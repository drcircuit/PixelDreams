Shader "Custom/OuterRim"
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
            float3 l = float3(1,1,1);
            float2x2 rotate2d(float angle)
			{
				float c = cos(angle);
				float s = sin(angle);
				return float2x2(c, -s, s, c);
			}

            float2 map(float3 p){
                float s=2,e,f,o;
                for(e=p.y/2-.8, f=-.5;s<4e2;s*=1.6){
                    p.xz = mul(p.xz, rotate2d(1));
                    e+=abs(dot(sin(p*s)/s,l));
                    f+=abs(dot(sin(p*s*.5)/s,l));
                }
                o = 1+(f>.001?e:-exp(-f*f));
                return float2(max(o,0), min(f, max(e,.5)));
            }

            float3 rayMarch(float3 ro, float3 rd){
                float t = 1, dt = 0.035;
                float3 col = float3(0,0,0);
                for(int i =0; i<100; i++){
				    float2 d = map(ro + t*rd);
                    float c = d.x, f=d.y;
                    t+= dt*f;
                    dt *= 1.035;
                    col = .95*col+0.9*float3(c*c*c, c*c, c);
				}
                return col;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Normalized pixel coordinates (from 0 to 1)
                float2 uv = i.uv;
                uv = (2.0*uv - 1.0) * float2(_iResolution.x/_iResolution.y, .25);
                uv.x *=.25;
                float2 n,q,p = uv;
                float d = dot(p,p);
                float S=8.0;
                float a,j = 0;
                for(float2x2 m = rotate2d(.5+.04*_MyTime);j++<30.;){
                    p = mul(p,m);
                    n = mul(n,m);  
                    q=p*S+_MyTime*.02+sin(_MyTime*4.-d*.04)*.8+j+n;
                    a+=dot(cos(q)/S, float2(.2,.2));
                    n-=sin(q);
                    S*=1.2;
                }
                float cb = abs(cos(_InstrumentAmplitudes[0]*100.))*4.0;
                float4 col = (a+.2)*float4(sin(_InstrumentAmplitudes[1]*1000.+cb),0.,0,0)+lerp(a+a/d, a+a-d, sin(_MyTime*.9));
                // Output to screen
                return col;
            }
            ENDCG
        }
    }
}
