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
            float _WaveFormScale = 0.5;
            float _SpectrumScale = 0.2;
            float4 _iResolution;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Normalized pixel coordinates (from 0 to 1)
                float2 uv = i.uv;

                // Correct for aspect ratio
                float aspect = _iResolution.x / _iResolution.y;
                uv.x *= aspect;

                // Time varying pixel color
                float3 col = 0.5 + 0.5 * cos(_MyTime + uv.xyx + float3(0, 2, 4));
                
                // Calculate the band width and index
                int bandWidth = 1024 / _Bands;
                int bandIndex = int(i.uv.x * _Bands);

                // Average the spectrum values within the band
                float spectrumValue = 0.0;
                for (int j = 0; j < bandWidth; j++)
                {
                    spectrumValue += _AudioSpectrum[bandIndex * bandWidth + j];
                }
                spectrumValue /= bandWidth;
                spectrumValue = pow(spectrumValue, _SpectrumScale);

                // Draw vertical bars based on the spectrum value
                if (uv.y < spectrumValue)
                {
                    col *= spectrumValue;
                }

                // Example of drawing waveform as a translucent red wave at the center up and down in the y direction based on amplitude
                if (i.uv.x < 1.0) // Ensure rendering within valid range
                {
                    int spectrumIndex = int(i.uv.x * 1023.0); // Assuming fftResolution is 1024
                    float waveformValue = _AudioWaveform[spectrumIndex] * _WaveFormScale;
                    if (abs(uv.y - 0.5) < waveformValue)
                        col += float3(1, -1, -2) * waveformValue;
                }

                // Add circles along the x axis for each instrument, radius given by amplitude, evenly spaced across the x axis
                for (int j = 0; j < 5; j++)
                {
                    float instrumentAmplitude = _InstrumentAmplitudes[j];
                    float instrumentX = (float(j) + 0.5) / 5.0; // Center circles within each segment
                    instrumentX *= aspect; // Correct for aspect ratio
                    float2 instrumentCenter = float2(instrumentX, 0.5); // Center vertically
                
                    // Calculate distance from circle center
                    float distance = length(uv - instrumentCenter);
                    
                    // If within the radius, set color
                    if (distance < instrumentAmplitude)
                    {
                        col += float3(1, 0, 0) * instrumentAmplitude * 100000.0;
                    }
                }
                // Output to screen
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
