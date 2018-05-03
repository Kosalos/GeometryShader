import UIKit

class Background: UIView {
    override func draw(_ rect: CGRect) {
        UIColor(red:0.135, green:0.13, blue:0.13, alpha: 1).setFill()
        UIBezierPath(rect:rect).fill()
    }
}
