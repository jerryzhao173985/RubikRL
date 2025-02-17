import Foundation

struct RLConfig {
    var alpha: Double = 0.1          // Initial learning rate.
    var gamma: Double = 0.9          // Discount factor.
    var initialEpsilon: Double = 1.0 // Starting exploration.
    var minEpsilon: Double = 0.05    // Minimum exploration.
    var decayRate: Double = 0.00001  // Epsilon decays slowly.
    var maxSteps: Int = 10           // Maximum moves per episode.
    var maxEpisodes: Int = 20000000    // Maximum training episodes.
    var debugInterval: Int = 1000    // Print Q-table stats every 1000 episodes.
    var targetReward: Double = 98.0  // Target average reward for convergence.
    var windowSize: Int = 10        // Number of episodes for averaging reward.
}
