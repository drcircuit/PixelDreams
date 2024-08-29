Shader "Custom/CloudsEffect"
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
        Tags { "RenderType"="Opaque" }
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
            float _WaveFormScale = 0.5;
            float4 _iResolution;

            // Hash function to generate pseudo-random values based on 3D coordinates
            float hash(float3 p)
            {
                p = frac(p * 0.3183099 + 0.1);
                p *= 17.0;
                return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
            }

            // Fade function used in noise calculations for smooth interpolation
            float3 fade(float3 t)
            {
                return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
            }

            // 3D noise function based on hash and trilinear interpolation
            float noise(float3 p)
            {
                float3 gridPoint = floor(p);
                float3 fractionalPart = frac(p);
                float3 u = fade(fractionalPart);

                float n000 = hash(gridPoint + float3(0.0, 0.0, 0.0));
                float n001 = hash(gridPoint + float3(0.0, 0.0, 1.0));
                float n010 = hash(gridPoint + float3(0.0, 1.0, 0.0));
                float n011 = hash(gridPoint + float3(0.0, 1.0, 1.0));
                float n100 = hash(gridPoint + float3(1.0, 0.0, 0.0));
                float n101 = hash(gridPoint + float3(1.0, 0.0, 1.0));
                float n110 = hash(gridPoint + float3(1.0, 1.0, 0.0));
                float n111 = hash(gridPoint + float3(1.0, 1.0, 1.0));

                float n00 = lerp(n000, n100, u.x);
                float n01 = lerp(n001, n101, u.x);
                float n10 = lerp(n010, n110, u.x);
                float n11 = lerp(n011, n111, u.x);

                float n0 = lerp(n00, n10, u.y);
                float n1 = lerp(n01, n11, u.y);

                return lerp(n0, n1, u.z);
            }

            // 2D rotation matrix to rotate vectors in the xy-plane
            float2x2 rotationMatrix(float angle)
            {
                float c = cos(angle), s = sin(angle);
                return float2x2(c, s, -s, c);
            }

            // Matrix for additional 3D transformation
            const float3x3 transformationMatrix = float3x3(
                0.33338, 0.56034, -0.71817, 
                -0.87887, 0.32651, -0.15323, 
                0.15162, 0.69596, 0.61339) * 1.93;

            float prm1 = 0.4;
            float2 bsMo = float2(0, 0);

            // Simple utility to calculate squared magnitude of a 2D vector
            float magnitudeSquared(float2 p) {
                return dot(p, p);
            }

            // Linear step function that smoothly interpolates between two values
            float linearStep(float minVal, float maxVal, float value) {
                return clamp((value - minVal) / (maxVal - minVal), 0.0, 1.0);
            }

            // Displacement function for dynamic motion
            float2 displacement(float t) {
                return float2(sin(t * -0.12), cos(t * 0.175)) * 2.0;
            }

            // FBM (Fractional Brownian Motion) noise function
            float fbm(float3 p) {
                float value = 0.0;
                float amplitude = 0.3;
                float frequency = 5.0;

                for (int i = 0; i < 5; i++) { // Number of octaves
                    value += amplitude * noise(p * frequency);
                    p *= 2.0;  // Increase frequency
                    amplitude *= 0.5;  // Decrease amplitude
                }

                return value;
            }

            // Mapping function using original noise method
            float2 mapOriginal(float3 position) {
                float3 displacedPos = position;
                displacedPos.xy -= displacement(position.z).xy;
                position.xy = mul(position.xy, rotationMatrix(sin(position.z + _MyTime * 2.0) * 0.15 + cos(position.z + _MyTime * 3.0) * 0.1));


                float density = 0.0;
                float cl = magnitudeSquared(displacedPos.xy);

                position *= 0.91;
                float frequency = 1.0;
                float amplitude = 0.1 + prm1 * .2;

                for (int i = 0; i < 5; i++) {
                    position += sin(position.zxy * 0.75 * frequency + _MyTime * frequency * 0.8) * amplitude;
                    density -= abs(dot(cos(position), sin(position.xzy)) * frequency);
                    frequency *= .57;
                    position = mul(position, transformationMatrix);
                }
                density = abs(density + prm1 * 3.0) + prm1 * 0.3 - 2.5 + bsMo.y;

                return float2(density + cl * 0.2 + 0.25, cl);
            }

            // Mapping function using FBM noise
            float2 mapFBM(float3 position, float time) {
                float3 displacedPos = position;
                displacedPos.xy -= displacement(position.z).xy;
                displacedPos.z += time * 0.05;
                position.xy = mul(position.xy, rotationMatrix(sin(position.z + _MyTime * 2.0) * 0.15 + cos(position.z + _MyTime * 3.0) * 0.1));

                float cl = magnitudeSquared(displacedPos.xy);
                float density = fbm((position+time) * 0.51) * 0.8;

                return float2(density + cl * 0.2 + 0.25, cl);
            }

            // Rendering function using original noise method
            float4 renderOriginal(float3 rayOrigin, float3 rayDirection, float time) {
                float4 accumulatedColor = float4(0, 0, 0, 0);
                float t = 4.5;
                float fogFactor = 0.0;
                time *= 0.000005;
                for (int i = 0; i < 130; i++) {
                    if (accumulatedColor.a > 0.95) break;

                    float3 currentPosition = rayOrigin + t * rayDirection;
                    float2 mappedValue = mapOriginal(currentPosition);
                    float2 mappedValueFBM = mapFBM(currentPosition,time);
                    mappedValue = lerp(mappedValue, mappedValueFBM, .5)/2.0;
                    float density = clamp(mappedValue.x - 0.3, 0.0, 1.0) * 1.3;
                    float dn = clamp((mappedValue.x + 2.0), 0.0, 3.0);

                    float4 color = float4(0, 0, 0, 0);
                    if (mappedValue.x > 0.1) {
                        float3 blendedColor = lerp(float3(0.05, 0.05, 0.05), float3(0.2, 0.15, 0.1), smoothstep(0.0, 0.7, density));
                        blendedColor = lerp(blendedColor, float3(0.6, 0.5, 0.3), smoothstep(0.7, 1.0, density));

                        color = float4(sin(blendedColor + mappedValue.y * 0.1 + sin(currentPosition.z * 0.4) * 0.5 + 1.8) * 0.5 + 0.5, 0.08);
                        color *= density * density * density * 1.2;
                        color.rgb *= linearStep(4.0, -2.5, mappedValue.x) * 2.3;

                        float diffuse = clamp((density - mapOriginal(currentPosition + 0.8).x) / 6.0, 0.001, 1.0);
                        diffuse += clamp((density - mapOriginal(currentPosition + 0.35).x) / 1.8, 0.001, 1.0);
                        color.xyz *= density * (float3(0.005, 0.045, 0.075) + 1.5 * float3(0.033, 0.07, 0.03) * diffuse);
                    }

                    float fogContribution = exp(t * 0.2 - 2.0);
                    color.rgba += float4(0.06, 0.11, 0.11, 0.1) * clamp(fogContribution - fogFactor, 0.0, 1.0);
                    fogFactor = fogContribution;
                    accumulatedColor += color * (1.0 - accumulatedColor.a);
                    t += clamp(0.5 - dn * dn * 0.05, 0.09, 0.6);
                }
                return clamp(accumulatedColor, 0.0, 1.0);
            }

            // Rendering function using FBM noise with fewer iterations for performance
            float4 renderFBM(float3 rayOrigin, float3 rayDirection, float time) {
                float4 accumulatedColor = float4(0, 0, 0, 0);
                time *= .0000005;
                // const float lightDist = 8.0;
                // float3 lightPosition = float3(displacement(time + lightDist) * 0.5, time + lightDist);
                float t = 3.5;
                float fogFactor = 0.0;
                for (int i = 0; i < 10; i++) { // Fewer iterations for performance
                    if (accumulatedColor.a > 0.95) break;

                    float3 currentPosition = rayOrigin + t * rayDirection;
                    float2 mappedValue = mapFBM(currentPosition, time);
                    float density = clamp(mappedValue.x - 0.3, 0.0, 1.0) * 1.3;
                    float dn = clamp((mappedValue.x + 2.0), 0.0, 3.0);

                    float4 color = float4(0, 0, 0, 0);
                    if (mappedValue.x > 0.1) {
                        float3 blendedColor = lerp(float3(0.05, 0.05, 0.05), float3(0.2, 0.15, 0.1), smoothstep(0.0, 0.7, density));
                        blendedColor = lerp(blendedColor, float3(0.6, 0.5, 0.3), smoothstep(0.7, 1.0, density));

                        color = float4(sin(blendedColor + mappedValue.y * 0.1 + sin(currentPosition.z * 0.4) * 0.5 + 1.8) * 0.5 + 0.5, 0.08);
                        color *= density * density * density * 1.2;
                        color.rgb *= linearStep(4.0, -2.5, mappedValue.x) * 2.3;

                        float diffuse = clamp((density - mapFBM(currentPosition + 0.8,time).x) / 6.0, 0.001, 1.0);
                        diffuse += clamp((density - mapFBM(currentPosition + 0.35,time).x) / 1.8, 0.001, 1.0);
                        color.xyz *= density * (float3(0.005, 0.045, 0.075) + 1.5 * float3(0.033, 0.07, 0.03) * diffuse);
                    }

                    float fogContribution = exp(t * 0.2 - 2.0);
                    color.rgba += float4(0.06, 0.11, 0.11, 0.1) * clamp(fogContribution - fogFactor, 0.0, 1.0);
                    
                    fogFactor = fogContribution;
                    accumulatedColor += color * (1.0 - accumulatedColor.a);
                    t += clamp(0.2 - dn * dn * 0.05, 0.09, 0.6);
                }
                return clamp(accumulatedColor, 0.0, 1.0);
            }
            
            // Main rendering function that blends between FBM and original based on the sine of time
            void mainImage(out float4 fragColor, float2 fragCoord)
            {
                float2 uv = fragCoord.xy / _iResolution.xy;
                float2 p = (fragCoord - 0.5 * _iResolution.xy) / _iResolution.y;
                float amp = 0.2;
                float2 bsMo = (amp * float2(sin(_MyTime), cos(_MyTime)) * _iResolution.xy) / _iResolution.y;

                // Time scaling factor for animation
                float time = _MyTime * 3.0;

                // Ray origin initialization
                float3 rayOrigin = float3(0, 0, time);
                rayOrigin += float3(sin(_MyTime) * 0.5, 0.0, 0.0);

                // Amplitude for displacement effect
                float displacementAmplitude = .95;
                rayOrigin.xy += displacement(rayOrigin.z) * displacementAmplitude;

                // Target direction calculation
                float targetDistance = 3.5;
                float3 targetDirection = normalize(rayOrigin - float3(displacement(time + targetDistance) * displacementAmplitude, time + targetDistance));
                rayOrigin.x -= bsMo.x * 2.0;

                // Camera setup (right, up, and ray directions)
                float3 rightDir = normalize(cross(targetDirection, float3(0, 1, 0)));
                float3 upDir = normalize(cross(rightDir, targetDirection));
                rightDir = normalize(cross(upDir, targetDirection));

                float3 rayDirection = normalize((p.x * rightDir + p.y * upDir) * 1.0 - targetDirection);
                rayDirection.xy = mul(rotationMatrix(-displacement(time + 3.5).x * 0.2 + bsMo.x), rayDirection.xy);


                // Parameter used in the noise generation
                prm1 = smoothstep(-0.4, 0.4, sin(_MyTime * 0.3));

                // Blend between the FBM and original rendering functions based on the sine of time
                float blendFactor = (sin(_MyTime) * 0.5 + 0.5); // Maps sin(_MyTime) from [-1, 1] to [0, 1]
                // Keep blendFactor between .2 and .8
                blendFactor = blendFactor * .6 + .2;
                float4 sceneColorOriginal = renderOriginal(rayOrigin, rayDirection, time) / (.2+blendFactor);
                float4 sceneColorFBM = renderFBM(rayOrigin, rayDirection, time) / (.2+blendFactor);
                float4 finalColor = lerp(sceneColorOriginal, sceneColorFBM, blendFactor);
                //float4 finalColor = sceneColorOriginal * (1.0 - blendFactor) + sceneColorFBM * blendFactor;
                float3 col = finalColor.rgb;
                
                // Adjust the final color output
                col = pow(col, float3(0.55, 0.65, 0.6)) * float3(1.0, 0.97, 0.9);
                col *= col * col * col;

                // Apply vignette effect
                col *= pow(32.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.5) * 0.7 + 0.3;
                fragColor = float4(col, 1.0);
            }

            float4 logoSample(float2 uv) {
                float4 color = tex2D(_Texture2D1, uv);
                return color;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 fragColor;
                mainImage(fragColor,  (i.uv * _iResolution.xy) + 0.5);
                float4 logoColor = logoSample(i.uv);
                // wait 10 seconds, then use 5 seconds to fade in the logo, display the logo for 20 seconds, then fade the logo out over 5 seconds
                float logoTime = _MyTime - 10.0;
                float logoFadeInTime = 5.0;
                float logoDisplayTime = 10.0;
                float logoFadeOutTime = 5.0;
                float logoAlpha = 0.0;
                if (logoTime < logoFadeInTime) {
                    logoAlpha = smoothstep(0.0, 1.0, logoTime / logoFadeInTime);
                } else if (logoTime < logoFadeInTime + logoDisplayTime) {
                    logoAlpha = 1.0;
                } else if (logoTime < logoFadeInTime + logoDisplayTime + logoFadeOutTime) {
                    float logoFadeFactor = (logoTime - logoFadeInTime - logoDisplayTime) / logoFadeOutTime;
                    logoAlpha = smoothstep(1.0, 0.0, logoFadeFactor);
                    // scale UV up to scale logo out from center while fading out
                    float2 uv = i.uv * 2.0 - 1.0;
                    float scale = 1.0 + logoFadeFactor;
                    uv *= scale;
                    uv = uv * 0.5 + 0.5;
                    // rotate UV clockwize
                    float angle = logoFadeFactor * 3.14159;
                    uv = mul(uv, rotationMatrix(angle));
                    logoColor = logoSample(uv);
                    
                }
                logoColor.a *= logoAlpha;
                
                //superimpose logo by alpha
                fragColor = lerp(fragColor, logoColor, logoColor.a);
                return fragColor;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            ENDCG
        }
    }
}
