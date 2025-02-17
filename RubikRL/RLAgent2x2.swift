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
    var solved: String = ""
    @Published var isTraining: Bool = false
    var stopRequested: Bool = false
    
    var epsilon: Double
    
    init(config: RLConfig = RLConfig()) {
        self.config = config
        self.epsilon = config.initialEpsilon
    }
    
    private func updateEpsilon(episode: Int) {
        let decayFactor = exp(-self.config.decayRate * Double(episode))
        epsilon = max(self.config.minEpsilon, self.config.initialEpsilon * decayFactor)
    }
    
    func startTraining(environment: CubeManager, completion: @escaping () -> Void) {
        guard !isTraining else { return }
        isTraining = true
        stopRequested = false
        qQueue.sync { Q.removeAll() }
        currentEpisode = 0
        maxReward = -Double.infinity
        averageReward = 0.0
        epsilon = config.initialEpsilon
        
        // Use corner-based state as solved state.
        let solvedState = environment.getCornerState()  // For example, solved state might be "00001111"
        solved = solvedState
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.trainForever(solvedState: solvedState)
            DispatchQueue.main.async {
                self.isTraining = false
                completion()
            }
        }
    }
    
    private func trainForever(solvedState: String) {
        var episodeCount = 0
        var recentRewards: [Double] = []
        
        while !stopRequested {
            episodeCount += 1
            updateEpsilon(episode: episodeCount)
            let reward = runOneEpisode(from: solvedState)
            recentRewards.append(reward)
            if recentRewards.count > config.windowSize {
                recentRewards.removeFirst()
            }
            let avgReward = recentRewards.reduce(0, +) / Double(recentRewards.count)
            
            DispatchQueue.main.async {
                self.totalEpisodes = episodeCount
                self.currentEpisode = episodeCount
                if reward > self.maxReward {
                    self.maxReward = reward
                }
                self.averageReward = avgReward
            }
            
            if episodeCount % 500 == 0 {
                print("Episode \(episodeCount): Reward=\(reward), Avg=\(avgReward), MaxReward=\(self.maxReward), Epsilon=\(self.epsilon)")
            }
            
            if recentRewards.count == config.windowSize && avgReward >= config.targetReward {
                print("Converged after \(episodeCount) episodes, avg reward: \(avgReward)")
                break
            }
        }
    }
    
    private func runOneEpisode(from solvedState: String) -> Double {
        var state = randomState(from: solvedState, moves: 10)
        var steps = 0
        var episodeReward: Double = 0
        
        while state != solved && steps < config.maxSteps && !stopRequested {
            let action = chooseActionForTraining(state: state)
            let nextState = simulateCorner(state: state, move: action)
            let reward: Double = (nextState == solved) ? (100 - Double(steps + 1)) : -1.0
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
    
    private func randomState(from solvedState: String, moves: Int) -> String {
        var state = solvedState
        let movesArray = CubeMove.availableMoves2x2
        for _ in 0..<moves {
            let move = movesArray.randomElement()!
            state = simulateCorner(state: state, move: move)
        }
        return state
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
    
    /// Simulate the effect of a move on the 8–bit corner state.
    /// The state is represented as an 8-character string.
    private func simulateCorner(state: String, move: CubeMove) -> String {
        guard state.count == 8 else { return state }
        let arr = Array(state)
        var newArr = Array(repeating: Character("0"), count: 8)
        var perm = Array(0..<8)
        switch move {
        case .U:
            // Affects top layer corners: indices 0,1,4,5.
            perm[0] = 1; perm[1] = 5; perm[5] = 4; perm[4] = 0
        case .D:
            // Affects bottom layer corners: indices 2,3,6,7.
            perm[2] = 3; perm[3] = 7; perm[7] = 6; perm[6] = 2
        case .L:
            // Affects left face: indices 0,2,4,6.
            perm[0] = 2; perm[2] = 6; perm[6] = 4; perm[4] = 0
        case .R:
            // Affects right face: indices 1,3,5,7.
            perm[1] = 3; perm[3] = 7; perm[7] = 5; perm[5] = 1
        case .F:
            // Affects front face: indices 0,1,2,3.
            perm[0] = 1; perm[1] = 3; perm[3] = 2; perm[2] = 0
        case .B:
            // Affects back face: indices 4,5,6,7.
            perm[4] = 5; perm[5] = 7; perm[7] = 6; perm[6] = 4
        default:
            return simulateCorner(state: state, move: move.inverse)
        }
        for i in 0..<8 {
            newArr[i] = arr[perm[i]]
        }
        return String(newArr)
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
            Q[state]![action]! = oldQ + config.alpha * (reward + config.gamma * maxNext - oldQ)
        }
    }
    
    /// Inference: Use pure greedy (epsilon = 0)
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
            currentState = simulateCorner(state: currentState, move: bestMove)
            if currentState == solved { break }
        }
        return solution
    }
}
