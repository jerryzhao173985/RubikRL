import SceneKit

enum CubeMove: String, CaseIterable {
    case U, UPrime, D, DPrime, L, LPrime, R, RPrime, F, FPrime, B, BPrime

    // Only use these moves for RL (if desired)
    static var availableMoves2x2: [CubeMove] {
        return [.U, .D, .L, .R, .F, .B]
    }
    
    // Computed property for the rotation axis.
    var axis: SCNVector3 {
        switch self {
        case .U, .UPrime, .D, .DPrime:
            return SCNVector3(0, 1, 0)
        case .L, .LPrime, .R, .RPrime:
            return SCNVector3(1, 0, 0)
        case .F, .FPrime, .B, .BPrime:
            return SCNVector3(0, 0, 1)
        }
    }
    
    // Computed property for the rotation angle.
    var angle: Double {
        switch self {
        case .U, .D, .L, .R, .F, .B:
            return Double.pi / 2
        case .UPrime, .DPrime, .LPrime, .RPrime, .FPrime, .BPrime:
            return -Double.pi / 2
        }
    }
    
    // Computed property that indicates which face layer is affected.
    var affectedLayer: (axis: String, value: Double) {
        switch self {
        case .U, .UPrime:
            return ("y", 0.5)
        case .D, .DPrime:
            return ("y", -0.5)
        case .L, .LPrime:
            return ("x", -0.5)
        case .R, .RPrime:
            return ("x", 0.5)
        case .F, .FPrime:
            return ("z", 0.5)
        case .B, .BPrime:
            return ("z", -0.5)
        }
    }
    
    // Rotate a coordinate by the move.
    func rotateCoordinate(_ coord: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
        switch self {
        case .U:      return (x: coord.z, y: coord.y, z: -coord.x)
        case .UPrime: return (x: -coord.z, y: coord.y, z: coord.x)
        case .D:      return (x: -coord.z, y: coord.y, z: coord.x)
        case .DPrime: return (x: coord.z, y: coord.y, z: -coord.x)
        case .L:      return (x: coord.x, y: coord.z, z: -coord.y)
        case .LPrime: return (x: coord.x, y: -coord.z, z: coord.y)
        case .R:      return (x: coord.x, y: -coord.z, z: coord.y)
        case .RPrime: return (x: coord.x, y: coord.z, z: -coord.y)
        case .F:      return (x: coord.y, y: -coord.x, z: coord.z)
        case .FPrime: return (x: -coord.y, y: coord.x, z: coord.z)
        case .B:      return (x: -coord.y, y: coord.x, z: coord.z)
        case .BPrime: return (x: coord.y, y: -coord.x, z: coord.z)
        }
    }
    
    // Computed property for the rotation as a quaternion.
    var quaternion: SCNQuaternion {
        let halfAngle = angle / 2
        let sinHalf = sin(halfAngle)
        let cosHalf = cos(halfAngle)
        let a = axis
        return SCNQuaternion(a.x * Float(sinHalf), a.y * Float(sinHalf), a.z * Float(sinHalf), Float(cosHalf))
    }
    
    // Inverse move: map each move to its opposite.
    var inverse: CubeMove {
        switch self {
        case .U: return .UPrime
        case .UPrime: return .U
        case .D: return .DPrime
        case .DPrime: return .D
        case .L: return .LPrime
        case .LPrime: return .L
        case .R: return .RPrime
        case .RPrime: return .R
        case .F: return .FPrime
        case .FPrime: return .F
        case .B: return .BPrime
        case .BPrime: return .B
        }
    }
}
