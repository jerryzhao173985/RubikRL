import SceneKit

enum CubeMove: String, CaseIterable {
    case U, UPrime, D, DPrime, L, LPrime, R, RPrime, F, FPrime, B, BPrime

    static var availableMoves2x2: [CubeMove] {
        return [.U, .D, .L, .R, .F, .B]
    }
    
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
    
    var angle: Double {
        switch self {
        case .U, .D, .L, .R, .F, .B:
            return Double.pi / 2
        case .UPrime, .DPrime, .LPrime, .RPrime, .FPrime, .BPrime:
            return -Double.pi / 2
        }
    }
    
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
    
    var quaternion: SCNQuaternion {
        let halfAngle = angle / 2
        let sinHalf = sin(halfAngle)
        let cosHalf = cos(halfAngle)
        let a = axis
        return SCNQuaternion(a.x * Float(sinHalf), a.y * Float(sinHalf), a.z * Float(sinHalf), Float(cosHalf))
    }
    
    // Add the inverse computed property.
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
    
    /// Permutation mapping on the 8 corners (indices 0...7).
    var cornerPermutation: [Int] {
        switch self {
        case .U:
            var perm = Array(0..<8)
            perm[0] = 1; perm[1] = 5; perm[5] = 4; perm[4] = 0
            return perm
        case .D:
            var perm = Array(0..<8)
            perm[2] = 3; perm[3] = 7; perm[7] = 6; perm[6] = 2
            return perm
        case .L:
            var perm = Array(0..<8)
            perm[0] = 2; perm[2] = 6; perm[6] = 4; perm[4] = 0
            return perm
        case .R:
            var perm = Array(0..<8)
            perm[1] = 3; perm[3] = 7; perm[7] = 5; perm[5] = 1
            return perm
        case .F:
            var perm = Array(0..<8)
            perm[0] = 1; perm[1] = 3; perm[3] = 2; perm[2] = 0
            return perm
        case .B:
            var perm = Array(0..<8)
            perm[4] = 5; perm[5] = 7; perm[7] = 6; perm[6] = 4
            return perm
        default:
            return self.inverse.cornerPermutation
        }
    }
    
    /// For corner orientation delta we return an array of 8 ints (only affected corners will have nonzero values).
    /// For simplicity, let’s assume U and D do not change orientation.
    var cornerOrientationDelta: [Int] {
        switch self {
        case .U, .D:
            return Array(repeating: 0, count: 8)
        case .F:
            var delta = Array(repeating: 0, count: 8)
            // For F move, affect corners 0,1,2,3.
            delta[0] = 1; delta[1] = 2; delta[2] = 2; delta[3] = 1
            return delta
        case .B:
            var delta = Array(repeating: 0, count: 8)
            // For B move, affect corners 4,5,6,7.
            delta[4] = 1; delta[5] = 2; delta[6] = 2; delta[7] = 1
            return delta
        case .L:
            var delta = Array(repeating: 0, count: 8)
            // Affect corners 0,2,4,6.
            delta[0] = 1; delta[2] = 2; delta[4] = 2; delta[6] = 1
            return delta
        case .R:
            var delta = Array(repeating: 0, count: 8)
            // Affect corners 1,3,5,7.
            delta[1] = 1; delta[3] = 2; delta[5] = 2; delta[7] = 1
            return delta
        default:
            return self.inverse.cornerOrientationDelta
        }
    }
}
