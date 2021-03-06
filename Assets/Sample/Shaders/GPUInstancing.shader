﻿Shader "Custom/GPUInstancing"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Shaders/Libs/ColorUtil.cginc"
#include "Assets/Shaders/Libs/Quaternion.cginc"
#include "GPUParticleCommon.cginc"

	struct VertexData
	{
		float3 vertex;
		float3 normal;
		float2 uv;
		float4 tangent;
	};

	struct ParticleData
	{
		bool isActive;      // 有効フラグ
		float3 position;    // 座標
		float3 velocity;    // 加速度
		float4 color;       // 色
		float duration;     // 生存時間
		float scale;        // サイズ
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 color : COLOR;
	};

	StructuredBuffer<uint> _indices;
	StructuredBuffer<VertexData> _vertex;
	StructuredBuffer<ParticleData> _Particles;

	sampler2D _MainTex;

	float4 _MainTex_ST;
	float4 _RotationOffsetAxis;

	v2f vert(uint vid : SV_VertexID, uint iid: SV_InstanceID)
	{
		uint idx = _indices[vid];
		float4 pos = float4(_vertex[idx].vertex, 1.0);
		float2 uv = _vertex[idx].uv;
		float3 normal = _vertex[idx].normal;
		float4 tangent = _vertex[idx].tangent;

		uint iidx = GetParticleIndex(iid);

		float4 rotation = getAngleAxisRotation(_RotationOffsetAxis.xyz, _RotationOffsetAxis.w);
		
		pos.xyz *= _Particles[iidx].scale;
		pos.xyz = rotateWithQuaternion(pos.xyz, rotation);
		pos.xyz += _Particles[iidx].position;

		v2f o;
		o.pos = mul(UNITY_MATRIX_VP, pos);
		o.uv = uv;
		o.color = _Particles[iidx].color;

		return o;
	}

	fixed4  frag(v2f i) : SV_Target
	{

		fixed4 col = tex2D(_MainTex, i.uv) * i.color;

		return col;
	}
	ENDCG

	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			Lighting Off

			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 5.0
#pragma shader_feature GPUPARTICLE_CULLING_ON


			ENDCG
		}
	}

	Fallback Off
}
