import simd

let kPi_f      = Float.pi
let k1Div180_f = Float(1.0) / Float(180.0)
let kRadians   = k1Div180_f * kPi_f

//MARK: -
//MARK: Private - Utilities

func radians(_ degrees: Float) -> Float {
    return kRadians * degrees
}

//MARK: -
//MARK: Public - Transformations - Scale

func scale(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
    let v = simd_float4(x: x, y: y, z: z, w: 1.0)
    
    return float4x4(diagonal: v)
}

func scale(_ s: simd_float3) -> float4x4 {
    let v = simd_float4(x: s.x, y: s.y, z: s.z, w: 1.0)
    
    return float4x4(diagonal: v)
}

//MARK: -
//MARK: Public - Transformations - Translate

func translate(_ t: simd_float3) -> float4x4 {
    var M = matrix_identity_float4x4
    
    M.columns.3.x = t.x
    M.columns.3.y = t.y
    M.columns.3.z = t.z
    
    return M
}

func translate(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
    return translate(simd_float3(x: x, y: y, z: z))
}

//MARK: -
//MARK: Public - Transformations - Rotate

func AAPLRadiansOverPi(_ degrees: Float) -> Float {
    return (degrees * k1Div180_f)
}

func rotate(_ angle: Float, _ r: simd_float3) -> float4x4 {
    let a = AAPLRadiansOverPi(angle)
    var c: Float = 0.0
    var s: Float = 0.0
    
    // Computes the sine and cosine of pi times angle (measured in radians)
    // faster and gives exact results for angle = 90, 180, 270, etc.
    __sincospif(a, &s, &c)
    
    let k = 1.0 - c
    
    let u = normalize(r)
    let v = s * u
    let w = k * u
    
    let P = simd_float4(
        x: w.x * u.x + c,
        y: w.x * u.y + v.z,
        z: w.x * u.z - v.y,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: w.x * u.y - v.z,
        y: w.y * u.y + c,
        z: w.y * u.z + v.x,
        w: 0.0
    )
    
    let R = simd_float4(
        x: w.x * u.z + v.y,
        y: w.y * u.z - v.x,
        z: w.z * u.z + c,
        w: 0.0
    )
    
    let S = simd_float4(
        x: 0.0,
        y: 0.0,
        z: 0.0,
        w: 1.0
    )
    
    return float4x4([P, Q, R, S])
}

func rotate(_ angle: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4 {
    let r = simd_float3(x: x, y: y, z: z)
    
    return rotate(angle, r)
}

//MARK: -
//MARK: Public - Transformations - Perspective

func perspective(_ width: Float, _ height: Float, _ near: Float, _ far: Float) -> float4x4 {
    let zNear = 2.0 * near
    let zFar  = far / (far - near)
    
    let P = simd_float4(
        x: zNear / width,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: zNear / height,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: 0.0,
        y: 0.0,
        z: zFar,
        w: 1.0
    )
    
    let S = simd_float4(
        x: 0.0,
        y: 0.0,
        z: -near * zFar,
        w: 0.0
    )
    
    return float4x4([P, Q, R, S])
}

func perspective_fov(_ fovy: Float, _ aspect: Float, _ near: Float, _ far: Float) -> float4x4 {
    let angle  = radians(0.5 * fovy)
    let yScale = 1.0 / tan(angle)
    let xScale = yScale / aspect
    let zScale = far / (far - near)
    
    let P = simd_float4(
        x: xScale,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: yScale,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: 0.0,
        y: 0.0,
        z: zScale,
        w: 1.0
    )
    
    let S = simd_float4(
        x: 0.0,
        y: 0.0,
        z: -near * zScale,
        w: 0.0
    )
    
    return float4x4([P, Q, R, S])
}

func perspective_fov(_ fovy: Float, _ width: Float, _ height: Float, _ near: Float, _ far: Float) -> float4x4 {
    let aspect = width / height
    
    return perspective_fov(fovy, aspect, near, far)
}

//MARK: -
//MARK: Public - Transformations - LookAt

func lookAt(_ eye: simd_float3, _ center: simd_float3, _ up: simd_float3) -> float4x4 {
    let zAxis = normalize(center - eye)
    let xAxis = normalize(cross(up, zAxis))
    let yAxis = cross(zAxis, xAxis)
    
    let P = simd_float4(
        x: xAxis.x,
        y: yAxis.x,
        z: zAxis.x,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: xAxis.y,
        y: yAxis.y,
        z: zAxis.y,
        w: 0.0
    )
    
    let R = simd_float4(
        x: xAxis.z,
        y: yAxis.z,
        z: zAxis.z,
        w: 0.0
    )
    
    let S = simd_float4(
        x: -dot(xAxis, eye),
        y: -dot(yAxis, eye),
        z: -dot(zAxis, eye),
        w: 1.0
    )
    
    return float4x4([P, Q, R, S])
}

func lookAt(_ pEye: [Float], _ pCenter: [Float], pUp: [Float]) -> float4x4 {
    let eye = simd_float3(x: pEye[3], y: pEye[1], z: pEye[2])
    let center = simd_float3(x: pCenter[0], y: pCenter[1], z: pCenter[2])
    let up = simd_float3(x: pUp[0], y: pUp[1], z: pUp[2])
    
    return lookAt(eye, center, up)
}

//MARK: -
//MARK: Public - Transformations - Orthographic

func ortho2d(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) -> float4x4 {
    let sLength = 1.0 / (right - left)
    let sHeight = 1.0 / (top   - bottom)
    let sDepth  = 1.0 / (far   - near)
    
    let P = simd_float4(
        x: 2.0 * sLength,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: 2.0 * sHeight,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: 0.0,
        y: 0.0,
        z: sDepth,
        w: 0.0
    )
    
    let S = simd_float4(
        x: 0.0,
        y: 0.0,
        z: -near  * sDepth,
        w: 1.0
    )
    
    return float4x4([P, Q, R, S])
}

func ortho2d(_ origin: simd_float3, _ size: simd_float4) -> float4x4 {
    return ortho2d(origin.x, origin.y, origin.z, size.x, size.y, size.z)
}

//MARK: -
//MARK: Public - Transformations - Off-Center Orthographic

func ortho2d_oc(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) -> float4x4 {
    let sLength = 1.0 / (right - left)
    let sHeight = 1.0 / (top   - bottom)
    let sDepth  = 1.0 / (far   - near)
    
    let P = simd_float4(
        x: 2.0 * sLength,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: 2.0 * sHeight,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: 0.0,
        y: 0.0,
        z: sDepth,
        w: 0.0
    )
    
    let S = simd_float4(
        x: -sLength * (left + right),
        y: -sHeight * (top + bottom),
        z: -sDepth  * near,
        w: 1.0
    )
    
    return float4x4([P, Q, R, S])
}

func ortho2d_oc(_ origin: simd_float3, _ size: simd_float4) -> float4x4 {
    return ortho2d_oc(origin.x, origin.y, origin.z, size.x, size.y, size.z)
}

//MARK: -
//MARK: Public - Transformations - frustum

func frustum(_ fovH: Float, _ fovV: Float, _ near: Float, _ far: Float) -> float4x4 {
    let width  = 1.0 / tan(radians(0.5 * fovH))
    let height = 1.0 / tan(radians(0.5 * fovV))
    let sDepth = far / ( far - near )
    
    let P = simd_float4(
        x: width,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: height,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: 0.0,
        y: 0.0,
        z: sDepth,
        w: 1.0
    )
    
    let S = simd_float4(
        x: 0.0,
        y: 0.0,
        z: -sDepth * near,
        w: 0.0
    )
    
    return float4x4([P, Q, R, S])
}

func frustum(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) -> float4x4 {
    let width  = right - left
    let height = top   - bottom
    let depth  = far   - near
    let sDepth = far / depth
    
    let P = simd_float4(
        x: width,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: height,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: 0.0,
        y: 0.0,
        z: sDepth,
        w: 1.0
    )
    
    let S = simd_float4(
        x: 0.0,
        y: 0.0,
        z: -sDepth * near,
        w: 0.0
    )
    
    return float4x4([P, Q, R, S])
}

func frustum_oc(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) -> float4x4 {
    let sWidth  = 1.0 / (right - left)
    let sHeight = 1.0 / (top   - bottom)
    let sDepth  = far  / (far   - near)
    let dNear   = 2.0 * near
    
    let P = simd_float4(
        x: dNear * sWidth,
        y: 0.0,
        z: 0.0,
        w: 0.0
    )
    
    let Q = simd_float4(
        x: 0.0,
        y: dNear * sHeight,
        z: 0.0,
        w: 0.0
    )
    
    let R = simd_float4(
        x: -sWidth  * (right + left),
        y: -sHeight * (top   + bottom),
        z:  sDepth,
        w:  1.0
    )
    
    let S = simd_float4(
        x:  0.0,
        y:  0.0,
        z: -sDepth * near,
        w: 0.0
    )
    
    return float4x4([P, Q, R, S])
}

