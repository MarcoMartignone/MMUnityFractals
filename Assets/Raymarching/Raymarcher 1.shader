Shader "Raymarcher/RayMarcher_new" {
Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _Glossiness ("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0, 1)) = 0.0
    _Position("Position", Vector) = (0, 0, 0, 0)
    _Rotation("Rotation", Vector) = (0, 1, 0, 0)
    _Scale("Scale", Vector) = (1, 1, 1, 0)

    _Scene("Scene", Float) = 0

    // Julia 
    _Threshold("Threshold", Float) = 10

}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "distance_functions.cginc"
#include "fractals_math.cginc"

#define MAX_MARCH_OPASS 100
#define MAX_MARCH_QPASS 40
#define MAX_MARCH_HPASS 20
#define MAX_MARCH_APASS 5
#define MAX_MARCH_SINGLE_GBUFFER_PASS 100

int _Scene;
int _Threshold;
float3 _Position;
float4 _Rotation;
float3 _Scale;

float3 localize(float3 p)
{
    p = mul(unity_WorldToObject, float4(p, 1)).xyz * _Scale.xyz;
    return p;
}

float map(float3 p)
{
    p = localize(p);

   //return Julia(p, _Threshold);
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

struct distance_out
{
    float4 distance : SV_Target0;
};

struct opass_out
{
    float distance : SV_Target0;
    half diff : SV_Target1;
};

#define DIFF_THRESHILD 0.0001

opass_out frag_opass(vs_out I)
{
#if UNITY_UV_STARTS_AT_TOP
    I.spos.y *= -1.0;
#endif
    float2 tpos = I.spos.xy*0.5+0.5;
    float2 pos = I.spos.xy;
    pos.x *= _ScreenParams.x / _ScreenParams.y;

    float num_steps, last_distance, total_distance = _ProjectionParams.y;
    float3 ray_pos;
    raymarching(pos, MAX_MARCH_OPASS, total_distance, num_steps, last_distance, ray_pos);

    opass_out O;
    O.distance = total_distance;
    O.diff = total_distance - tex2D(g_depth_prev, tpos).x;
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
    
    Pass {
        Name "ODepth"
        ZWrite Off
        ZTest Always
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_opass
#pragma multi_compile ___ ENABLE_SCREENSPACE
ENDCG
    } 
}
Fallback Off
}
