#include <metal_stdlib>
#include <simd/simd.h>
#import "Shader.h"

using namespace metal;

struct Transfer {
    float4 position [[position]];
    float pointsize [[point_size]];
    float2 txt;
    float4 lighting;
    int style;
};

vertex Transfer texturedVertexShader
(
 device TVertex* vData [[ buffer(0) ]],
 constant Control& control [[ buffer(1) ]],
 unsigned int vid [[ vertex_id ]])
{
    Transfer out;
    TVertex v = vData[vid];
    
    out.txt = v.txt;
    out.pointsize = 10.0;
    out.position = control.mvp * float4(v.pos, 1.0);
    out.style = v.style;
    
    float intensity = saturate(dot(vData[vid].nrm.rgb, control.light));
    out.lighting = 0.1 + float4(intensity,intensity,intensity,1);
    
    return out;
}

fragment float4 texturedFragmentShader
(
 Transfer data [[stage_in]],
 texture2d<float> tex2D [[texture(0)]],
 sampler sampler2D [[sampler(0)]])
{
    if(data.style == 0) return float4(1,1,1,1);
    
    return tex2D.sample(sampler2D, data.txt.xy) * data.lighting;
}

