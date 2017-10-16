Shader "Tessellated/Bezier Curve" 
{
    Properties 
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _InternalTessellation("Internal Tessellation", Float) = 5
        _EdgeTessellation("Edge Tessellation", Float) = 5
        [Toggle]_HideWireframe("Hide Wireframe", Float) = 0
    }

    SubShader 
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Cull Off

            CGPROGRAM
                #pragma target 5.0
                #include "UnityCG.cginc"
                #include "../Addon/UCLA GameLab Wireframe Functions.cginc"
                #include "./Bezier Curve Functions.cginc"
                #pragma vertex vert
                #pragma hull hull
                #pragma domain dom
                #pragma geometry geom 
                #pragma fragment frag

                // Quad
                #define MAX_POINTS 4

                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _InternalTessellation;
                float _EdgeTessellation;
                float _HideWireframe;
                uniform StructuredBuffer<float3> _controlPoints;

                // Vertex to Hull
                struct VS_OUTPUT {
                    float4 position     : POSITION;     // vertex position
                    float2 uv           : TEXCOORD0;
                };
                
                // Hull to Domain
                // Output control point
                struct HS_OUTPUT {
                    float3 position : BEZIERPOS;
                    float2 uv       : TEXCOORD0;
                };

                // Hull Constant to Domain
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

                // Domain to Geometry 
                struct DS_OUTPUT
                {
                    float4 position : POSITION;
                    float4 col : COLOR;
                    float2 uv : TEXCOORD0;
                };

                // Geometry to Fragment
                struct GS_OUTPUT
                {
                    float4 position     : POSITION;     // fragment position
                    float4 col          : COLOR;
                    float2 uv           : TEXCOORD0;
                    float3 normal       : NORMAL;
                    float3 dist         : TEXCOORD1;
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
                                
                // Patch Constant Function
                HS_CONSTANT_OUTPUT hsConstant(
                    InputPatch<VS_OUTPUT, MAX_POINTS> ip,
                    uint PatchID : SV_PrimitiveID )
                {   
                    HS_CONSTANT_OUTPUT output;

                    float edge = _EdgeTessellation;
                    float inside = _InternalTessellation;
                    
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
                
                // Domain Shader
                [domain("quad")]
                [partitioning("fractional_even")]
                [outputtopology("triangle_cw")]
                [outputcontrolpoints(MAX_POINTS)]
                [patchconstantfunc("hsConstant")]
                HS_OUTPUT hull(InputPatch<VS_OUTPUT, MAX_POINTS> ip, uint i : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID ) {
                    HS_OUTPUT output;
                    output.uv = ip[i].uv;
                    
                    output.position = ip[i].position;
                    
                    return output;
                }
                
                // Domain Shader
                [domain("quad")]
                DS_OUTPUT dom(HS_CONSTANT_OUTPUT input, float2 UV : SV_DomainLocation, const OutputPatch<HS_OUTPUT, MAX_POINTS> patch ) {
                    DS_OUTPUT output;

                    // Why do we have to do this?
                    float2 uv = UV;
                    uv *= 0.9999998;
                    uv.x += 0.0000001;
                    uv.y += 0.0000001;

                    float4 pos = float4(SurfaceSolve(_controlPoints, uv),1);
                    output.position = pos;
                    output.uv = UV;
                    output.col = float4(1, 1, 1, 1);

                    return output;    
                }
                
                // Geometry Shader
                [maxvertexcount(6)]
                void geom(triangle DS_OUTPUT p[3], inout TriangleStream<GS_OUTPUT> triStream)
                {
                    float3 norm = cross(p[0].position - p[1].position, p[0].position - p[2].position);
                    norm = normalize(mul(unity_ObjectToWorld, float4(norm, 0))).xyz;

                    p[0].position = UnityObjectToClipPos(p[0].position);
                    p[1].position = UnityObjectToClipPos(p[1].position);
                    p[2].position = UnityObjectToClipPos(p[2].position);

                    float3 dist = UCLAGL_CalculateDistToCenter(p[0].position, p[1].position, p[2].position);

                    GS_OUTPUT i1, i2, i3;
                    
                    // Add the normal facing triangle
                    i1.position = p[0].position;
                    i1.col = p[0].col;
                    i1.uv = p[0].uv;
                    i1.normal = norm;
                    i1.dist = float3(dist.x, 0, 0);

                    i2.position = p[1].position;
                    i2.col = p[1].col;
                    i2.uv = p[1].uv;
                    i2.normal = norm;
                    i2.dist = float3(0, dist.y, 0);

                    i3.position = p[2].position;
                    i3.col = p[2].col;
                    i3.uv = p[2].uv;
                    i3.normal = norm;
                    i3.dist = float3(0, 0, dist.z);

                    triStream.Append(i1);
                    triStream.Append(i2);
                    triStream.Append(i3);   
                }
                
                // Fragment Shader
                float4 frag(GS_OUTPUT input, fixed facing : VFACE) : COLOR
                {
                    float alpha = UCLAGL_GetWireframeAlpha(input.dist, .25, 100, 1);
                    clip(alpha - 0.9);
                    
                    float4 col = input.col;
                    float2 uv = TRANSFORM_TEX (input.uv, _MainTex);
                    col = tex2D(_MainTex, uv) * float4(input.normal * facing, 1);
                    
                    return col;
                }
            
            ENDCG
        }
    } 
}
