import Foundation
import Combine

class RLAgentSimple: ObservableObject {
    var Q: [String: [CubeMove: Double]] = [:]
    private let qQueue = DispatchQueue(label: "com.mycompany.RubikRL.QQueue")
    
    var config: RLConfig
    @Published var currentEpisode: Int = 0
    @Published var maxReward: Double = -Double.infinity
    @Published var totalEpisodes: Int = 0
    @Published var averageReward: Double = 0.0
    
    var solved: String = "1"  // Target state.
    var isTraining: Bool = false
    var stopRequested: Bool = false
    
    var epsilon: Double
    var currentAlpha: Double  // Learning rate.
    
    // Best model tracking.
    var bestQ: [String: [CubeMove: Double]] = [:]
    var bestAvgReward: Double = -Double.infinity
    
    init(config: RLConfig = RLConfig()) {
        self.config = config
        self.epsilon = config.initialEpsilon
        self.currentAlpha = config.alpha
    }
    
    private func updateEpsilon(episode: Int) {
        let decayFactor = exp(-self.config.decayRate * Double(episode))
        epsilon = max(self.config.minEpsilon, self.config.initialEpsilon * decayFactor)
    }
    
    private func updateAlpha(episode: Int) {
        currentAlpha = max(0.001, config.alpha - 0.00001 * Double(episode))
    }
    
    func printQStatistics(episode: Int) {
        qQueue.sync {
            let stateCount = Q.keys.count
            let allValues = Q.values.flatMap { $0.values }
            let avgQ = allValues.reduce(0, +) / Double(allValues.count)
//            print("Episode \(episode): Q-table has \(stateCount) states, avg Q: \(avgQ)")
        }
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
        solved = "1"
        
        // We'll accumulate rewards in a batch array.
        var batchRewards: [Double] = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            for episode in 1...self.config.maxEpisodes {
                if self.stopRequested { break }
                self.updateEpsilon(episode: episode)
                self.updateAlpha(episode: episode)
                let initState = String(Int.random(in: 0..<8))
                let reward = self.runOneEpisode(from: initState)
                
                // Update episode counters on main thread.
                DispatchQueue.main.async {
                    self.currentEpisode = episode
                    self.totalEpisodes = episode
                    if reward > self.maxReward {
                        self.maxReward = reward
                    }
                }
                
                // Append this episode's reward to the batch.
                batchRewards.append(reward)
                
                // Every windowSize episodes, compute and log batch stats.
                if episode % self.config.windowSize == 0 {
                    let avgBatchReward = batchRewards.reduce(0, +) / Double(batchRewards.count)
                    let maxBatchReward = batchRewards.max() ?? 0.0
                    if episode % self.config.debugInterval == 0 {
                        print("Batch ending at episode \(episode): avg reward: \(avgBatchReward), max reward: \(maxBatchReward)")
                    }
                    self.printQStatistics(episode: episode)
                    
                    // Check convergence: if the average reward over the batch is above targetReward, stop training.
                    if avgBatchReward >= self.config.targetReward {
                        print("Convergence achieved at episode \(episode) with avg reward \(avgBatchReward)")
                        break
                    }
                    // Reset batchRewards for next batch.
                    batchRewards.removeAll()
                }
            }
            DispatchQueue.main.async {
                self.isTraining = false
                completion()
            }
        }
    }
    
    private func runOneEpisode(from initState: String) -> Double {
        var state = initState
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
            // Now choose from all 12 moves.
            return CubeMove.allCases.randomElement()!
        } else {
            var qState: [CubeMove: Double] = [:]
            qQueue.sync {
                qState = Q[state] ?? [:]
            }
            return qState.max { a, b in a.value < b.value }?.key ?? CubeMove.allCases.randomElement()!
        }
    }
    
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
                print("No Q-value for state: \(currentState)")
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
