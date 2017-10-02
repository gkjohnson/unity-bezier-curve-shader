// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// TODO : Something weird happens with this shader 
// when it's batched.
Shader "SinTest" 
{
	Properties 
	{
		_SinOffset ("Sin Offset", Float) = 0
		//_MainTex ("Main Texture", 2D) = "white" {}
	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha 
			LOD 200
			
			CGPROGRAM
				#pragma target 5.0
				#include "UnityCG.cginc"
				#pragma vertex vert
				#pragma hull hull
				#pragma domain dom
				#pragma geometry geom
				#pragma fragment frag

				
				float4 _Color;
				float _SinOffset;
				
				
				// VERTEX SHADER //
				// Vertex to Geometry
				struct VS_OUTPUT
				{
					float4	position	: POSITION;		// vertex position
				};
				// Vertex Shader
				VS_OUTPUT vert(appdata_base v)
				{
					VS_OUTPUT output;
					output.position =  UnityObjectToClipPos(v.vertex);		
					output.position = v.vertex;			
					return output;
				}


				// HULL SHADER //
				// Output control point
				struct HS_OUTPUT
				{
				    float3 position	: BEZIERPOS;
				};

				// Output patch constant data.
				struct HS_CONSTANT_OUTPUT
				{
				    float Edges[3]        : SV_TessFactor;
				    float Inside[1]       : SV_InsideTessFactor;
				    
				    //float3 vTangent[4]    : TANGENT;
				    //float2 vUV[4]         : TEXCOORD;
				    //float3 vTanUCorner[4] : TANUCORNER;
				    //float3 vTanVCorner[4] : TANVCORNER;
				    //float4 vCWts          : TANWEIGHTS;
				};
				#define MAX_POINTS 3

				// Patch Constant Function
				HS_CONSTANT_OUTPUT hsConstant(
					InputPatch<VS_OUTPUT, MAX_POINTS> ip,
				    uint PatchID : SV_PrimitiveID )
				{	
				    HS_CONSTANT_OUTPUT output;

					float edge = 32.0f;
					float inside = 32.0f;
					
					output.Edges[0] = edge;
					output.Edges[1] = edge;
					output.Edges[2] = edge;
					//output.Edges[3] = edge;
				    
				    output.Inside[0] = inside;
				    //output.Inside[1] = inside;
				    				    						    
				    return output;
				}
				
				[domain("tri")]
				[partitioning("integer")]
				[outputtopology("triangle_cw")]
				[outputcontrolpoints(MAX_POINTS)]
				[patchconstantfunc("hsConstant")]
				HS_OUTPUT hull( 
				    InputPatch<VS_OUTPUT, MAX_POINTS> ip, 
				    uint i : SV_OutputControlPointID,
				    uint PatchID : SV_PrimitiveID )
				{
				    HS_OUTPUT output;
					output.position = ip[i].position;

				    return output;
				}
				
				


				// DOMAIN SHADER //
				struct DS_OUTPUT
				{
					float4 position : POSITION;
					float4 col : COLOR;
				};
				
				[domain("tri")]
				DS_OUTPUT dom(
					HS_CONSTANT_OUTPUT input,
					float3 UV : SV_DomainLocation,
					const OutputPatch<HS_OUTPUT, MAX_POINTS> patch )
				{
				    DS_OUTPUT output;
				    
				    //float3 topMidpoint = lerp(patch[0].position, patch[1].position, UV.x);
				    //float3 bottomMidpoint = lerp(patch[3].position, patch[2].position, UV.x);
				    
				    //float4 pos = float4(lerp(topMidpoint, bottomMidpoint, UV.y),1);
				    //output.position = pos;
				    //output.position = mul(UNITY_MATRIX_MVP, pos);		

				    //Output.color = float4(UV.yx, 1-UV.x, 1);
				    
				    float3 pos = 
				    	UV.x * patch[0].position +
				    	UV.y * patch[1].position + 
				    	UV.z * patch[2].position;
				    	
				    	
				    pos.z += sin(UV.x * 10.0f + _SinOffset) + sin(UV.y * 10.0f + _SinOffset);
				    pos.z *= 0.1f;
				    
				    output.position = UnityObjectToClipPos(float4(pos,1));
				    output.col = float4(UV.x,UV.y,0,1);
				    
				    return output;    
				}


				
				// GEOMETRY SHADER //
				// Geometry to  UCLAGL_fragment
				struct GS_OUTPUT
				{
					float4	position	: POSITION;		// fragment position
					float4  col 		: COLOR;
				};
				// Geometry Shader
				[maxvertexcount(6)]
				void geom(triangle DS_OUTPUT p[3], inout TriangleStream<GS_OUTPUT> triStream)
				{
				
					GS_OUTPUT pIn;
					
					// Add the normal facing triangle
					pIn.position = p[0].position;
					pIn.col = p[0].col;
					triStream.Append(pIn);
					
					pIn.position = p[1].position;
					pIn.col = p[1].col;
					triStream.Append(pIn);
					
					pIn.position = p[2].position;
					pIn.col = p[2].col;
					triStream.Append(pIn);	
					
					// Add a reverse facing triangle
					pIn.position = p[0].position;
					pIn.col = p[0].col;
					triStream.Append(pIn);				
					
					pIn.position = p[1].position;
					pIn.col = p[1].col;
					triStream.Append(pIn);
					
					pIn.position = p[2].position;
					pIn.col = p[2].col;
					triStream.Append(pIn);	
				}
				
				// FRAGMENT SHADER
				// Fragment Shader
				float4 frag(GS_OUTPUT input) : COLOR
				{				
					float4 col = input.col;
					
					return col;
				}
			
			ENDCG
		}
	} 
}
