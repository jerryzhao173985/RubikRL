import Foundation

struct RLConfig {
    var size: Int = 2  // For RL we use the minimum of (sizeX, sizeY, sizeZ) – assume cubic for RL parameters.
    var alpha: Double = 0.1
    var gamma: Double = 0.9
    var initialEpsilon: Double = 1.0
    var minEpsilon: Double = 0.01
    // We'll use exponential decay in our updateEpsilon and updateAlpha functions.
    var decayRate: Double = 0.00001
    var windowSize: Int = 50         // Batch size for averaging rewards.
    var maxEpisodes: Int = 20000000
    var debugInterval: Int = 1000      // Log every 1000 episodes.
    
    var maxSteps: Int {
        switch size {
        case 2: return 2*1
        case 3: return 3*2*1
        case 4: return 4*3*2*1
        case 5: return 5*4*3*2*1
        default: return 10
        }
    }
    var targetReward: Double {
        switch size {
        case 2: return 98    // For example, 100 - (minimal penalty)
        case 3: return 95
        case 4: return 91
        case 5: return 86
        default: return 98
        }
    }
}
