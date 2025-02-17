import SceneKit

enum CubeMove: String, CaseIterable {
    case U, UPrime, D, DPrime, L, LPrime, R, RPrime, F, FPrime, B, BPrime

    // For RL we use all 12 moves.
    static var availableMoves2x2: [CubeMove] {
        return CubeMove.allCases
    }
    
    // For visualization.
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
    
    /// Permutation mapping on indices 0...7.
    /// (These are example mappings; you may adjust them to better reflect Rubik’s cube moves.)
    var cornerPermutation: [Int] {
        switch self {
        case .U:
            // Cycle top corners: positions 0,1,4,5.
            var perm = Array(0..<8)
            perm[0] = 1; perm[1] = 5; perm[5] = 4; perm[4] = 0
            return perm
        case .UPrime:
            var perm = Array(0..<8)
            perm[0] = 4; perm[4] = 5; perm[5] = 1; perm[1] = 0
            return perm
        case .D:
            // Cycle bottom corners: positions 2,3,6,7.
            var perm = Array(0..<8)
            perm[2] = 3; perm[3] = 7; perm[7] = 6; perm[6] = 2
            return perm
        case .DPrime:
            var perm = Array(0..<8)
            perm[2] = 6; perm[6] = 7; perm[7] = 3; perm[3] = 2
            return perm
        case .L:
            // Cycle left face: positions 0,2,4,6.
            var perm = Array(0..<8)
            perm[0] = 2; perm[2] = 6; perm[6] = 4; perm[4] = 0
            return perm
        case .LPrime:
            var perm = Array(0..<8)
            perm[0] = 4; perm[4] = 6; perm[6] = 2; perm[2] = 0
            return perm
        case .R:
            // Cycle right face: positions 1,3,5,7.
            var perm = Array(0..<8)
            perm[1] = 3; perm[3] = 7; perm[7] = 5; perm[5] = 1
            return perm
        case .RPrime:
            var perm = Array(0..<8)
            perm[1] = 5; perm[5] = 7; perm[7] = 3; perm[3] = 1
            return perm
        case .F:
            // Cycle front face: positions 0,1,2,3.
            var perm = Array(0..<8)
            perm[0] = 1; perm[1] = 3; perm[3] = 2; perm[2] = 0
            return perm
        case .FPrime:
            var perm = Array(0..<8)
            perm[0] = 2; perm[2] = 3; perm[3] = 1; perm[1] = 0
            return perm
        case .B:
            // Cycle back face: positions 4,5,6,7.
            var perm = Array(0..<8)
            perm[4] = 5; perm[5] = 7; perm[7] = 6; perm[6] = 4
            return perm
        case .BPrime:
            var perm = Array(0..<8)
            perm[4] = 6; perm[6] = 7; perm[7] = 5; perm[5] = 4
            return perm
        }
    }
}
