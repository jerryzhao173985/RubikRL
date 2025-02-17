import Foundation
import Combine

class RLAgentSimple: ObservableObject {
    var Q: [String: [CubeAction: Double]] = [:]
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
    
    // For saving the best model.
    var bestQ: [String: [CubeAction: Double]] = [:]
    var bestAvgReward: Double = -Double.infinity
    
    // Store full dimensions for state conversion.
    let dims: (X: Int, Y: Int, Z: Int)
    
    init(config: RLConfig, dims: (X: Int, Y: Int, Z: Int)) {
        self.config = config
        self.epsilon = config.initialEpsilon
        self.currentAlpha = config.alpha
        self.dims = dims
    }
    
    private func updateEpsilon(episode: Int) {
        // Exponential decay
        epsilon = max(config.minEpsilon, config.initialEpsilon * pow(0.999, Double(episode)))
    }
    
    private func updateAlpha(episode: Int) {
        currentAlpha = max(0.001, config.alpha * pow(0.9999, Double(episode)))
    }
    
    func printQStatistics(episode: Int) {
        qQueue.sync {
            let stateCount = Q.keys.count
            let allValues = Q.values.flatMap { $0.values }
            let avgQ = allValues.reduce(0, +) / Double(allValues.count)
            print("Episode \(episode): Q-table has \(stateCount) states, avg Q: \(avgQ)")
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
        
        if let goal = environment.settings.goal {
            solved = "\(goal)"
        } else {
            solved = "1"
        }
        
        let totalStates = environment.sizeX * environment.sizeY * environment.sizeZ
        var batchRewards: [Double] = []
        var episodeCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            while !self.stopRequested && episodeCount < self.config.maxEpisodes {
                for _ in 0..<self.config.windowSize {
                    episodeCount += 1
                    self.updateEpsilon(episode: episodeCount)
                    self.updateAlpha(episode: episodeCount)
                    let initState = String(Int.random(in: 0..<totalStates))
                    let reward = self.runOneEpisode(from: initState)
                    batchRewards.append(reward)
                    
                    DispatchQueue.main.async {
                        self.currentEpisode = episodeCount
                        self.totalEpisodes = episodeCount
                        if reward > self.maxReward {
                            self.maxReward = reward
                        }
                    }
                }
                let avgBatch = batchRewards.reduce(0, +) / Double(batchRewards.count)
                let maxBatch = batchRewards.max() ?? 0.0
                print("Batch ending at episode \(episodeCount): avg reward: \(avgBatch), max reward: \(maxBatch)")
                self.printQStatistics(episode: episodeCount)
                if avgBatch >= self.config.targetReward {
                    print("Convergence achieved at episode \(episodeCount) with avg reward \(avgBatch)")
                    break
                }
                batchRewards.removeAll()
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
            let nextState = simulateState(state: state, action: action)
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
    
    private func chooseActionForTraining(state: String) -> CubeAction {
        qQueue.sync {
            if Q[state] == nil {
                Q[state] = [:]
                let actions = allCubeActions(forCubeSize: config.size)
                for action in actions {
                    Q[state]![action] = 0.001
                }
            }
        }
        if Double.random(in: 0...1) < epsilon {
            let actions = allCubeActions(forCubeSize: config.size)
            return actions.randomElement()!
        } else {
            var qState: [CubeAction: Double] = [:]
            qQueue.sync {
                qState = Q[state] ?? [:]
            }
            return qState.max { a, b in a.value < b.value }?.key ?? allCubeActions(forCubeSize: config.size).randomElement()!
        }
    }
    
    private func simulateState(state: String, action: CubeAction) -> String {
        guard let index = Int(state) else { return state }
        let X = dims.X, Y = dims.Y, Z = dims.Z
        let i = index % X
        let j = (index / X) % Y
        let k = index / (X * Y)
        let newCoord = action.transform(state: (i, j, k), dims: (X: X, Y: Y, Z: Z))
        let newIndex = newCoord.i + X * newCoord.j + X * Y * newCoord.k
        return "\(newIndex)"
    }
    
    private func updateQ(state: String, action: CubeAction, reward: Double, nextState: String) {
        qQueue.sync {
            // Ensure Q[state] is initialized.
            if Q[state] == nil {
                Q[state] = [:]
                let actions = allCubeActions(forCubeSize: config.size)
                for act in actions {
                    Q[state]![act] = 0.001
                }
            }
            // Also ensure Q[nextState] is initialized.
            if Q[nextState] == nil {
                Q[nextState] = [:]
                let actions = allCubeActions(forCubeSize: config.size)
                for act in actions {
                    Q[nextState]![act] = 0.001
                }
            }
            let maxNext = Q[nextState]!.values.max() ?? 0.0
            let oldQ = Q[state]![action] ?? 0.001
            Q[state]![action] = oldQ + currentAlpha * (reward + config.gamma * maxNext - oldQ)
        }
    }
    
    func getSolution(from state: String, maxDepth: Int = 50) -> [CubeAction] {
        var solution: [CubeAction] = []
        var currentState = state
        for _ in 0..<maxDepth {
            if currentState == solved { break }
            var actions: [CubeAction: Double] = [:]
            qQueue.sync {
                actions = Q[currentState] ?? [:]
            }
            if actions.isEmpty {
                print("No Q-value for state: \(currentState)")
                break
            }
            guard let bestAction = actions.max(by: { a, b in a.value < b.value })?.key else { break }
            solution.append(bestAction)
            currentState = simulateState(state: currentState, action: bestAction)
            if currentState == solved { break }
        }
        return solution
    }
}
