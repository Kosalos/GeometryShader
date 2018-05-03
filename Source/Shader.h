#pragma once

#include <simd/simd.h>
#include <simd/base.h>
#import "Geometry/Geometry.h"

#define TMAX 3900000

struct TVertex {
    vector_float3 pos;
    vector_float3 nrm;
    vector_float2 txt;
    
    float gAngle;
    float gHeight;
    float gTexture;
    char style;
};

struct Control {
    matrix_float4x4 mvp;
    vector_float3 light;
};

