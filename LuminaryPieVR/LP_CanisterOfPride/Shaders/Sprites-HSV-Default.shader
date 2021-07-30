// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hue Shift Sprites/HSV Default"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_H("Hue", Range(-180,180)) = 0
		_S("Saturation", Range(0,2)) = 1.0
		_V("Value", Range(0,2)) = 1.0
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ PIXELSNAP_ON
			#include "UnityCG.cginc"
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				half2 texcoord  : TEXCOORD0;
			};
			
			

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color;
				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap (OUT.vertex);
				#endif

				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			float _AlphaSplitEnabled;

			fixed4 SampleSpriteTexture (float2 uv)
			{
				fixed4 color = tex2D (_MainTex, uv);
				if (_AlphaSplitEnabled)
					color.a = tex2D (_AlphaTex, uv).r;

				return color;
			}
			
			float3 r2h(float3 i)
			{
				float4 a = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
				float4 b = lerp(float4(i.bg, a.wz), float4(i.gb, a.xy), step(i.b, i.g));
				float4 c = lerp(float4(b.xyw, i.r), float4(i.r, b.yzx), step(b.x, i.r));

				float d = c.x - min(c.w, c.y);
				float e = 1.0e-10;
				return float3(abs(c.z + (c.w-c.y) / (6.0*d+e)), d / (c.x+e), c.x);
			}

			float3 h2r(float3 i)
			{
				float4 a = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
				float3 b = abs(((i.xxx + a.xyz) -floor(i.xxx + a.xyz)) * 6.0 - a.www);
				return i.z * lerp(a.xxx, clamp(b - a.xxx, 0.0, 1.0), i.y);
			}

			float _H;
			float _S;
			float _V;
			
			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 c = SampleSpriteTexture (IN.texcoord) * IN.color;
				float3 hsv = r2h(c.rgb);
				hsv.x += _H/360;
				hsv.y *= _S;
				hsv.z *= _V;
				c.rgb = h2r(hsv);
				c.rgb *= c.a;
				return c;
			}
		ENDCG
		}
	}
}
