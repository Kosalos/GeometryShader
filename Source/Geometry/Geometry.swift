/*
 
 Metal does not offer a geometry shader, so this class supplies one.
 Given an array of seed points, this class creates the vertices and indices required to render a
 multi-segmented tower based at each point.
 
 Class Geometry offers three functions:
 update() = copy the GUI control data into the control buffer and call calc..
 calcGeometry() = call the geometry shader to produce the vertices & indices
 render() = draw the created geometry
 
 GeometryPoint is provided for each seed point.
 
 struct GeometryPoint {
 vector_float3 pos;     // 3D coordinate of the base of the tower
 vector_float2 angle; // initial direction as and X and Y rotation
 float stiffness;     // controls how quickly the tower responds to angle changes
 };
 
 GeometryControl provides global data that all towers share.
 
 struct GeometryControl {
 int nSides;            // number of sides of a tower
 int nLevels;        // number of levels in a tower
 int pCount;            // number of seed points provided
 
 vector_float2 deltaAngle;    // how much the tower rotates at each level
 vector_float2 desiredAngle; // the angle all towers should be moving to (stiffness affects response time)
 float radius;        // the width of the bottom of the tower
 float deltaRadius;        // how the width is altered at each level
 float dist;            // the vertical distance between tower levels
 float deltaDist;        // amount the distance is altered at each level
 };
 
 The Geometry shader uses this data to generate the tower vertices and indices:
 
 kernel void calcGeometryShader
 (
 device TVertex *vertices       [[ buffer(0) ]], // where to store the vertices
 device ushort *indices         [[ buffer(1) ]], // where to store the indices
 device atomic_uint &vcounter   [[ buffer(2) ]], // where to store the number of vertices created
 device atomic_uint &icounter   [[ buffer(3) ]], // where to store the number of indices created
 device GeometryPoint *pnt      [[ buffer(4) ]], // the seed data for each tower
 constant GeometryControl &ctrl [[ buffer(5) ]], // the global control data shared by all towers
 uint p [[thread_position_in_grid]])
 {
 
 Note: this shader also alters the angle field of each seed point (that's why *pnt is not constant)
 
 /////////////////////////
 
 Using the GUI:
 All the control widgets work the same way:
 Press and hold to either side of center to affect the parameters in the specified direction and speed.
 
 Pinch/drag the screen to control position and rotation.

*/

import UIKit
import Metal
import simd

let MAX_TRI:Int = 3900000  //  = 250000000 / MemoryLayout<TVertex>.stride

var control = Control()

class Geometry {
    let commandQueue: MTLCommandQueue
    var vCountBuffer:MTLBuffer! = nil
    var iCountBuffer:MTLBuffer! = nil

    var iCount = Int()
    var tCount = Int()
    var geoCtl:GeometryControl! = nil
    var geoPnt:[GeometryPoint] = []
    
    var indice = Array(repeating:UInt16(), count:MAX_TRI)
    var vertex = Array(repeating:TVertex(), count:MAX_TRI)
    var cBuffer: MTLBuffer?
    var pBuffer: MTLBuffer?
    var iBuffer: MTLBuffer?
    var vBuffer: MTLBuffer?

    init(_ ctrl: inout GeometryControl, _ pnt: inout [GeometryPoint]) {
        geoCtl = ctrl
        geoPnt = pnt
        
        if pnt.count <= 0 || pnt.count != ctrl.pCount { print("you must provide an array of GeometryPoints"); exit(0) }
        ctrl.pCount = Int32(pnt.count)
        
        self.commandQueue = gDevice.makeCommandQueue()!
        vCountBuffer = gDevice?.makeBuffer(length:MemoryLayout<Counter>.stride, options:.storageModeShared)
        iCountBuffer = gDevice?.makeBuffer(length:MemoryLayout<Counter>.stride, options:.storageModeShared)
        cBuffer = gDevice?.makeBuffer(length:MemoryLayout<GeometryControl>.stride, options:.storageModeShared)
        pBuffer = gDevice?.makeBuffer(length:MemoryLayout<GeometryPoint>.stride * pnt.count, options:.storageModeShared)

        iBuffer = gDevice?.makeBuffer(bytes:indice, length: MAX_TRI * MemoryLayout<UInt16>.stride, options: MTLResourceOptions())!
        vBuffer = gDevice?.makeBuffer(bytes:vertex, length: MAX_TRI * MemoryLayout<TVertex>.stride, options: MTLResourceOptions())!
        update(&ctrl,&pnt)
    }
    
    //MARK: -
    
    func update(_ ctrl: inout GeometryControl, _ pnt: inout [GeometryPoint]) {
        geoCtl = ctrl
        calcGeometry()
    }
    
    func buildPipeline(_ shaderFunction:String) -> MTLComputePipelineState {
        var result:MTLComputePipelineState!
        
        do {
            let defaultLibrary = gDevice?.makeDefaultLibrary()
            let prg = defaultLibrary?.makeFunction(name:shaderFunction)
            result = try gDevice?.makeComputePipelineState(function: prg!)
        } catch { fatalError("Failed to setup " + shaderFunction) }
        
        return result
    }
    
    //MARK: -

    var pipe:MTLComputePipelineState!
    var numThreadgroups2 = MTLSize()
    var threadsPerGroup2 = MTLSize()
    
    func calcGeometry() {
        let pCount = Int(geoCtl.pCount)
        if pCount <= 0 { print("geoCtl.pCount == 0 during update()"); exit(0) }
        
        if pipe == nil {
            pipe = buildPipeline("calcGeometryShader")
            let threadExecutionWidth = pipe.threadExecutionWidth
            let ntg = Int(ceil(Float(pCount)/Float(threadExecutionWidth)))
            threadsPerGroup2 = MTLSize(width:threadExecutionWidth, height:1, depth:1)
            numThreadgroups2 = MTLSize(width:ntg, height:1, depth:1)
        }
        
        cBuffer?.contents().copyMemory(from:&geoCtl, byteCount:MemoryLayout<GeometryControl>.stride)
        pBuffer?.contents().copyMemory(from:geoPnt, byteCount:MemoryLayout<GeometryPoint>.stride * pCount)

        memset(vCountBuffer.contents(),0,MemoryLayout<Counter>.stride)
        memset(iCountBuffer.contents(),0,MemoryLayout<Counter>.stride)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        commandEncoder.setComputePipelineState(pipe)
        commandEncoder.setBuffer(vBuffer,       offset:0, index:0)
        commandEncoder.setBuffer(iBuffer,       offset:0, index:1)
        commandEncoder.setBuffer(vCountBuffer,  offset:0, index:2)
        commandEncoder.setBuffer(iCountBuffer,  offset:0, index:3)
        commandEncoder.setBuffer(pBuffer,       offset:0, index:4)
        commandEncoder.setBuffer(cBuffer,       offset:0, index:5)
        commandEncoder.dispatchThreadgroups(numThreadgroups2, threadsPerThreadgroup:threadsPerGroup2)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        var result = Counter()
        memcpy(&result,vCountBuffer.contents(),MemoryLayout<Counter>.stride);  tCount = Int(result.count)
        memcpy(&result,iCountBuffer.contents(),MemoryLayout<Counter>.stride);  iCount = Int(result.count)

        memcpy(&geoPnt, pBuffer?.contents(),MemoryLayout<GeometryPoint>.stride * pCount)
    }

    //MARK: -

    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        if vBuffer == nil { return }
        
        if tCount > 0 {
            renderEncoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle,  indexCount:iCount, indexType: MTLIndexType.uint16, indexBuffer: iBuffer!, indexBufferOffset:0)
        }
    }
}

