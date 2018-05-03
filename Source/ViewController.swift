import UIKit
import MetalKit

var vc:ViewController! = nil
let test = Test()

var directionY:Float = -3
var directionX:Float = 1.29
var length:Float = 0.3
var thickness:Float = -0.3
var angle1:Float = 0
var angle2:Float = 0.02

class ViewController: UIViewController {
    var timer = Timer()
    lazy var device: MTLDevice! = MTLCreateSystemDefaultDevice()
    var renderer: Renderer!
    
    @IBOutlet var metalView: MTKView!
    @IBOutlet var widget1: DeltaView!
    @IBOutlet var widget2: DeltaView!
    @IBOutlet var widget3: DeltaView!

    var dList:[DeltaView]! = nil
    
    override func viewDidLoad() {
        vc = self
        super.viewDidLoad()
        
        metalView.device = device
        metalView.backgroundColor = UIColor.clear
        
        guard let newRenderer = Renderer(metalKitView: metalView, 0) else { print("Renderer cannot be initialized"); exit(0) }
        renderer = newRenderer
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        metalView.delegate = renderer
        
        widget1.initializeFloat1(&directionY, -3,+3, 5, "Direction");  widget1.initializeFloat2(&directionX)
        widget2.initializeFloat1(&length, -0.3,+0.3, 0.5, "Len,Thk");  widget2.initializeFloat2(&thickness)
        widget3.initializeFloat1(&angle1, 0,1, 0.1, "Curl");  widget3.initializeFloat2(&angle2)

        dList = [ widget1,widget2,widget3 ]

        timer = Timer.scheduledTimer(timeInterval: 1.0/20.0, target:self, selector: #selector(timerHandler), userInfo: nil, repeats:true)
    }
    
    override var prefersStatusBarHidden: Bool { return true }

    //MARK: -
    
    @objc func timerHandler() {
        var needUpdate:Bool = true
        for d in dList { if d.update() { needUpdate = true }}
        if needUpdate { test.update() }
        
        rotate(paceRotate.x,paceRotate.y)
    }
    
    //MARK: -
    
    var rotateCenter = CGPoint()
    var paceRotate = CGPoint()

    func rotate(_ x:CGFloat, _ y:CGFloat) {
        if rotateCenter.x == 0 {
            let hk = metalView.bounds
            rotateCenter.x = hk.size.width/2
            rotateCenter.y = hk.size.height/2
        }
        
        arcBall.mouseDown(CGPoint(x: rotateCenter.x, y: rotateCenter.y))
        arcBall.mouseMove(CGPoint(x: rotateCenter.x - x, y: rotateCenter.y - y))
    }
    
    func parseTranslation(_ pt:CGPoint) {
        let scale:Float = 0.05
        translation.x = Float(pt.x) * scale
        translation.y = -Float(pt.y) * scale
    }
    
    func parseRotation(_ pt:CGPoint) {
        let scale:CGFloat = 0.1
        paceRotate.x = pt.x * scale
        paceRotate.y = pt.y * scale
    }
    
    var numberPanTouches:Int = 0
    
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        let pt = sender.translation(in: self.view)
        let count = sender.numberOfTouches
        if count == 0 { numberPanTouches = 0 }  else if count > numberPanTouches { numberPanTouches = count }
        
        switch sender.numberOfTouches {
        case 1 : if numberPanTouches < 2 { parseRotation(pt) } // prevent rotation after releasing translation
        case 2 : parseTranslation(pt)
        default : break
        }
    }
    
    @IBAction func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        let min:Float = 1
        let max:Float = 1000
        translation.z *= Float(1 + (1 - sender.scale) / 10 )
        if translation.z < min { translation.z = min }
        if translation.z > max { translation.z = max }
    }
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        paceRotate.x = 0
        paceRotate.y = 0
    }

    
}
