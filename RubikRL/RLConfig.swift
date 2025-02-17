import Foundation

struct RLConfig {
    var alpha: Double = 0.1          // Learning rate.
    var gamma: Double = 0.9          // Discount factor.
    var initialEpsilon: Double = 1.0 // Starting exploration.
    var minEpsilon: Double = 0.01    // Minimum exploration.
    var decayRate: Double = 0.0001   // Epsilon decay per episode.
    var maxSteps: Int = 50           // Max moves per episode.
    var windowSize: Int = 50         // Episodes for averaging reward.
    var targetReward: Double = 90.0  // Convergence target.
}
