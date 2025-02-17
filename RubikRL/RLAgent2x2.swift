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
    var solvedSet: Set<String> = []
    @Published var isTraining: Bool = false
    var stopRequested: Bool = false
    
    var epsilon: Double
    var currentAlpha: Double
    
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
    
    /// Generate all equivalent solved states by applying the 24 global rotations.
    private func generateSolvedSet(from canonical: String) -> Set<String> {
        // canonical is a 16-character string (2 digits per corner).
        var set = Set<String>()
        for perm in globalCornerRotations {
            var newState = ""
            let arr = Array(canonical)
            for i in 0..<8 {
                let srcIndex = 2 * perm[i]
                newState.append(arr[srcIndex])
                newState.append(arr[srcIndex + 1])
            }
            set.insert(newState)
        }
        return set
    }
    
    private func isSolved(_ state: String) -> Bool {
        return solvedSet.contains(state)
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
        currentAlpha = config.alpha
        
        let solvedState = environment.getCornerState()  // e.g. "0,0;1,0;2,0;...;7,0"
        // Convert canonical state to our compact representation.
        // We'll assume it becomes a 16-character string by removing separators.
        let canonical = solvedState.replacingOccurrences(of: ";", with: "")
        solved = canonical
        solvedSet = generateSolvedSet(from: canonical)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.trainForever(solvedState: canonical)
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
            updateAlpha(episode: episodeCount)
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
            
            if episodeCount % 10000 == 0 {
                print("Episode \(episodeCount): Reward=\(reward), Avg=\(avgReward), MaxReward=\(self.maxReward), Epsilon=\(self.epsilon), Alpha=\(self.currentAlpha)")
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
        let gamma = config.gamma
        
        while !isSolved(state) && steps < config.maxSteps && !stopRequested {
            let currentPotential = Double(numCorrectCorners(state: state))
            let action = chooseActionForTraining(state: state)
            let nextState = simulateDetailed(state: state, move: action)
            let nextPotential = Double(numCorrectCorners(state: nextState))
            let r = -1.0
            let shapedReward = r + gamma * nextPotential - currentPotential
            let reward: Double = isSolved(nextState) ? (shapedReward + (100 - Double(steps + 1))) : shapedReward
            updateQ(state: state, action: action, reward: reward, nextState: nextState)
            episodeReward += reward
            state = nextState
            steps += 1
            if isSolved(state) { break }
        }
        if !isSolved(state) {
            return -Double(config.maxSteps)
        }
        return episodeReward
    }
    
    private func numCorrectCorners(state: String) -> Int {
        // State is 16 characters: for each corner, first digit is id, second digit is twist.
        // Compare twist with canonical solved twist (which is 0).
        guard state.count == solved.count else { return 0 }
        let arr = Array(state)
        var count = 0
        for i in stride(from: 1, to: state.count, by: 2) {
            if String(arr[i]) == "0" {
                count += 1
            }
        }
        return count
    }
    
    private func randomState(from solvedState: String, moves: Int) -> String {
        var state = solvedState
        let movesArray = CubeMove.availableMoves2x2
        for _ in 0..<moves {
            let move = movesArray.randomElement()!
            state = simulateDetailed(state: state, move: move)
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
    
    /// Simulate the effect of a move on the detailed corner state.
    /// Our detailed state is a 16-character string: each corner is 2 digits (id and twist).
    /// We update the state by applying the move's cornerPermutation and updating twist.
    private func simulateDetailed(state: String, move: CubeMove) -> String {
        guard state.count == 16 else { return state }
        let arr = Array(state)
        // Parse state into 8 corners: each corner is a tuple (id, twist)
        var corners: [(Int, Int)] = []
        for i in stride(from: 0, to: 16, by: 2) {
            let idStr = String(arr[i])
            let twistStr = String(arr[i+1])
            if let id = Int(idStr), let twist = Int(twistStr) {
                corners.append((id, twist))
            }
        }
        // Get permutation mapping.
        let perm = move.cornerPermutation  // array of 8 ints
        let delta = move.cornerOrientationDelta  // array of 8 ints
        var newCorners = Array(repeating: (0,0), count: 8)
        for i in 0..<8 {
            let from = perm[i]
            let (id, twist) = corners[from]
            newCorners[i] = (id, (twist + delta[from]) % 3)
        }
        var newState = ""
        for (id, twist) in newCorners {
            newState += "\(id)\(twist)"
        }
        return newState
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
    
    /// Inference: Use pure greedy (epsilon = 0).
    func getSolution(from state: String, maxDepth: Int = 50) -> [CubeMove] {
        var solution: [CubeMove] = []
        var currentState = state
        for _ in 0..<maxDepth {
            if isSolved(currentState) { break }
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
            currentState = simulateDetailed(state: currentState, move: bestMove)
            if isSolved(currentState) { break }
        }
        return solution
    }
    
    func printQStatistics() {
        qQueue.sync {
            let stateCount = Q.keys.count
            let allValues = Q.values.flatMap { $0.values }
            let avgQ = allValues.reduce(0, +) / Double(allValues.count)
            print("Q–table: \(stateCount) states, avg Q value: \(avgQ)")
        }
    }
}
