import Foundation

struct RLConfig {
    var alpha: Double = 0.1          // Initial learning rate.
    var gamma: Double = 0.9          // Discount factor.
    var initialEpsilon: Double = 1.0 // Starting exploration.
    var minEpsilon: Double = 0.01    // Minimum exploration.
    var decayRate: Double = 0.00001  // Slower epsilon decay.
    var maxSteps: Int = 50           // Maximum moves per episode.
    var windowSize: Int = 50         // Episodes for averaging reward.
    var targetReward: Double = 99.9  // Convergence target.
}
