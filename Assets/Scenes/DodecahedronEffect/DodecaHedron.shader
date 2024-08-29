Shader "Custom/FractalDodecahedron"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bands ("Bands", Range(2, 32)) = 24
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _Bands;
            float _AudioSpectrum[1024]; // Assuming max FFT resolution
            // Define frequency bands (adjust as per your FFT configuration)
            float _BandFrequencies[32] = {
                20.0, 60.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0,
                16000.0, 20000.0, 25000.0, 31500.0, 40000.0, 50000.0,
                63000.0, 80000.0, 100000.0, 125000.0, 160000.0, 200000.0,
                250000.0, 315000.0, 400000.0, 500000.0, 630000.0, 800000.0,
                1000000.0, 1250000.0, 1600000.0, 2000000.0, 2500000.0, 3150000.0
            };
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float calculateBandVolume(int bandIndex, float startFreq, float endFreq)
            {
                int startIndex = int(startFreq / 44100.0 * 1024.0); // Adjust 44100.0 to your audio sample rate
                int endIndex = int(endFreq / 44100.0 * 1024.0);     // Adjust 44100.0 to your audio sample rate
                float volume = 0.0;
                for (int i = startIndex; i < endIndex; ++i)
                {
                    volume += _AudioSpectrum[i];
                }
                return volume / float(endIndex - startIndex);
            }
            float3 palette(float d) {
                return lerp(float3(0.8, 0.0, 0.4), float3(0.0, 0.80, 0.99), d);
            }

            float2 rotate(float2 p, float a) {
                float c = cos(a);
                float s = sin(a);
                return float2(c * p.x - s * p.y, s * p.x + c * p.y);
            }

            // Calculate the signed distance to a dodecahedron
            float sdDodecahedron(float3 p) {
                // The normal vectors of a dodecahedron's faces
                const float3 n[12] = {
                    float3(0.57735, 0.57735, 0.57735), float3(0.57735, 0.57735, -0.57735),
                    float3(0.57735, -0.57735, 0.57735), float3(0.57735, -0.57735, -0.57735),
                    float3(-0.57735, 0.57735, 0.57735), float3(-0.57735, 0.57735, -0.57735),
                    float3(-0.57735, -0.57735, 0.57735), float3(-0.57735, -0.57735, -0.57735),
                    float3(0, 0.35682, 0.93417), float3(0, -0.35682, 0.93417),
                    float3(0.93417, 0, 0.35682), float3(-0.93417, 0, 0.35682)
                };
                float d = -1e10;
                for (int i = 0; i < 12; i++) {
                    d = max(d, dot(p, n[i]));
                }
                return d;
            }
            float kickVolume;
            float snareVolume;
            float lowMidVolume;
            float highMidVolume;
            float trebleVolume;
            float map(float3 p, float time) {
                float t = time * 0.2;
                float mixAmnt = max(sin(lowMidVolume+t) * .5 + .5, .8);
                float oldMix = max(sin(t * 12.+snareVolume) * .5 + .5, .8);
                float mix = max(sin(t*12.)*.5+.5, .8);
                for (int i = 0; i < 24; ++i) {
                    p.xz = rotate(p.xz, t);
                    p.xy = rotate(p.xy, t * 1.89);
                    p.xz = lerp(abs(p.yz), abs(p.xz),  mixAmnt);
                    p.xz -= .5;
                }
                return sdDodecahedron(p) / 2.0;
            }

            float4 rm(float3 ro, float3 rd, float time) {
                float t = 0.0;
                float3 col = float3(0.0,0.0,0.0);
                float d;
                for (float i = 0.0; i < 64.0; i++) {
                    float3 p = ro + rd * t;
                    d = map(p, time) * 0.5;
                    if (d < 0.02) {
                        break;
                    }
                    if (d > 290.0) {
                        break;
                    }
                    col += palette(length(p) * .1) / (800.0 * d);
                    t += d;
                }
                return float4(col, 1.0 / (d * 100.0));
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = (i.uv - 0.5) * 2.0;
                float t = _Time * 30.0;
                kickVolume = calculateBandVolume(2, 80.0, 250.0);       // Example: Replace with actual band index and bandwidth
                snareVolume = calculateBandVolume(5, 1000.0, 1800.0);     // Example: Replace with actual band index and bandwidth
                lowMidVolume = calculateBandVolume(10, 500.0, 1000.0);  // Example: Replace with actual band index and bandwidth
                highMidVolume = calculateBandVolume(20, 4000.0, 16000.0);// Example: Replace with actual band index and bandwidth
                trebleVolume = calculateBandVolume(30, 16000.0, 200000.0);// Example: Replace with actual band index and bandwidth

                float3 ro = float3(0.0,0.0 ,(-240.0 + sin(t) * 150.0)-(snareVolume*400.1) );
                ro.xz = rotate(ro.yz, t);
                float3 cf = normalize(-ro);

                float3 cs = normalize(cross(cf, float3(0.0, 1.0, 0.0)));
                float3 cu = normalize(cross(cf, cs));

                float3 uuv = ro + cf * 3.0 + uv.x * cs + uv.y * cu;
                float3 rd = normalize(uuv - ro);
                // Calculate volumes for specific bands
           
                float4 col = rm(ro, rd, t);

                //col *= .8+float4(-1.0 * kickVolume * 10.0, 1.0 * lowMidVolume * 10.0, -1.0 * snareVolume * 10.0, -1.0 * highMidVolume * 10.0);
                col *= snareVolume * 100.0;

                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
