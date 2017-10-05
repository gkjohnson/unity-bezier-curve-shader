// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "HullTest" 
{
	Properties 
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_TessellationAmt ("Tessellation", Float) = 5
	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		Pass
		{
			Cull Off
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
				sampler2D _MainTex;
				float4 _MainTex_ST;
				
				uniform StructuredBuffer<float3> _controlPoints;
				float _TessellationAmt;

				// Vertex to Geometry
				struct VS_OUTPUT
				{
					float4 position     : POSITION;		// vertex position
					float2 uv           : TEXCOORD0;
				};
                
                // Output control point
                struct HS_OUTPUT
                {
                    float3 position	: BEZIERPOS;
                    float2 uv       : TEXCOORD0;
                };

                // Output patch constant data.
                struct HS_CONSTANT_OUTPUT
                {
                    float Edges[4]        : SV_TessFactor;
                    float Inside[2]       : SV_InsideTessFactor;

                    //float3 vTangent[4]    : TANGENT;
                    //float2 vUV[4]         : TEXCOORD;
                    //float3 vTanUCorner[4] : TANUCORNER;
                    //float3 vTanVCorner[4] : TANVCORNER;
                    //float4 vCWts          : TANWEIGHTS;
                };

                struct DS_OUTPUT
                {
                    float4 position : POSITION;
                    float4 col : COLOR;
                    float2 uv : TEXCOORD0;
                };

                // GEOMETRY SHADER //
                struct GS_OUTPUT
                {
                    float4	position	: POSITION;		// fragment position
                    float4  col 		: COLOR;
                    float2 uv : TEXCOORD0;
                };

				// Vertex Shader
				VS_OUTPUT vert(appdata_base v)
				{
					// Pass through shader
					// The control points define position
					VS_OUTPUT output;
					output.position = v.vertex;
					output.uv = v.texcoord.xy;
					return output;
				}

				#define MAX_POINTS 4
				
				// Patch Constant Function
				HS_CONSTANT_OUTPUT hsConstant(
					InputPatch<VS_OUTPUT, MAX_POINTS> ip,
				    uint PatchID : SV_PrimitiveID )
				{	
				    HS_CONSTANT_OUTPUT output;

					float edge = _TessellationAmt;
					float inside = _TessellationAmt;
					
					// Set the tessellation factors for the inside
					// and outside edges of the quad
					output.Edges[0] = edge;
					output.Edges[1] = edge;
					output.Edges[2] = edge;
					output.Edges[3] = edge;
				    
				    output.Inside[0] = inside;
				    output.Inside[1] = inside;
				    				    						    
				    return output;
				}
				
				[domain("quad")]
				[partitioning("fractional_even")]
				[outputtopology("triangle_cw")]
				[outputcontrolpoints(MAX_POINTS)]
				[patchconstantfunc("hsConstant")]
				HS_OUTPUT hull( 
				    InputPatch<VS_OUTPUT, MAX_POINTS> ip, 
				    uint i : SV_OutputControlPointID,
				    uint PatchID : SV_PrimitiveID )
				{
				    HS_OUTPUT output;
					output.uv = ip[i].uv;
					
					output.position = ip[i].position;
					
				    return output;
				}				
				
				// returns the factorial of n until "stop" is hit
				float factorial(int n, int stop)
				{
					if( n<=0 )
					{
						return 1;
					}
					if( stop <= 0 )
					{
						stop = 1;
					}
					
					float res = 1;
					for( int i = n ; i >= stop ; i -- )
					{
						res *= i;
					}
					return res;
				}
				// returns the factorial of n
				float factorial(int n)
				{
					return factorial(n,2);
				}
				
				// Takes an array of 16 control points to solve
				// the points are expected to be in the following format (Pxy)
				// P00 P10 P20 P30 P01 P11 ... P23 P33
				float3 SurfaceSolve(float3 cps[16], float2 uv)
				{
					float u = uv.y;
					float v = uv.x;
					
					float n = 3; // x target
					float m = 3; // y target
					
					float3 pos = float3(0,0,0);
					for(float y = 0 ; y <= m ; y ++)
					{
						float ypoly = pow(1-v, m-y) * pow(v,y); // 0
						float ybc = factorial(m,y+1) / (factorial(m-y));

						for( float x = 0 ; x <= n ; x ++)
						{
							float3 cp = cps[ y * 4 + x ];
							
							float xpoly = pow(1-u, n-x) * pow(u,x); // 0
							float xbc = factorial(n,x+1) / (factorial(n-x));
						
							pos += xbc * xpoly * ybc * ypoly * cp;
						
						}
					}
					return pos;
				}
				float3 SurfaceSolve(StructuredBuffer<float3> cps, float2 uv)
				{
					float3 arr[16];
					for( int i = 0 ; i < 16 ; i ++ )
					{
						arr[i] = cps[i];
					}
					return SurfaceSolve(arr, uv);
				}
				
				// Solves for a cubic Bezier curve using the
				// four given control points and returns the point
				// at "t" interpolation on the curve
				float3 CurveSolve(float3 cp0, float3 cp1, float3 cp2, float3 cp3, float t)
				{
					// summed bezier curve formula
					float3 cps[4] = {cp0, cp1, cp2, cp3};
					float3 pos = float3(0,0,0);
					int n = 3;
					for( int i = 0 ; i <= n ; i ++ )
					{
						// the poly and binomial coefficient parts
						// of the Bernstein polynomial
						float poly = pow(1-t, n-i) * pow(t,i);
						
						// n!/i!(n-i)! = (n*n-1*...*i+1)/(n-i)!;
						float bc = factorial(n,i+1) / (factorial(n-i));
						
						// multiplied 
						pos += bc * poly * cps[i];
					}
					return pos;
					
					// expanded cubic curve formula
					pos = 
						pow(1.0f - t, 3.0f) * cp0 + 
						3.0f * pow(1.0f - t, 2.0f) * t * cp1 + 
						3.0f * (1.0f - t) * pow(t, 2.0f) * cp2 + 
						pow(t, 3.0f) * cp3;

					return pos;
				}
				
				[domain("quad")]
				DS_OUTPUT dom(
					HS_CONSTANT_OUTPUT input,
					float2 UV : SV_DomainLocation,
					const OutputPatch<HS_OUTPUT, MAX_POINTS> patch )
				{
				    DS_OUTPUT output;

				    // Why do we have to do this?
					float2 uv = UV;
					uv *= 0.9999998;
					uv.x += 0.0000001;
					uv.y += 0.0000001;

				    float4 pos = float4(SurfaceSolve(_controlPoints, uv),1);
					output.position = UnityObjectToClipPos(pos);

					output.uv = UV;

				    return output;    
				}
				
				// Geometry Shader
				[maxvertexcount(6)]
				void geom(triangle DS_OUTPUT p[3], inout TriangleStream<GS_OUTPUT> triStream)
				{
				
					GS_OUTPUT i1, i2, i3;
					
					// Add the normal facing triangle
					
					i1.position = p[0].position;
					i1.col = p[0].col;
					i1.uv = p[0].uv;
					
					i2.position = p[1].position;
					i2.col = p[1].col;
					i2.uv = p[1].uv;
					
					i3.position = p[2].position;
					i3.col = p[2].col;
					i3.uv = p[2].uv;
					
					triStream.Append(i1);
					triStream.Append(i2);
					triStream.Append(i3);	
				}
				
				// Fragment Shader
				float4 frag(GS_OUTPUT input) : COLOR
				{				
					float4 col = input.col;
					float2 uv = TRANSFORM_TEX (input.uv, _MainTex);
					col = tex2D(_MainTex, uv);
					
					return col;
				}
			
			ENDCG
		}
	} 
}
