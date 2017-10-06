// TODO : Something weird happens with this shader 
// when it's batched.
// It could have something to do with the shader getting batched
// and therefore not having the right transformed "forward"
Shader "sin-test" 
{
	Properties 
	{
		_SinOffset ("Sin Offset", Float) = 0
        _TessellationAmt("Tessellation", Float) = 5
	}

	SubShader 
	{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

		Pass
		{		
			CGPROGRAM
				#pragma target 5.0
				#include "UnityCG.cginc"
				#pragma vertex vert
				#pragma hull hull
				#pragma domain dom
				#pragma geometry geom
				#pragma fragment frag
		        
                // Triangle
				#define MAX_POINTS 3
        
				float _SinOffset;
                float _TessellationAmt;

				// Vertex to Hull
				struct VS_OUTPUT { float4 position : POSITION; };

                // Hull to Domain
                // Output control point
                struct HS_OUTPUT { float3 position : BEZIERPOS; };

                // Hull Constant to Domain
                // Output patch constant data.
                struct HS_CONSTANT_OUTPUT {
                    float Edges[3]        : SV_TessFactor;
                    float Inside[1]       : SV_InsideTessFactor;

                    //float3 vTangent[4]    : TANGENT;
                    //float2 vUV[4]         : TEXCOORD;
                    //float3 vTanUCorner[4] : TANUCORNER;
                    //float3 vTanVCorner[4] : TANVCORNER;
                    //float4 vCWts          : TANWEIGHTS;
                };

                // Domain to Geometry
                struct DS_OUTPUT {
                    float4 position : POSITION;
                    float4 col : COLOR;
                };

                 // Geometry to Fragment
                struct GS_OUTPUT {
                    float4	position	: POSITION;
                    float4  col 		: COLOR;
                };

				// Vertex Shader
				VS_OUTPUT vert(appdata_base v) {
					VS_OUTPUT output;
					output.position =  UnityObjectToClipPos(v.vertex);		
					output.position = v.vertex;			
					return output;
				}
               
                // Hull Shader
                // Transform and output control points for the hull points
                // to then be transformed in the domain shader
                [domain("tri")]
                [partitioning("integer")]
                [outputtopology("triangle_cw")]
                [outputcontrolpoints(MAX_POINTS)]
                [patchconstantfunc("hsConstant")]
                HS_OUTPUT hull(InputPatch<VS_OUTPUT, MAX_POINTS> ip, uint i : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID) {
                    HS_OUTPUT output;
                    output.position = ip[i].position;

                    return output;
                }

				// Patch Constant Function
                // Outputs edge and internal tesellation values for the triangle
                // This could be driven by camera skew, distance from camera, texture sampling, etc
                // to change the detail that is tessellated to
                HS_CONSTANT_OUTPUT hsConstant(InputPatch<VS_OUTPUT, MAX_POINTS> ip, uint PatchID : SV_PrimitiveID) {	
				    HS_CONSTANT_OUTPUT output;

					float edge = _TessellationAmt;
					float inside = _TessellationAmt;
					
					output.Edges[0] = edge;
					output.Edges[1] = edge;
					output.Edges[2] = edge;
					//output.Edges[3] = edge;
				    
				    output.Inside[0] = inside;
				    //output.Inside[1] = inside;
				    				    						    
				    return output;
				}
				
                // Domain Shader
                // Transform all the points from the hull shader here
                // The detail from the tessellated patch and the hull control points 
                // are available here
				[domain("tri")]
				DS_OUTPUT dom(HS_CONSTANT_OUTPUT input, float3 UV : SV_DomainLocation, const OutputPatch<HS_OUTPUT, MAX_POINTS> patch ) {
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

				// Geometry Shader
                // Produce new geometry if desired
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
				
				// Fragment Shader
                // Pixel Color
				float4 frag(GS_OUTPUT input) : COLOR
				{				
					float4 col = input.col;
					
					return col;
				}
			
			ENDCG
		}
	} 
}
