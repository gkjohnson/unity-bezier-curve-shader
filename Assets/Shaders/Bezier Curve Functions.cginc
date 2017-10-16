                
// Bezier Curve Functions
// returns the factorial of n until "stop" is hit
float factorial(int n, int stop) {
    if(n<=0) return 1;
    if(stop <= 0) stop = 1;
                    
    float res = 1;
    for(int i = n; i >= stop; i--) {
        res *= i;
    }
    return res;
}

// returns the factorial of n
float factorial(int n) {
    return factorial(n,2);
}
                
// Takes an array of 16 control points to solve
// the points are expected to be in the following format (Pxy)
// P00 P10 P20 P30 P01 P11 ... P23 P33
float3 SurfaceSolve(float3 cps[16], float2 uv) {
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

float3 SurfaceSolve(StructuredBuffer<float3> cps, float2 uv) {
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
float3 CurveSolve(float3 cp0, float3 cp1, float3 cp2, float3 cp3, float t) {
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