#include <metal_stdlib>
#include <simd/simd.h>
#include "Source/Shader.h"

using namespace metal;

constant float pi2 = 6.283185;

float3 rotatePos(float3 old, float2 angle) {
    float3 pos = old;
    
    float qt = pos.x;  // X rotation
    pos.x = pos.x * cos(angle.x) - pos.y * sin(angle.x);
    pos.y = qt * sin(angle.x) + pos.y * cos(angle.x);
    
    qt = pos.x;      // Y rotation
    pos.x = pos.x * cos(angle.y) - pos.z * sin(angle.y);
    pos.z = qt * sin(angle.y) + pos.z * cos(angle.y);
    
    return pos;
}

kernel void calcGeometryShader
(
 device TVertex *vertices       [[ buffer(0) ]],
 device ushort *indices         [[ buffer(1) ]],
 device atomic_uint &vcounter   [[ buffer(2) ]],
 device atomic_uint &icounter   [[ buffer(3) ]],
 device GeometryPoint *pnt      [[ buffer(4) ]],
 constant GeometryControl &ctrl [[ buffer(5) ]],
 uint p [[thread_position_in_grid]])
{
    if(p >= uint(ctrl.pCount)) return;

    // vertices -----------------------------------
    int nVertices = ctrl.nSides * (ctrl.nLevels+1);
    
    uint vBaseIndex = atomic_fetch_add_explicit(&vcounter, 0, memory_order_relaxed);
    if(vBaseIndex >= uint(TMAX - nVertices - 10)) return;
    vBaseIndex = atomic_fetch_add_explicit(&vcounter, nVertices, memory_order_relaxed);
    
    int vIndex = vBaseIndex;
    
    pnt[p].angle += (ctrl.desiredAngle - pnt[p].angle) * pnt[p].stiffness;
    float2 currentAngle = pnt[p].angle;

    float3 previousPos = pnt[p].pos;
    float radius = ctrl.radius;
    float dist = ctrl.dist;
    float flevels = float(ctrl.nLevels);
    float fsides = float(ctrl.nSides);
    float angleHop = pi2 / fsides;
    float angle,txtY;
    
    for(int levelIndex = 0; levelIndex <= ctrl.nLevels; ++levelIndex) {
        txtY = float(levelIndex + p) / flevels;
        angle = 0;
        
        for(int sideIndex = 0; sideIndex < ctrl.nSides; ++sideIndex) {
            device TVertex &tv = vertices[vIndex++];
            tv.pos = float3(0,cos(angle) * radius,sin(angle) * radius); // un-rotated resting position
            angle += angleHop;
            
            tv.pos = rotatePos(tv.pos,currentAngle); // rotated by current accumulated angle
            tv.pos += previousPos; // offset by parent's final position

            tv.txt.x = float(sideIndex) / (fsides - 1);
            tv.txt.y = txtY;
            
            tv.nrm = normalize(tv.pos);
            tv.style = 1;
        }

        previousPos += rotatePos(float3(dist,0,0), currentAngle);

        currentAngle += ctrl.deltaAngle;
        radius *= ctrl.deltaRadius;
        dist *= ctrl.deltaDist;
    }

    // Indices --------------------------------------
    uint index = atomic_fetch_add_explicit(&icounter, 0, memory_order_relaxed);
    if(index >= TMAX - 30) return;
    index = atomic_fetch_add_explicit(&icounter,ctrl.nLevels * ctrl.nSides * 6, memory_order_relaxed);
    
    for(int n=0;n < ctrl.nLevels;++n) {
        int base = vBaseIndex + n * ctrl.nSides;
        
        for(int i = 0; i < ctrl.nSides; ++i) {
            int i2 = i+1;
            if(i2 == ctrl.nSides) i2 = 0;
            int i3 = i + ctrl.nSides;
            int i4 = i2 + ctrl.nSides;
            indices[index++] = base + i;
            indices[index++] = base + i2;
            indices[index++] = base + i3;
            
            indices[index++] = base + i2;
            indices[index++] = base + i4;
            indices[index++] = base + i3;
        }
    }
}
