Below is one “complete‐from‑scratch” example that redefines the state space using an 8–element (corner–based) representation. In this approach we assume that the cube is always held in a fixed orientation so that the 8 corners are in known positions. We number the corners in the solved state as follows (in reading order):
	•	Front layer:
0 = front‑top‑left,
1 = front‑top‑right,
2 = front‑bottom‑left,
3 = front‑bottom‑right
	•	Back layer:
4 = back‑top‑left,
5 = back‑top‑right,
6 = back‑bottom‑left,
7 = back‑bottom‑right

Because we assign colors as follows (by face):
• Front, Back, Top are red
• Right, Left, Bottom are blue

each corner will have three visible faces. In a solved cube the corners will have one of two possible color–combinations (when ordered in a canonical way). For example, if we “read” each corner’s visible faces in a fixed order (say, for front layer: Top, Front, Left; for back layer: Top, Back, Right), then in the solved state the front–top–left corner might be (red, red, blue) and the front–bottom–right might be (blue, red, blue). (The exact pattern depends on how you choose to “read” each corner.)
We now “reduce” this further by assigning a single binary value per corner. For example, we choose a convention so that in the solved state exactly four corners yield “0” and the other four yield “1.” (For instance, one simple choice is to use the sign of the Y–coordinate: if y > 0 then output “0,” else “1.”)
That is a very simple (and very low–dimensional) representation: an 8–character string (each character either “0” or “1”). In a solved cube (with our fixed construction) the top layer corners will be “0” and the bottom layer “1.” (For example, the solved state might be “0011 1100” or some fixed pattern depending on the ordering.)
Because there are only 8 corners, the total state space is at most 2⁸ = 256 possible states. (In our construction many of these states may not be reachable.) This representation is dramatically smaller than a 24–element (face–based) one but still captures the essential distinction between, say, a cubie being in the top half versus bottom half. (It does not capture full orientation details—but as you requested, we are not tracking full sticker orientation.)

Furthermore, we define the effect of each move as a permutation on the 8 corners. For example, an U (up) move rotates the top face corners among themselves. We define the following corner–permutation mappings (these are one possible convention):
	•	U: affects corners [0, 1, 4, 5]. Clockwise cycle:
new[0] = old[1], new[1] = old[5], new[5] = old[4], new[4] = old[0]; other indices unchanged.
	•	D: affects corners [2, 3, 6, 7]. Clockwise cycle:
new[2] = old[3], new[3] = old[7], new[7] = old[6], new[6] = old[2].
	•	L: affects corners [0, 2, 4, 6]. Clockwise cycle:
new[0] = old[2], new[2] = old[6], new[6] = old[4], new[4] = old[0].
	•	R: affects corners [1, 3, 5, 7]. Clockwise cycle:
new[1] = old[3], new[3] = old[7], new[7] = old[5], new[5] = old[1].
	•	F: affects corners [0, 1, 2, 3]. Clockwise cycle:
new[0] = old[1], new[1] = old[3], new[3] = old[2], new[2] = old[0].
	•	B: affects corners [4, 5, 6, 7]. Clockwise cycle:
new[4] = old[5], new[5] = old[7], new[7] = old[6], new[6] = old[4].

We then use these permutations to simulate the effect of a move on the current 8–bit state. The RL agent’s reward function is defined as follows:
	•	Each move gives –1.
	•	If a move results in a solved state (i.e. the 8–bit state matches the solved pattern), then reward = 100 – (number of moves taken).

Finally, we implement epsilon decay (starting at 1.0 and decaying slowly) during training; during inference (when “Run” is pressed) we use pure greedy.

Below is the complete code for each file. You can split these into separate Swift files in your Xcode project.

RLConfig.swift

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

CubeMove.swift

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
            return U.inverse.cornerPermutation
        case .DPrime:
            return D.inverse.cornerPermutation
        case .LPrime:
            return L.inverse.cornerPermutation
        case .RPrime:
            return R.inverse.cornerPermutation
        case .FPrime:
            return F.inverse.cornerPermutation
        case .BPrime:
            return B.inverse.cornerPermutation
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

Cubie.swift

import SceneKit

class Cubie {
    let id: Int          // Unique ID assigned during construction.
    let node: SCNNode
    var logicalPosition: (x: Double, y: Double, z: Double)
    let solvedPosition: (x: Double, y: Double, z: Double)
    var netRotation: SCNQuaternion
    
    init(id: Int, node: SCNNode, position: (x: Double, y: Double, z: Double)) {
        self.id = id
        self.node = node
        self.logicalPosition = position
        self.solvedPosition = position
        self.netRotation = SCNQuaternion(0, 0, 0, 1)
    }
}

CubeManager.swift

We add a new method getCornerState() that returns an 8–character string. For simplicity we define the binary value for a corner as follows: if the cubie’s y–coordinate is positive (i.e. it’s in the top layer) we output “0”, otherwise “1”. (In a solved cube—according to our construction—this yields a fixed 8–bit pattern.)
This is our simplified state representation.

import SceneKit
import SwiftUI

class CubeManager: ObservableObject {
    let scene: SCNScene
    let cubeContainer: SCNNode
    var cubies: [Cubie] = []
    let positions: [Double] = [-0.5, 0.5]
    var moveHistory: [CubeMove] = []
    var isAnimating = false

    @Published var activeMove: CubeMove? = nil

    init() {
        scene = SCNScene()
        cubeContainer = SCNNode()
        scene.rootNode.addChildNode(cubeContainer)
        setupCameraAndLights()
        buildCube()
    }

    private func setupCameraAndLights() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(2, 2, 2)
        let constraint = SCNLookAtConstraint(target: cubeContainer)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        scene.rootNode.addChildNode(cameraNode)

        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.position = SCNVector3(3, 3, 3)
        scene.rootNode.addChildNode(omniLight)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLight)
    }

    private func buildCube() {
        var cubieId = 0
        for x in positions {
            for y in positions {
                for z in positions {
                    let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.01)
                    // Use two colors: red for front, back, top; blue for right, left, bottom.
                    let redMat = SCNMaterial(); redMat.diffuse.contents = UIColor.red
                    let blueMat = SCNMaterial(); blueMat.diffuse.contents = UIColor.blue
                    box.materials = [redMat, blueMat, redMat, blueMat, redMat, blueMat]
                    
                    let cubieNode = SCNNode(geometry: box)
                    cubieNode.position = SCNVector3(Float(x), Float(y), Float(z))
                    cubeContainer.addChildNode(cubieNode)
                    let cubie = Cubie(id: cubieId, node: cubieNode, position: (x, y, z))
                    cubies.append(cubie)
                    cubieId += 1
                }
            }
        }
    }

    private func updateCubieTransform(_ cubie: Cubie) {
        let newPos = SCNVector3(Float(cubie.logicalPosition.x),
                                Float(cubie.logicalPosition.y),
                                Float(cubie.logicalPosition.z))
        cubie.node.position = newPos
        cubie.node.orientation = cubie.netRotation
    }

    func performMove(_ move: CubeMove, record: Bool = true, completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        DispatchQueue.main.async { self.activeMove = move }
        
        let layer = move.affectedLayer
        let affectedCubies = cubies.filter { cubie in
            switch layer.axis {
            case "x": return cubie.logicalPosition.x == layer.value
            case "y": return cubie.logicalPosition.y == layer.value
            case "z": return cubie.logicalPosition.z == layer.value
            default: return false
            }
        }
        
        let groupNode = SCNNode()
        cubeContainer.addChildNode(groupNode)
        for cubie in affectedCubies {
            cubie.node.removeFromParentNode()
            groupNode.addChildNode(cubie.node)
        }
        
        let rotationAction = SCNAction.rotate(by: CGFloat(move.angle), around: move.axis, duration: 0.3)
        groupNode.runAction(rotationAction) { [weak self] in
            guard let self = self else { return }
            for cubie in affectedCubies {
                cubie.logicalPosition = move.rotateCoordinate(cubie.logicalPosition)
                let oldQuat = cubie.netRotation
                let moveQuat = move.quaternion
                cubie.netRotation = self.multiplyQuaternion(q1: moveQuat, q2: oldQuat)
                
                let worldT = cubie.node.worldTransform
                cubie.node.transform = self.cubeContainer.convertTransform(worldT, from: nil)
                self.cubeContainer.addChildNode(cubie.node)
                self.updateCubieTransform(cubie)
            }
            groupNode.removeFromParentNode()
            if record { self.moveHistory.append(move) }
            self.isAnimating = false
            DispatchQueue.main.async { self.activeMove = nil }
            completion?()
        }
    }
    
    private func multiplyQuaternion(q1: SCNQuaternion, q2: SCNQuaternion) -> SCNQuaternion {
        let w1 = q1.w, x1 = q1.x, y1 = q1.y, z1 = q1.z
        let w2 = q2.w, x2 = q2.x, y2 = q2.y, z2 = q2.z
        let w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
        let x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2
        let y = w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2
        let z = w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2
        return SCNQuaternion(x, y, z, w)
    }
    
    func randomizeCube() {
        guard !isAnimating else { return }
        let moves = CubeMove.availableMoves2x2
        let count = 10
        var current = 0
        func performNext() {
            if current >= count { return }
            let move = moves.randomElement()!
            performMove(move) {
                current += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    performNext()
                }
            }
        }
        performNext()
    }
    
    /// Returns an 8-character string representing the simplified corner state.
    /// We order the cubies by their id (assigned during buildCube) and for each cubie output "0" if its y is > 0 (top) and "1" if y < 0 (bottom).
    func getCornerState() -> String {
        let sortedCubies = cubies.sorted { $0.id < $1.id }
        let state = sortedCubies.map { cubie -> String in
            return (cubie.logicalPosition.y > 0) ? "0" : "1"
        }
        return state.joined()
    }
}

RLAgent2x2.swift

Now we update the RL agent to work on the simplified 8–bit state (corner state). In this model, a move is simulated by applying a permutation on the 8 corners. We define the following permutation mappings:
	•	U: Permutation on indices: top face corners [0,1,4,5] are cycled: 0→1, 1→5, 5→4, 4→0; others remain.
	•	D: Permutation on bottom face corners [2,3,6,7]: 2→3, 3→7, 7→6, 6→2.
	•	L: Permutation on left face corners [0,2,4,6]: 0→2, 2→6, 6→4, 4→0.
	•	R: Permutation on right face corners [1,3,5,7]: 1→3, 3→7, 7→5, 5→1.
	•	F: Permutation on front face corners [0,1,2,3]: 0→1, 1→3, 3→2, 2→0.
	•	B: Permutation on back face corners [4,5,6,7]: 4→5, 5→7, 7→6, 6→4.

We use these mappings in simulateCorner(state:move:). The reward function is the same as before (–1 per move, and if the state is solved then reward = 100 – moves).

We also implement epsilon decay as before (during training) and use greedy (epsilon=0) for inference.

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
    /// The state string is 8 characters long.
    private func simulateCorner(state: String, move: CubeMove) -> String {
        guard state.count == 8 else { return state }
        let arr = Array(state)
        var newArr = Array(repeating: Character("0"), count: 8)
        var perm = Array(0..<8)
        switch move {
        case .U:
            // Affects top face corners: indices 0,1,4,5.
            perm[0] = 1; perm[1] = 5; perm[5] = 4; perm[4] = 0
        case .D:
            // Affects bottom face corners: indices 2,3,6,7.
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
    
    /// Inference: Use greedy (epsilon = 0)
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

RubiksCubeFullView.swift

import SwiftUI
import SceneKit

struct RubiksCubeFullView: UIViewRepresentable {
    let cubeManager: CubeManager

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.scene = cubeManager.scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.black
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) { }
}

ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var cubeManager = CubeManager()
    @StateObject private var rlAgent = RLAgent2x2()
    
    var body: some View {
        VStack {
            RubiksCubeFullView(cubeManager: cubeManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 20) {
                Text("Episode: \(rlAgent.currentEpisode) / \(rlAgent.totalEpisodes)")
                    .foregroundColor(.white)
                    .font(.headline)
                Text("Max Reward: \(String(format: "%.2f", rlAgent.maxReward))")
                    .foregroundColor(.white)
                    .font(.headline)
                HStack(spacing: 30) {
                    Button(action: {
                        cubeManager.randomizeCube()
                    }) {
                        Text("Random")
                            .font(.title2)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    Button(action: {
                        rlAgent.startTraining(environment: cubeManager) {
                            print("Training converged or stopped.")
                        }
                    }) {
                        Text("Learn")
                            .font(.title2)
                            .padding()
                            .background(rlAgent.isTraining ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(rlAgent.isTraining)
                    Button(action: {
                        let currentState = cubeManager.getCornerState()
                        print("Current corner state: \(currentState)")
                        let solution = rlAgent.getSolution(from: currentState, maxDepth: 50)
                        print("RL solution: \(solution.map { $0.rawValue })")
                        cubeManager.animateSolution(moves: solution)
                    }) {
                        Text("Run")
                            .font(.title2)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.black)
            .frame(height: 160)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

Final Explanation
	1.	State Representation:
We now represent the cube’s state as an 8–character string (one character per corner), where we simply assign a “0” if the cubie is in the top layer (y > 0) and “1” if it is in the bottom layer (y < 0).
In a solved cube (with our fixed construction) this yields a consistent pattern (for example, “00001111”).
This is a dramatic reduction in state dimension (only 256 possible states).
	2.	Corner Simulation:
We define permutation mappings on the 8 corners for each move (U, D, L, R, F, B). The simulation function simulateCorner(state:move:) applies these mappings to the 8–bit state.
	3.	Reward Shaping:
Each move gives –1; if a move results in a solved state, the reward is 100 minus the number of moves taken.
	4.	Epsilon Decay & Inference:
Epsilon decays gradually during training; during inference (the “Run” button) we use the current corner state and select moves greedily.
	5.	Integration:
ContentView now uses cubeManager.getCornerState() for inference.
Q–table accesses are synchronized via a serial queue.

Compile and run this code. This new, reduced 8–bit state representation should be much easier for the agent to learn, while still preserving essential information about whether corners are in the top or bottom layer (which—if arranged correctly—corresponds to the solved condition for our simplified 2×2 cube). Adjust hyperparameters and permutation mappings as needed to suit your requirements.
