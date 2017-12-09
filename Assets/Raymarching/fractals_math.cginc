#ifndef fractals_math_h
#define fractals_math_h

#include "foundation.cginc"

float Julia(float3 pos, int iterations) {

	//int iterations = 16;
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

///////////////

#define Phi (.5*(1.+sqrt(5.)))

float3 n1 = normalize(float3(-Phi,Phi-1.0,1.0));
float3 n2 = normalize(float3(1.0,-Phi,Phi+1.0));
float3 n3 = normalize(float3(0.0,0.0,-1.0));

float4x4  rotationMatrix(float3 v, float angle)
{
	float c = cos(radians(angle));
	float s = sin(radians(angle));
	
	return float4x4(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y, 0.0,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x, 0.0,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z, 0.0,
		0.0, 0.0, 0.0, 1.0);
}

float4x4 translate(float3 v) {
	return float4x4(1.0,0.0,0.0,0.0,
		0.0,1.0,0.0,0.0,
		0.0,0.0,1.0,0.0,
		v.x,v.y,v.z,1.0);
}

float4x4 scale4(float s) {
	return float4x4(s,0.0,0.0,0.0,
		0.0,s,0.0,0.0,
		0.0,0.0,s,0.0,
		0.0,0.0,0.0,1.0);
}

float DE(
		float3 z,
		int iterations = 11,
		int colorIterations = 2,
		float scale = 3,
		float size = 0.5,
		float3 plnormal = float3(1, -0.04950, 0.70298),
		float3 offset = float3(0.85065, 0.56140, 0.11404),
		float angle1 = 47.81520,
		float3 rot1 = float3(0.18644, -0.38984, 0.66102),
		float angle2 = 93.75120,
		float3 rot2 = float3(0.83050, 1, 1)
		) {

	float4 orbitTrap = float4(10000.0, 10000.0, 10000.0, 10000.0);

	float4x4 fracRotation2 = rotationMatrix(normalize(rot2), angle2);
	float4x4 fracRotation1 = rotationMatrix(normalize(rot1), angle1);
    float4x4 M = fracRotation2 * translate(offset) * scale4(scale) * translate(-offset) * fracRotation1;

	float s=1.;
	float t;
	// Folds.
	//Dodecahedral.. you can use other sets of foldings!
	z = abs(z);
	t=dot(z,n1); if (t>0.0) { z-=2.0*t*n1; }
	t=dot(z,n2); if (t>0.0) { z-=2.0*t*n2; }
	z = abs(z);
	t=dot(z,n1); if (t>0.0) { z-=2.0*t*n1; }
	t=dot(z,n2); if (t>0.0) { z-=2.0*t*n2; }
	z = abs(z);
	//combine DEs... explore different combinations ;)
	float dmin=dot(z-float3(size,0.,0.),normalize(plnormal));

	for(int i=0; i<iterations; i++){
		// Rotate, scale, rotate (we need to cast to a 4-component vector).
		z = mul(M, float4(z,1.0)).xyz;s/=scale;
		
		// Folds.
		//Dodecahedral.. you can use other sets of foldings!
		z = abs(z);
		t=dot(z,n1); if (t>0.0) { z-=2.0*t*n1; }
		t=dot(z,n2); if (t>0.0) { z-=2.0*t*n2; }
		z = abs(z);
		t=dot(z,n1); if (t>0.0) { z-=2.0*t*n1; }
		t=dot(z,n2); if (t>0.0) { z-=2.0*t*n2; }
		z = abs(z);
       	if (i<colorIterations) orbitTrap = min(orbitTrap, abs(float4(z.x,z.y,z.z,dot(z.xyz,z.xyz))));
				
		//combine DEs... explore different combinations ;)
		//the base DE is the distance to the plane going through float3(Size,0.,0.) and which normal is plnormal
		dmin=max(dmin,s*dot(z-float3(size,0.,0.),normalize(plnormal)));
	}
	return abs(dmin);//you can take a look to the inside
}

///////////////

float3x3  rotationMatrix3(float3 v, float angle)
{
	float c = cos(radians(angle));
	float s = sin(radians(angle));
	
	return float3x3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}

float trap(float3 p, float3x3 fracRotation2, float3 O3, float cylHeight, float cylRad, float val){
	//	p=p.yxz;
	p = mul(p, fracRotation2);
		
	return abs(length(p.xz-O3.xy)-val);
	p.x-=val;
	return max(abs(p.z)-cylHeight,length(p.xy)-cylRad);
}	

// The fractal distance estimation calculation
float octahedron(
		float3 z,
		float Scale = 1.53332,
		float3 Offset = float3(0.48246, 0.09649, 0.15789),
		float Angle1 = -119.99900,
		float3 Rot1 = float3(1.00000, -0.50850, 0.44068),
		float Angle2 = 29.99880,
		float3 Rot2 = float3(0.50848, 1.00000, -0.62800),
		float val = 0,
		float cylRad = 0.10000,
		float cylHeight = 2.00000,
		float3 O3 = float3(1, 1, 1),
		float Iterations = 26,
		float ColorIterations = 2
		) {

	float4 orbitTrap = float4(10000.0, 10000.0, 10000.0, 10000.0);

	float3x3 fracRotation1 = rotationMatrix3(normalize(Rot1), Angle1);
	float3x3 fracRotation2 = rotationMatrix3(normalize(Rot2), Angle2);

	float r;
	
	// Iterate to compute the distance estimator.
	int n = 0;
	float d = 10900.0;
	while (n < Iterations) {
		z = mul(z, fracRotation1);
		
		if (z.x+z.y<0.0) z.xy = -z.yx;
		if (z.x+z.z<0.0) z.xz = -z.zx;
		if (z.x-z.y<0.0) z.xy = z.yx;
		if (z.x-z.z<0.0) z.xz = z.zx;
		
		z = z*Scale - Offset*(Scale-1.0);
		
		r = dot(z, z);
            if (n< ColorIterations)  orbitTrap = min(orbitTrap, abs(float4(z,r)));
		
		n++;


	d = min(d, trap(z, fracRotation2, O3, cylHeight, cylRad, val) * pow(Scale, -float(n)));
	}
return d;
	
}

///////////////////////

#endif // distance_functions_h
