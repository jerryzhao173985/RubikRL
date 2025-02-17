import SceneKit

enum CubeMove: String, CaseIterable {
    case U, D, L, R, F, B, UPrime, DPrime, LPrime, RPrime, FPrime, BPrime
    
    // We assume the RL agent will only use the non-prime moves for simplicity.
    static var availableMoves2x2: [CubeMove] {
        return [.U, .D, .L, .R, .F, .B]
    }
    
    // For corner simulation, we define permutation mappings on indices 0...7.
    var cornerPermutation: [Int] {
        switch self {
        case .U:
            // Affects corners 0,1,4,5. Clockwise: 0->1, 1->5, 5->4, 4->0.
            return [1, 5, 2, 3, 0, 4, 6, 7]
        case .D:
            // Affects corners 2,3,6,7. Clockwise: 2->3, 3->7, 7->6, 6->2.
            return [0, 1, 3, 7, 4, 5, 2, 6]
        case .L:
            // Affects corners 0,2,4,6. Clockwise: 0->2, 2->6, 6->4, 4->0.
            return [2, 1, 6, 3, 0, 5, 4, 7]
        case .R:
            // Affects corners 1,3,5,7. Clockwise: 1->3, 3->7, 7->5, 5->1.
            return [0, 3, 2, 7, 4, 1, 6, 5]
        case .F:
            // Affects corners 0,1,2,3. Clockwise: 0->1, 1->3, 3->2, 2->0.
            return [1, 3, 0, 2, 4, 5, 6, 7]
        case .B:
            // Affects corners 4,5,6,7. Clockwise: 4->5, 5->7, 7->6, 6->4.
            return [0, 1, 2, 3, 5, 7, 4, 6]
        case .UPrime:
            return CubeMove.U.inverse.cornerPermutation
        case .DPrime:
            return CubeMove.D.inverse.cornerPermutation
        case .LPrime:
            return CubeMove.L.inverse.cornerPermutation
        case .RPrime:
            return CubeMove.R.inverse.cornerPermutation
        case .FPrime:
            return CubeMove.F.inverse.cornerPermutation
        case .BPrime:
            return CubeMove.B.inverse.cornerPermutation
        }
    }
    
    // Define inverse as three quarter turn.
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
