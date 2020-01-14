import UIKit
import MetalKit

let NUMPOINT:Int = 500

var ctrl = GeometryControl()
var pnt = Array(repeating:GeometryPoint(), count:NUMPOINT)

class Test {
    var geo:Geometry! = nil

    init() {
        let K:Float = NUMPOINT > 1 ? 300 : 0
        
        ctrl.nSides = 8
        ctrl.nLevels =  8
        ctrl.radius = 8
        ctrl.dist = 3
        ctrl.pCount = Int32(NUMPOINT)

        for i in 0 ..< NUMPOINT {
            if pnt[i].pos.x == 0 {
                pnt[i].pos.x = fRandom(-K,K)
                pnt[i].pos.y = -8
                pnt[i].pos.z = fRandom(-K,K)
            }
            
            pnt[i].angle = simd_float2(0,0)
            pnt[i].stiffness = fRandom(0.02,1)
        }
        
        geo = Geometry(&ctrl,&pnt)
    }
    
    func update() {
        ctrl.deltaRadius = 1 + thickness
        ctrl.deltaDist = 1 + length
        ctrl.deltaAngle.x = angle2
        ctrl.deltaAngle.y = angle1
        ctrl.desiredAngle = simd_float2(directionX,directionY)

        geo.update(&ctrl,&pnt)
    }
    
    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        geo.render(renderEncoder)
    }
}

func fRandom(_ vmin:Float, _ vmax:Float) -> Float { return vmin + (vmax - vmin) * Float( arc4random() & 1023) / Float(1024) }

