Shader "Custom/LandscapeEffect"
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
        _LightDirection ("LightDirection", Vector) = (0.1, 0.1, -.4, 0.0)
        _LightColor ("LightColor", Vector) = (1.0, .95,0.8, 1.0)
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

            struct mappedSurface
            {
                float distance;
                int materialId;
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
            float3 _LightDirection;
            float4 _LightColor;

            float sdPlane(float3 p)
            {
                return p.y;
            }

            mappedSurface map(float3 p)
            {
                float ocean = sdPlane(p);
                mappedSurface surface;
                surface.distance = ocean;
                surface.materialId = 1;
                return surface;
            }

            float3 GetNormal(float3 p)
            {
                float2 eps = float2(0.001, 0.0);
                float3 n;
                n.x = map(p + eps.xyy).distance - map(p - eps.xyy).distance;
                n.y = map(p + eps.yxy).distance - map(p - eps.yxy).distance;
                n.z = map(p + eps.yyx).distance - map(p - eps.yyx).distance;
                return normalize(n);
            }

            float march(float3 ro, float3 rd, out int materialId)
            {
                float d = 0.0;
                materialId = 0;
                for (int i = 0; i < 100; i++)
                {
                    float3 p = ro + rd * d;
                    mappedSurface surface = map(p);
                    if (surface.distance < 0.001)
                    {
                        materialId = surface.materialId;
                        return d;
                    }
                    d += surface.distance;
                    // account for max distance, break if too far
                    if (d > 100.0)
                    {
                        break;
                    }
                    // account for inside overstepping
                    if (d < 0.0)
                    {
                        d = 0.00001;
                    }
                }
                return d;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Normalized pixel coordinates (from 0 to 1)
                float2 uv = i.uv;
                // Correct for aspect ratio
                float aspect = _iResolution.x / _iResolution.y;
                uv.x *= aspect;

                // Calculate camera parameters
                float3 ro = float3(0, 1.0, -5.0); // Camera position
                float3 rd = normalize(float3(uv, 1.0)); // Ray direction
                _LightDirection.z = -rd.z;
                // Directly visualize the dot product between the ray direction and light direction
                float sunDot = dot(rd, normalize(_LightDirection));

                // Output the sunDot value as the color
                return float4(sunDot, sunDot, sunDot, 1.0);
            }
            ENDCG
        }
    }
}