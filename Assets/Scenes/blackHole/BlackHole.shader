Shader "Custom/ShaderToyStyle"
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
        _BlackHoleCenter("Black Hole Center", Vector) = (0.0, 0.0, 0.0, 0.0)
        _BlackHoleRadius("Black Hole Radius", Float) = 0.5
        _LensStrength("Lens Strength", Float) = 2.0

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
            float4 _BlackHoleCenter;
            float _BlackHoleRadius;
            float _LensStrength;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float hue2rgb(float p, float q, float t)
            {
                if (t < 0.0) t += 1.0;
                if (t > 1.0) t -= 1.0;
                if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
                if (t < 1.0 / 2.0) return q;
                if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
                return p;
            }

            float3 hsl2rgb(float h, float s, float l)
            {
                float r, g, b;

                if (s == 0.0)
                {
                    r = g = b = l; // Achromatic
                }
                else
                {
                    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
                    float p = 2.0 * l - q;
                    r = hue2rgb(p, q, h + 1.0 / 3.0);
                    g = hue2rgb(p, q, h);
                    b = hue2rgb(p, q, h - 1.0 / 3.0);
                }

                return float3(r, g, b);
            }

            float hash(float2 p)
            {
                p = frac(p * 0.3183099 + 0.1);
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            float noise(float2 uv)
            {
                return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            float noise23(float2 uv)
            {
                return frac(sin(dot(uv.xy, float2(13.9898, 121783.233))) * 1758.5453);
            }

            float2 noise2(float2 uv)
            {
                return float2(noise(uv), noise23(frac(uv * 12312.123123) + float2(11234.2, 112123.4343110)));
            }


            float perlinNoise(float2 uv)
            {
                float2 p = floor(uv);
                float2 f = frac(uv);

                f = f * f * (3.0 - 2.0 * f);

                float2 uv0 = p;
                float2 uv1 = p + float2(1.0, 0.0);
                float2 uv2 = p + float2(0.0, 1.0);
                float2 uv3 = p + float2(1.0, 1.0);

                float a = dot(hash(uv0), f - float2(0.0, 0.0));
                float b = dot(hash(uv1), f - float2(1.0, 0.0));
                float c = dot(hash(uv2), f - float2(0.0, 1.0));
                float d = dot(hash(uv3), f - float2(1.0, 1.0));

                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            // Improved FBM function with more octaves and adjusted frequency
            float fbm(float2 p)
            {
                float total = 0.0;
                float persistence = 0.5;
                float amplitude = 1.0;
                float maxValue = 0.0;
                float scale = .5; // Adjusted for better quality
                p.x *= 8.0;
                p.x = sin(p.x);
                for (int i = 0; i < 8; i++) // Increased octaves for more detail
                {
                    total += perlinNoise(p * scale) * amplitude;
                    maxValue += amplitude;
                    amplitude *= persistence;
                    p *= 2.0;
                }
                return total / maxValue;
            }


            float2x2 Rotate2D(float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                return float2x2(c, -s, s, c);
            }

            float calculateBrightnessFactor(float distance, float eventHorizonRadius, float influenceZoneRadius)
            {
                if (distance <= eventHorizonRadius)
                {
                    return 1.2; // Slightly lower maximum brightness inside event horizon
                }
                else if (distance <= influenceZoneRadius)
                {
                    float normalizedDistance = (distance - eventHorizonRadius) / (influenceZoneRadius -
                        eventHorizonRadius);
                    return pow(1.0 - normalizedDistance, 2.0); // Adjusted cubic falloff for smoother transition
                }
                else
                {
                    return 0.0; // No additional brightness outside influence zone
                }
            }


            float3 nebulaColor(float fbmValue, float hue, float distanceToEventHorizon, float eventHorizonRadius)
            {
                float influenceZoneRadius = eventHorizonRadius + 3.5;
                float brightnessFactor = calculateBrightnessFactor(distanceToEventHorizon, eventHorizonRadius,
                    influenceZoneRadius);
                float lightness = lerp(fbmValue * 0.01, 2.2, fbmValue * brightnessFactor);
                // Lowered lightness for better balance
                float3 color = hsl2rgb(hue, 0.8, lightness); // Reduced saturation for less extreme colors
                color += brightnessFactor * 0.1; // Reduced impact of brightness factor on final color
                return color;
            }


            float2x2 anisotropicScale(float xScale, float yScale)
            {
                return float2x2(xScale, 0, 0, yScale);
            }

            float Star(float2 uv, float flare)
            {
                float d = length(uv);
                float m = .02 / d;
                float rays = max(0., 1. - abs(uv.x * uv.y * 1000.)) * 0.1;
                m += rays * flare;
                uv = mul(uv, Rotate2D(3.1415 / 4.));
                rays = max(0., 1. - abs(uv.x * uv.y * 100000.)) * 0.9;
                m += rays * 0.3 * flare;
                m *= smoothstep(0.6, .01, d);
                return m;
            }

            float3 starLayer(float2 uv, float time, float scale, float2 off)
            {
                uv += off;
                uv *= scale;
                float3 color = float3(0, 0, 0);
                float2 gv = frac(uv) - .5;
                float2 id = floor(uv);
                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 offset = float2(x, y);
                        float n = noise(id + offset);
                        float size = frac(n * 1343.32 * 250);
                        float star = Star(gv - offset - float2(n, frac(n * 3334.)) + 0.5, smoothstep(.3, 0.9, size));
                        float3 starColor = sin(float3(0.5, 0.5, .5) * frac(n * 2345.2) * 123.12) * .5 + .5;
                        starColor *= float3(.4, 0.4, .1 + size);
                        star *= sin(time * n * 6.3) * 0.5 + 1.;
                        color += star * size * starColor;
                    }
                }
                return color;
            }

            float2 lensingEffect(float2 uv, float2 center, float radius, float strength)
            {
                float2 toCenter = center - uv;
                float distance = length(toCenter);
                float effect = smoothstep(radius, radius * 0.5, distance) * strength;

                // This will distort the UVs to create a stretching effect towards the center
                toCenter = normalize(toCenter) * effect;
                uv += toCenter;

                return uv;
            }

            float2 gravitationalLensing(float2 uv, float2 blackHoleCenter, float mass)
            {
                float2 delta = uv - blackHoleCenter;
                float r = length(delta) * 2.0;
                float lensingStrength = mass / (r * r);
                return uv + lensingStrength * normalize(delta);
            }

            float4 frag(v2f i) : SV_Target
            {
                float aspect = _iResolution.x / _iResolution.y;
                float2 uv = i.uv * 2.0 - 1.0;
                uv.x *= aspect;
                uv = mul(uv, Rotate2D(3.1415 / 4.0));
                float time = _MyTime * 0.2;
                _BlackHoleRadius += _InstrumentAmplitudes[0] * 1.5;
                float adjustedLensStrength = _LensStrength * (_BlackHoleRadius * 0.5 + 2.0); // Increase lens strength based on radius

                // Apply the lensing effect with the adjusted lens strength
                float2 lensedUv = lensingEffect(uv, _BlackHoleCenter.yx, _BlackHoleRadius, adjustedLensStrength);
                lensedUv += gravitationalLensing(uv, _BlackHoleCenter.yx,  0.42 + .8*_BlackHoleRadius); // Adjust the mass proportional to the radius

                lensedUv.x += time;
                _BlackHoleCenter.y += time;
                float distanceToEventHorizon = length(lensedUv - _BlackHoleCenter.yx);
                float angle = atan2(lensedUv.y - _BlackHoleCenter.y, lensedUv.x - _BlackHoleCenter.x);
                float xScale = 1.0;
                float yScale = 1.0;
                float angleBias = sin(angle * 5.0);
                float2 nebulaUv = lensedUv;
                nebulaUv = mul(nebulaUv - _BlackHoleCenter.xy, anisotropicScale(xScale, yScale + angleBias)) -
                    _BlackHoleCenter.xy;
                float fbmValue = fbm(nebulaUv * 0.5 + _Time * 0.1);
                float3 nebula = nebulaColor(fbmValue, 1.0 * 0.3 + .8, distanceToEventHorizon, _BlackHoleRadius);
                fbmValue = fbm(nebulaUv * 0.25 + _Time * 0.05);
                float3 nebula2 = nebulaColor(fbmValue, 0.6, distanceToEventHorizon, _BlackHoleRadius);
                fbmValue = fbm(nebulaUv * 0.5 + _Time * 0.1 + 4.0);
                float3 nebula3 = nebulaColor(fbmValue, 0.01, distanceToEventHorizon, _BlackHoleRadius);

                // change hue of nebula colors based on instruments 2,3,4
                nebula2 *= nebula2 + hsl2rgb(sin(time) + _InstrumentAmplitudes[3]*10, 0.8, 0.5);
                
                float3 color = float3(0, 0, 0);
                color += nebula2 * 4.0;
                color += 10.0 * _InstrumentAmplitudes[1] * starLayer(mul(lensedUv, Rotate2D(UNITY_PI / 4.0)), time, 4.0, float2(time * 0.1, 0.0)) *
                    float3(1.0, 1.2, sin(time * 0.1) * 0.5 + 0.5);
                color += nebula;
                color +=  40.0*_InstrumentAmplitudes[4] * (starLayer(lensedUv + float2(0.5, 0.5), time * 3.0, 8.0,
                  float2(time * 0.08, .0)) * float3(1.6, 1.1, 0.02 * sin(time * 0.1) * 0.5 + 0.5));
                color += nebula3;
                color += 30.0 * _InstrumentAmplitudes[4] * starLayer(lensedUv, time * 2.0, 12.0, float2(time * 0.05, 0.0)) * float3(
                    1.5, 1.0, sin(time * 0.01) * 0.5 + 0.5);
                // adjust lightness fromo the uv distance to the black hole, more lightness closer to the black hole, use lensed UVs
                
                color.g -= _InstrumentAmplitudes[2];
                // lightness gradient
                float gradient = smoothstep(2.0, -.4, distanceToEventHorizon);
                color += float3(gradient, gradient, gradient);
                
                // Adjust the event horizon (black hole) based on _BlackHoleRadius
                float hole = length(uv);
                float innerEdge = _BlackHoleRadius * .6; // Adjust this factor to control the inner edge size
                float outerEdge = _BlackHoleRadius * .69; // Adjust this factor to control the outer edge size
                hole = smoothstep(innerEdge, outerEdge, hole);
                color *= hole;
                
                
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}