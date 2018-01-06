Shader "Raymarcher/Octahedron" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0, 1)) = 0.0
    _Scale("Scale", Vector) = (1, 1, 1, 0)

    _Scene("Scene", Float) = 0

    // Octahedron 
    _OctahedroScale("OctahedroScale", Float) = 1.53332
    _Offset("Offset", Vector) = (0.48246, 0.09649, 0.15789)
    _Angle1("Angle1", Float) = -119.99900
    _Rot1("Rot1", Vector) = (1.00000, -0.50850, 0.44068)
    _Angle2("Angle2", Float) = 29.99880
    _Rot2("Rot2", Vector) = (0.50848, 1.00000, -0.62800)
    _val("val", Float) = 0
    _cylRad("cylRad", Float) = 0.10000
    _cylHeight("cylHeight", Float) = 2.00000
    _O3("O3", Vector) = (1, 1, 1)
    _Iterations("Iterations", Float) = 26
    _ColorIterations("ColorIterations", Float) = 2

}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "Assets/Raymarching/Foundation/foundation.cginc"

#define MAX_MARCH_OPASS 100
#define MAX_MARCH_QPASS 40
#define MAX_MARCH_HPASS 20
#define MAX_MARCH_APASS 5
#define MAX_MARCH_SINGLE_GBUFFER_PASS 500

int _Scene;
float3 _Position;
float4 _Rotation;
float3 _Scale;

// Octahedro
float _OctahedroScale;
float3 _Offset;
float _Angle1;
float3 _Rot1;
float _Angle2;
float3 _Rot2;
float _val;
float _cylRad;
float _cylHeight;
float3 _O3;
float _Iterations;
float _ColorIterations;

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
float octahedron(float3 z) {

	float4 orbitTrap = float4(0.0, 0.0, 0.0, 0.0);

	float3x3 fracRotation1 = rotationMatrix3(normalize(_Rot1), _Angle1);
	float3x3 fracRotation2 = rotationMatrix3(normalize(_Rot2), _Angle2);

	float r;
	
	// Iterate to compute the distance estimator.
	int n = 0;
	float d = 10900.0;
	while (n < _Iterations) {
		z = mul(z, fracRotation1);
		
		if (z.x+z.y<0.0) z.xy = -z.yx;
		if (z.x+z.z<0.0) z.xz = -z.zx;
		if (z.x-z.y<0.0) z.xy = z.yx;
		if (z.x-z.z<0.0) z.xz = z.zx;
		
		z = z*_OctahedroScale - _Offset*(_OctahedroScale-1.0);
		
		r = dot(z, z);
        //  if (n< _ColorIterations)  orbitTrap = min(orbitTrap, abs(float4(z,r)));
		
		n++;


	//d = min(d, trap(z, fracRotation2, _O3, _cylHeight, _cylRad, _val) * pow(_OctahedroScale, -float(n)));
    d = (length(z) ) * pow(_Scale, -float(n));
	}
return d;
	
}


//---------------------------------------------------------------------------------------------------------


float3 localize(float3 p)
{
    p = mul(unity_WorldToObject, float4(p, 1)).xyz * _Scale.xyz;
    return p;
}

float map(float3 p)
{
    p = localize(p);

    return octahedron(p);
}

float3 guess_normal(float3 p)
{
    const float d = 0.001;
    return normalize( float3(
        map(p+float3(  d,0.0,0.0))-map(p+float3( -d,0.0,0.0)),
        map(p+float3(0.0,  d,0.0))-map(p+float3(0.0, -d,0.0)),
        map(p+float3(0.0,0.0,  d))-map(p+float3(0.0,0.0, -d)) ));
}

struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 spos : TEXCOORD0;
};

vs_out vert(ia_out I)
{
    vs_out O;
    O.vertex = UnityObjectToClipPos(I.vertex);
    O.spos = O.vertex;
    return O;
}

void raymarching(float2 pos, const int num_steps, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
{
    float3 cam_pos      = GetCameraPosition();
    float3 cam_forward  = GetCameraForward();
    float3 cam_up       = GetCameraUp();
    float3 cam_right    = GetCameraRight();
    float  cam_focal_len= GetCameraFocalLength();

    float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward*cam_focal_len);
    float max_distance = _ProjectionParams.z - _ProjectionParams.y;
    o_raypos = cam_pos + ray_dir * o_total_distance;

    o_num_steps = 0.0;
    o_last_distance = 0.0;
    for(int i=0; i<num_steps; ++i) {
        o_last_distance = map(o_raypos);
        o_total_distance += o_last_distance;
        o_raypos += ray_dir * o_last_distance;
        o_num_steps += 1.0;
        if(o_last_distance < 0.001 || o_total_distance > max_distance) { break; }
    }
    o_total_distance = min(o_total_distance, max_distance);
}

struct gbuffer_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
    float depth             : SV_Depth;
};

gbuffer_out frag_gbuffer(vs_out I)
{
    I.spos.xy /= I.spos.w;
#if UNITY_UV_STARTS_AT_TOP
    I.spos.y *= -1.0;
#endif
    float time = _Time.y;
    float2 coord = I.spos.xy;
    coord.x *= GetAspectRatio();

    float num_steps = 1.0;
    float last_distance = 0.0;
    float total_distance = _ProjectionParams.y;
    float3 ray_pos;
    float3 normal;

    raymarching(coord, MAX_MARCH_SINGLE_GBUFFER_PASS, total_distance, num_steps, last_distance, ray_pos);
    normal = guess_normal(ray_pos);

    float glow = 0.0;
    glow += max(1.0-abs(dot(-GetCameraForward(), normal)) - 0.4, 0.0) * 1.0;
    float3 emission = float3(0.7, 0.7, 1.0)*glow*0.6;

    gbuffer_out O;
    O.diffuse = float4(0.75, 0.75, 0.80, 1.0);
    O.spec_smoothness = float4(0.2, 0.2, 0.2, _Glossiness);
    O.normal = float4(normal*0.5+0.5, 1.0);
    O.emission = float4(emission, 1.0);
#ifndef UNITY_HDR_ON
    O.emission = exp2(-O.emission);
#endif
    O.depth = ComputeDepth(mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0)));
    return O;
}

ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }
    Cull Off

    Pass {
        Tags { "LightMode" = "Deferred" }
        Stencil {
            Comp Always
            Pass Replace
            Ref 128
        }
CGPROGRAM
#pragma enable_d3d11_debug_symbols
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag_gbuffer
#pragma multi_compile ___ UNITY_HDR_ON
ENDCG
    } 
}
Fallback Off
}
