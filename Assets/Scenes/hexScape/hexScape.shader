Shader "Custom/hexScape"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Texture2D0 ("Texture2D0", 2D) = "white" {}
        _Texture2D1 ("Texture2D1", 2D) = "white" {}
        _Texture2D2 ("Texture2D2", 2D) = "white" {}
        _Texture2D3 ("Texture2D3", 2D) = "white" {}
        _Texture2D4 ("Texture2D4", 2D) = "white" {}
        _Texture2D5 ("Texture2D5", 2D) = "white" {}
        _Texture2D6 ("Texture2D6", 2D) = "white" {}
        _Texture2D7 ("Texture2D7", 2D) = "white" {}
        _Texture2D8 ("Texture2D8", 2D) = "white" {}
        _Texture2D9 ("Texture2D9", 2D) = "white" {}

        _Cubemap0 ("Cubemap0", CUBE) = "" {}
        _Cubemap1 ("Cubemap1", CUBE) = "" {}
        _Cubemap2 ("Cubemap2", CUBE) = "" {}
        _Cubemap3 ("Cubemap3", CUBE) = "" {}
        _Cubemap4 ("Cubemap4", CUBE) = "" {}
        _WaveFormScale ("WaveFormScale", Float) = 0.5
        _iResolution ("Resolution", Vector) = (1920, 1080, 0, 0)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _Texture2D0;
            sampler2D _Texture2D1;
            sampler2D _Texture2D2;
            sampler2D _Texture2D3;
            sampler2D _Texture2D4;
            sampler2D _Texture2D5;
            sampler2D _Texture2D6;
            sampler2D _Texture2D7;
            sampler2D _Texture2D8;
            sampler2D _Texture2D9;

            samplerCUBE _Cubemap0;
            samplerCUBE _Cubemap1;
            samplerCUBE _Cubemap2;
            samplerCUBE _Cubemap3;
            samplerCUBE _Cubemap4;

            float _MyTime;
            float _AudioSpectrum[1024];
            float _AudioWaveform[1024];
            float _InstrumentAmplitudes[5];
            int _Bands;
            float _WaveFormScale = 0.5;
            float _SpectrumScale = 0.2;
            float4 _iResolution;
            float ampA = 3.6;
            float ampB = .85;
            float freqA = .15;
            float freqB = .25;
            #define FAR 50.0
            #define TAU 6.28318530718
            #define PI 3.14159265359

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float hash(float n)
            {
                return frac(cos(n) * 45758.5453);
            }

            float hash33(float3 p)
            {
                float n = sin(dot(p, float3(7, 157, 113)));
                return frac(float3(2097152, 262144, 32768) * n);
            }

            float2x2 rot2d(float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2x2(c, -s, s, c);
            }

            // triplanar texturing
            float3 tex3D(sampler2D t, in float3 p, in float3 n)
            {
                n = max(abs(n) - .2, 0.001);
                n /= dot(n, float3(1, 1, 1));
                float3 tx = tex2D(t, p.yz).rgb;
                float3 ty = tex2D(t, p.xz).rgb;
                float3 tz = tex2D(t, p.xy).rgb;
                return tx * n.x + ty * n.y + tz * n.z;
            }

            float noise3D(in float3 p)
            {
                const float3 s = float3(7, 157, 113);
                float3 id = floor(p);
                float4 h = float4(0, s.yz, s.y + s.z) + dot(id, s);
                p -= id;
                p *= p * (3.0 - 2.0 * p);
                h = lerp(frac(sin(fmod(h, TAU)) * 43768.5453),
                         frac(sin(fmod(h + s.x, TAU)) * 43768.5453), p.x);
                h.xy = lerp(h.xz, h.yw, p.y);
                return lerp(h.x, h.y, p.z);
            }

            float sdSphere(float3 p)
            {
                p = frac(p) - 0.5;
                return dot(p, p);
            }

            float cellTile(in float3 p)
            {
                float c = .25; //max
                c = min(c, sdSphere(p - float3(.81, .62, .53)));
                c = min(c, sdSphere(p - float3(.39, .2, .11)));
                c = min(c, sdSphere(p - float3(.62, .24, .06)));
                c = min(c, sdSphere(p - float3(.2, .82, .64)));

                p *= 1.412;
                c = min(c, sdSphere(p - float3(.48, .29, .2)));
                c = min(c, sdSphere(p - float3(.06, .82, .64)));

                return c * 4.0;
            }

            float cellBump(in float3 p)
            {
                float c = .25; //max
                c = min(c, sdSphere(p - float3(.81, .62, .53)));
                c = min(c, sdSphere(p - float3(.39, .2, .11)));
                c = min(c, sdSphere(p - float3(.62, .24, .06)));
                c = min(c, sdSphere(p - float3(.2, .82, .64)));

                p *= 1.412;
                c = min(c, sdSphere(p - float3(.48, .29, .2)));
                c = min(c, sdSphere(p - float3(.06, .82, .64)));

                c = min(c, sdSphere(p - float3(.6, .86, .0)));
                c = min(c, sdSphere(p - float3(.18, .44, .57)));

                return c * 4.0;
            }

            float2 path(float z)
            {
                float x = sin(z * .35) *2.42;
                float y = cos(z * .25) * .85;
                return float2(x,y);
            }

            // map function
            // p is the position in 3d space
            // returns the distance to the surface

            float map(float3 p)
            {
                float height = tex2D(_Texture2D2, p.xy * .25).r;
                height *= 2.5;
                p.z += height;
                float sf = cellTile(p * .25);
                
                p.xy -= path(p.z);
                p.xy = mul(rot2d(p.z / 18.0+sin(_MyTime*.01)*40.), p.xy);
                float n = dot(sin(p * 1. + sin(p.yzx * .5 + _MyTime)), float3(.25, .25, .25));
                return 2 - abs(p.y) + n + sf;
            }

            float bumpSurf(in float3 p)
            {
                float noi = noise3D(p * 64.);
                float voronoi = cellBump(p * .75);
                return voronoi * .98 + noi * .02;
            }

            float3 bumpShading(in float3 p, in float3 n, float bumpFactor)
            {
                const float2 e = float2(0.001, 0);
                float3 ref = bumpSurf(p);
                float3 gradient = (
                    float3(bumpSurf(p - e.xyy),
               bumpSurf(p - e.yxy),
               bumpSurf(p - e.yyx)) - ref) / e.x;
                return normalize(n + gradient * bumpFactor);
            }

            float rayMarch(in float3 ro, in float3 rd)
            {
                float d = 0.0, h;
                for (int i = 0; i < 80; i++)
                {
                    h = map(ro + rd * d);
                    if (abs(h) < 0.002 * (d * .25 + 1) || d > FAR) break;
                    d += h * .8;
                }
                return clamp(d, 0.0, FAR);
            }

            float3 getNormal(in float3 p)
            {
                const float2 e = float2(0.001, 0);
                return normalize(
                    float3(map(p + e.xyy) - map(p - e.xyy),
               map(p + e.yxy) - map(p - e.yxy),
               map(p + e.yyx) - map(p - e.yyx)));
            }

            float thickness(in float3 p, in float3 n)
            {
                float sNum = 4.0;
                float sca = 1.0, occ = 0;
                for (float i = 0; i < sNum + 0.001; i++)
                {
                    float hr = .05 + .4 * i / sNum;
                    float dd = map(p - n * hr);
                    occ += (hr - min(dd, 0)) * sca;
                    sca *= .9;
                }
                return 1. - max(occ / sNum, 0.);
            }

            float ambientocclusion(in float3 p, in float3 n)
            {
                float ao = 0.0, l;
                const float maxDist = 4.;
                const float numIter = 6.0;
                for (float i = 1.0; i < numIter + .5; i++)
                {
                    l = (i + hash(i)) * .5 / numIter * maxDist;
                    ao += (l - map(p + n * l)) / (1. + l);
                }
                return clamp(1 - ao / numIter, 0., 1.);
            }

            float curve(in float3 p, in float w)
            {
                float2 e = float2(-1., 1) * w;
                float t1 = map(p + e.yxx), t2 = map(p + e.xxy), t3 = map(p + e.xyx), t4 = map(p + e.yyy);
                return 0.0125 / (w * w) * (t1 + t2 + t3 + t4 - 4. * map(p));
            }

            float mist(in float3 p)
            {
                p = cos(p * 2 + (cos(p.yzx) + 1 + _MyTime * 4) * 1.57);
                return dot(p, float3(.1666, .1666, .1666)) + .5;
            }

            float mistNoise3D(in float3 p)
            {
                const float3x3 m3RotTheta = float3x3(
                    .25, -0.866, 0.433,
                    0.9665, .25, -.2455127,
                    -0.058, 0.433, 0.899519
                ) * 1.5;
                float res = 0;
                float m = mist(p * PI);
                p += (m - _MyTime * .25);
                p = mul(m3RotTheta, p);
                res += m;
                m = mist(p * PI);
                p += (m - _MyTime * .25) * .7071;
                p = mul(m3RotTheta, p);
                res += m * .7071;
                m = mist(p * PI);
                res += m * .5;
                return res / 2.2071;
            }

            float hash32(float3 p)
            {
                return frac(sin(fmod(dot(p, float3(127.1, 311.7, 74.7)), TAU)) * 43758.5453);
            }

            float getMist(in float3 ro, in float3 rd, in float3 lp, in float t)
            {
                float mist = 0;
                ro += rd * t / 8.0;
                for (int i = 0; i < 4; i++)
                {
                    float sDi = length(lp - ro) / FAR;
                    float sAtt = min(1.0 / (1 + sDi * .25 + sDi * sDi * .05), 1.0);
                    mist += sAtt * mistNoise3D(ro);
                    ro += rd * t / 4.0;
                }
                return clamp(mist / 2 + hash32(ro) * .1 - .05, 0, 1);
            }

            float4 frag(v2f i) : SV_Target
            {
                // Normalized pixel coordinates (from 0 to 1)
                float2 uv = i.uv * 2.0 - 1.0;

                // Correct for aspect ratio
                uv.x *= _iResolution.x / _iResolution.y;


                // Calculate the band width and index
                int bandWidth = 1024 / _Bands;
                int bandIndex = int(uv.x * _Bands);

                // Average the spectrum values within the band
                float spectrumValue = 0.0;
                for (int j = 0; j < bandWidth; j++)
                {
                    spectrumValue += _AudioSpectrum[bandIndex * bandWidth + j];
                }
                spectrumValue /= bandWidth;
                spectrumValue = pow(spectrumValue, _SpectrumScale);

                // Draw vertical bars based on the spectrum value
                float t = _MyTime*6.0;
                float3 cam = float3(0, 0, t);
                float3 lookAt = cam + float3(0, 0, .1);
                float3 lp = cam + float3(0, 1, 8+_InstrumentAmplitudes[3]);
                lookAt.xy += path(t+.1);
                cam.xy += path(t);
                lp.xy += path(lp.z);
                float fov = PI / 2.0;
                float3 forward = normalize(lookAt - cam);
                float3 right = normalize(float3(forward.z, 0, -forward.x));
                float3 up = cross(forward, right);
                float3 rd = normalize(uv.x * right + uv.y * up + forward / fov);
                rd.xy = mul(rot2d(path(lookAt.z).x / 16.0), rd.xy);
                float d = rayMarch(cam, rd);
                float3 col = float3(0, 0, 0);
                float3 instrumentColors = float3(_InstrumentAmplitudes[3],_InstrumentAmplitudes[2],_InstrumentAmplitudes[0]);
                if (d < FAR)
                {
                    float3 sp = cam + rd * d;
                    float3 sn = getNormal(sp);
                    const float tSize = .25;
                    sn = bumpShading(sp, sn, 0.1);
                    float3 texNormal = tex3D(_Texture2D1, sp * tSize, sn);
                    texNormal = texNormal * 2.0 - 1.0;
                    sn = lerp(sn, texNormal, .5);
                    sn = normalize(sn);
                    //sn = normalize(sn + texNormal * .1);
                    float ao = ambientocclusion(sp, sn);
                    float3 ld = lp - sp;
                    float distlpsp = max(length(ld), 0.001);
                    ld /= distlpsp;
                    float atten = 1.; //2./(1. + distlpsp*distlpsp*.3);
                    float amb = 0.5;
                    float diff = max(dot(sn, ld), 0.0);
                    float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 16.0);
                    float crv = clamp(curve(sp, 0.125) * .5 + .5, 0., 1.);
                    float fresnel = pow(clamp(dot(sn, rd) + 1, 0, 1), 1);
                    float3 ref = reflect(sn, rd);
                    float3 tex = tex3D(_Texture2D0, sp * tSize, sn);
                    tex = smoothstep(-.05, .95, tex) * (smoothstep(-.5, crv, 1.0) * .75 + .25);
                    float3 texRoughness = tex3D(_Texture2D3, sp * tSize, sn);
                    float3 texAO = tex3D(_Texture2D4, sp * tSize, sn);
                    
                    //tex = lerp(tex, float3(1, 1, 1), texRoughness.x);
                    tex *= texAO*ao;


                    float3 hf = normalize(ld + sn);
                    float th = thickness(sp, hf);
                    float tdiff = pow(clamp(dot(rd, -hf), 0, 1), 1);
                    float trans = max((tdiff + .25) * th * 1.5, 0);
                    trans = pow(trans, 4);
                    float shading = crv*.5 + .5;
                    col = tex * (diff + amb) + float3(.7, .9, 1.0) * spec + float3(.2, .5, 1.2) * spec * spec * spec *
                        .5;
                    //col = tex;
                    col += tex * float3(.9, .95, 1) * pow(fresnel, 4.) * 2.;
                    float3 transColor1 = float3(0.3,.05, .66)+instrumentColors;
                    float3 transColor2 = float3(.48,.05, 2.)*instrumentColors;
                    col += tex * lerp(transColor1, transColor2, abs(hf.y)) * trans * 115;
    
                    float per = 10.;
                    float tanHi = abs(fmod(per * .5 + d + _MyTime, per) - per * .5);
                    float3 tanHiCol = float3(_InstrumentAmplitudes[1], .2, 1) * (1. / tanHi * .2);
                    col += tanHiCol;
                    col = lerp(col, float3(0,0.004,0.1), texRoughness.x);
                    col *= texAO;
                    
                    col *= atten * shading * ao;
                    
                    //col = tex;
                }
                float mist = getMist(cam, rd, lp, d);
                float3 sky = float3(0.5, 1.75, 2.875) * lerp(1, .72, mist) * (rd.y * .25 + 1) +.1* instrumentColors;
                col = lerp(col, sky, min(pow(d, 1.5)*.25/FAR,1));
                col = sqrt(clamp(col, 0, 1));
                col += sin(cam.z)*.25,0;
                //gamma correction
                col = pow(col, 3.2);
                // Output to screen
                // lookup texture to test sampler
                //col = float3(path(uv.x+uv.y), 1.0);
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}