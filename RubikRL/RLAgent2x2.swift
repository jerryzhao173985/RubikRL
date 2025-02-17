import Foundation
import Combine

class RLAgent2x2: ObservableObject {
    var Q: [String: [CubeMove: Double]] = [:]
    private let qQueue = DispatchQueue(label: "com.mycompany.RubikRL.QQueue")
    
    var config: RLConfig
    @Published var currentEpisode: Int = 0
    @Published var maxReward: Double = -Double.infinity
    @Published var totalEpisodes: Int = 0
    @Published var averageReward: Double = 0.0
    var solved: String = "1"  // target: blue corner index must be 1.
    @Published var isTraining: Bool = false
    var stopRequested: Bool = false
    
    var epsilon: Double
    var currentAlpha: Double  // learning rate that decays
    
    init(config: RLConfig = RLConfig()) {
        self.config = config
        self.epsilon = config.initialEpsilon
        self.currentAlpha = config.alpha
    }
    
    private func updateEpsilon(episode: Int) {
        let decayFactor = exp(Double(-self.config.decayRate) * Double(episode))
        epsilon = max(self.config.minEpsilon, self.config.initialEpsilon * decayFactor)
    }
    
    private func updateAlpha(episode: Int) {
        currentAlpha = max(0.001, config.alpha - 0.00001 * Double(episode))
    }
    
    func startTraining(environment: CubeManager, completion: @escaping () -> Void) {
        isTraining = true
        stopRequested = false
        qQueue.sync { Q.removeAll() }
        currentEpisode = 0
        maxReward = -Double.infinity
        averageReward = 0.0
        epsilon = config.initialEpsilon
        currentAlpha = config.alpha
        
        // Set solved state from environment settings (if provided) or default "1".
        if let goal = environment.settings.goal {
            solved = "\(goal)"
        } else {
            solved = "1"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.trainForever()
            DispatchQueue.main.async {
                self.isTraining = false
                completion()
            }
        }
    }
    
    private func trainForever() {
        var episodeCount = 0
        var recentRewards: [Double] = []
        let totalStates = config.size * config.size * config.size

        while !stopRequested {
            episodeCount += 1
            updateEpsilon(episode: episodeCount)
            updateAlpha(episode: episodeCount)
            
            // Randomize initial state for each episode.
            let initState = String(Int.random(in: 0..<totalStates))
            let reward = runOneEpisode()
            recentRewards.append(reward)
            if recentRewards.count > config.windowSize {
                recentRewards.removeFirst()
            }
            let avgReward = recentRewards.reduce(0, +) / Double(recentRewards.count)
            
            DispatchQueue.main.async {
                self.currentEpisode = episodeCount
                self.totalEpisodes = episodeCount
                if reward > self.maxReward {
                    self.maxReward = reward
                }
                self.averageReward = avgReward
            }
            
            if episodeCount % 500 == 0 {
                print("Episode \(episodeCount): Reward = \(reward), Batch Avg = \(avgReward), MaxReward = \(self.maxReward), Epsilon = \(self.epsilon), Alpha = \(self.currentAlpha)")
            }
            
            // Stop training if we have a full batch and the average reward meets or exceeds the target.
            if recentRewards.count == config.windowSize && avgReward >= config.targetReward {
                print("Convergence achieved after \(episodeCount) episodes with avg reward \(avgReward)")
                break
            }
        }
    }
    
    private func runOneEpisode() -> Double {
        var state = randomState()
        var steps = 0
        var episodeReward = 0.0
        while state != solved && steps < config.maxSteps && !stopRequested {
            let action = chooseActionForTraining(state: state)
            let nextState = simulateState(state: state, move: action)
            let reward: Double = nextState == solved ? (100 - Double(steps + 1)) : -1.0
            updateQ(state: state, action: action, reward: reward, nextState: nextState)
            episodeReward += reward
            state = nextState
            steps += 1
            if state == solved { break }
        }
        if state != solved {
            return -Double(config.maxSteps)
        }
        return episodeReward
    }
    
    private func randomState() -> String {
        let rand = Int.random(in: 0..<8)
        return "\(rand)"
    }
    
    private func chooseActionForTraining(state: String) -> CubeMove {
        qQueue.sync {
            if Q[state] == nil {
                Q[state] = [:]
                for move in CubeMove.availableMoves2x2 {
                    Q[state]![move] = 0.001
                }
            }
        }
        if Double.random(in: 0...1) < epsilon {
            return CubeMove.availableMoves2x2.randomElement()!
        } else {
            var qState: [CubeMove: Double] = [:]
            qQueue.sync {
                qState = Q[state] ?? [:]
            }
            return qState.max { a, b in a.value < b.value }!.key
        }
    }
    
    /// Given the current state (a single digit as string) and a move, simulate the new state.
    private func simulateState(state: String, move: CubeMove) -> String {
        guard let index = Int(state) else { return state }
        let perm = move.cornerPermutation
        let newIndex = perm[index]
        return "\(newIndex)"
    }
    
    private func updateQ(state: String, action: CubeMove, reward: Double, nextState: String) {
        qQueue.sync {
            if Q[nextState] == nil {
                Q[nextState] = [:]
                for move in CubeMove.availableMoves2x2 {
                    Q[nextState]![move] = 0.001
                }
            }
            let maxNext = Q[nextState]!.values.max() ?? 0.0
            let oldQ = Q[state]![action] ?? 0.001
            Q[state]![action]! = oldQ + currentAlpha * (reward + config.gamma * maxNext - oldQ)
        }
    }
    
    func getSolution(from state: String, maxDepth: Int = 50) -> [CubeMove] {
        var solution: [CubeMove] = []
        var currentState = state
        for _ in 0..<maxDepth {
            if currentState == solved { break }
            var actions: [CubeMove: Double] = [:]
            qQueue.sync {
                actions = Q[currentState] ?? [:]
            }
            if actions.isEmpty {
                print("No Q–value for state: \(currentState)")
                break
            }
            guard let bestMove = actions.max(by: { a, b in a.value < b.value })?.key else { break }
            solution.append(bestMove)
            currentState = simulateState(state: currentState, move: bestMove)
            if currentState == solved { break }
        }
        return solution
    }
}
