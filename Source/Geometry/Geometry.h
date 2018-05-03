#pragma once

struct Counter {
    int count;
};

struct GeometryPoint {
    vector_float3 pos;
    vector_float2 angle;
    float stiffness;
};

struct GeometryControl {
    int nSides;
    int nLevels;
    int pCount;
    
    vector_float2 deltaAngle;
    vector_float2 desiredAngle;
    float radius, deltaRadius;
    float dist, deltaDist;
};

