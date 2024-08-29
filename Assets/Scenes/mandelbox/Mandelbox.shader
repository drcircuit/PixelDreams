Shader "Custom/Mandelbox"
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
            float _AudioSpectrum[1024];
            float _AudioWaveform[1024];
            float _InstrumentAmplitudes[5];
            int _Bands;
            float _WaveFormScale;
            float _SpectrumScale;
            float4 _iResolution;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Function to calculate the Mandelbox distance
            float mandelboxDE(float3 pos, float scale, float cx, float cy, float cz) {
                float DEfactor = scale;
                float fixedRadius = 1.0;
                float fR2 = fixedRadius * fixedRadius;
                float minRadius = .01;
                float mR2 = minRadius * minRadius;
                float x = pos.x, y = pos.y, z = pos.z;

                // Inside iteration loop
                for (int i = 0; i < 4; i++) { // 4 iterations, adjust as needed
                    // Mandelbox algorithm
                    if (x > 1.0) x = 2.0 - x;
                    else if (x < -1.0) x = -2.0 - x;
                    if (y > 1.0) y = 2.0 - y;
                    else if (y < -1.0) y = -2.0 - y;
                    if (z > 1.0) z = 2.0 - z;
                    else if (z < -1.0) z = -2.0 - z;

                    float r2 = x*x + y*y + z*z;

                    if (r2 < mR2) {
                        x = x * fR2 / mR2;
                        y = y * fR2 / mR2;
                        z = z * fR2 / mR2;
                        DEfactor = DEfactor * fR2 / mR2;
                    } else if (r2 < fR2) {
                        x = x * fR2 / r2;
                        y = y * fR2 / r2;
                        z = z * fR2 / r2;
                        DEfactor *= fR2 / r2;
                    }

                    x = x * scale + cx;
                    y = y * scale + cy;
                    z = z * scale + cz;
                    DEfactor *= scale;
                }

                // Resultant estimated distance
                return sqrt(x*x + y*y + z*z) / abs(DEfactor);
            }

            float2x2 rot2d(float angle){
                float c = cos(angle);
                float s = sin(angle);
                return float2x2(c, s, -s, c);
            }

            float4 frag (v2f i) : SV_Target
            {
                // Normalized pixel coordinates (from 0 to 1)
                float2 uv = i.uv * 2.0 - 1.0;

                // Correct for aspect ratio
                uv.x *= _iResolution.x / _iResolution.y;

                // Use audio data to modify the effect
                float t = _MyTime * 0.2;

                // Use the audio spectrum to affect the zoom level
                int spectrumIndex = int(uv.x * 1023.0);
                float zoomFactor = 1.0;// + _AudioSpectrum[spectrumIndex] * 0.5;
                // calculate music transient value
                float transient = 0.0;
                for (int j = 0; j < 1024; j++)
                {
                    transient += _AudioSpectrum[j];
                }
                transient = transient / 10.0;
                // Adjust the Mandelbox evolution based on audio data
                float evolution = _MyTime +_InstrumentAmplitudes[1];// + _AudioSpectrum[spectrumIndex] * 100.0;

                float3 col = float3(0, 0, 0);
                
                // Transform coordinates
                float2 uvRot = mul(rot2d(fmod(evolution * 0.9, 6.28)), uv);
                float2 uv2 = uvRot;
                uv2 *= sin(_InstrumentAmplitudes[3]*10.5);
                uvRot = abs(uvRot) * sin(t);
                col += 0.006 / mandelboxDE(float3(uvRot, -cos(t * 10.0)), zoomFactor, uvRot.y, uvRot.x, uvRot.y + uvRot.x * tan(t));

                uv2 *= 45.0 / 6.28;
                col += 0.01 / mandelboxDE(float3(sin(uv2 * 0.2), -sin(t * 11.0)), zoomFactor, uv2.x, uv2.y, uvRot.x + uvRot.y / atan(t * 11.0));
                col += 0.02 / mandelboxDE(float3(uvRot, -sin(t * 11.0)), zoomFactor, uv2.x, uv2.y, uvRot.x + uvRot.y * atan(t * 11.0));

                col.g *= clamp(0.0, 1.0, 0.2 / mandelboxDE(float3(sin(uv2 * 0.2), -sin(t * 11.0)), zoomFactor, uv2.x, uv2.y, uvRot.x + uvRot.y * atan(t * 11.0)));
                col.r *= sin(col.b);

                // Modulate colors using the audio waveform
                col *= float3(1.0, 1.0 - _InstrumentAmplitudes[2]*40., 1.0 - _InstrumentAmplitudes[0]*20.);

                // Output to screen
                return float4(col * 2.5, 1.0);
            }
            ENDCG
        }
    }
}
