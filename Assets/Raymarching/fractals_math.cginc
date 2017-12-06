#ifndef fractals_math_h
#define fractals_math_h

#include "foundation.cginc"

static float julia_threshold = 10;

float Julia(float3 pos) {

	int iterations = 16;
	float threshold = 10.0;
	float4 C = float4(0.18,0.88,0.24,0.16);

	float4 p = float4(pos, 0.0);
	float4 dp = float4(1.0, 0.0,0.0,0.0);
	for (int i = 0; i < iterations; i++) {
		dp = 2.0* float4(p.x*dp.x-dot(p.yzw, dp.yzw), p.x*dp.yzw+dp.x*p.yzw+cross(p.yzw, dp.yzw));
		p = float4(p.x*p.x-dot(p.yzw, p.yzw), float3(2.0*p.x*p.yzw)) + C;
		float p2 = dot(p,p);
		if (p2 > threshold) break;
	}
	float r = length(p);
	return  0.5 * r * log(r) / length(dp);

}

#endif // distance_functions_h
