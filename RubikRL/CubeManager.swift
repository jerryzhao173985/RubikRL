import SceneKit
import SwiftUI

class CubeManager: ObservableObject {
    let scene: SCNScene
    let cubeContainer: SCNNode
    var cubies: [Cubie] = []
    // Canonical positions (fixed).
    let positions: [(x: Double, y: Double, z: Double)] = [
        (-0.5, 0.5, 0.5),   // 0: front-top-left
        (0.5, 0.5, 0.5),    // 1: front-top-right
        (-0.5, -0.5, 0.5),  // 2: front-bottom-left
        (0.5, -0.5, 0.5),   // 3: front-bottom-right
        (-0.5, 0.5, -0.5),  // 4: back-top-left
        (0.5, 0.5, -0.5),   // 5: back-top-right
        (-0.5, -0.5, -0.5), // 6: back-bottom-left
        (0.5, -0.5, -0.5)   // 7: back-bottom-right
    ]
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
        // Build cubies at fixed positions.
        // Randomly choose one cubie to be blue.
        let blueIndex = Int.random(in: 0..<8)
        for i in 0..<positions.count {
            let pos = positions[i]
            let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.01)
            let redMat = SCNMaterial(); redMat.diffuse.contents = UIColor.red
            let blueMat = SCNMaterial(); blueMat.diffuse.contents = UIColor.blue
            box.materials = [redMat, redMat, redMat, redMat, redMat, redMat]
            let node = SCNNode(geometry: box)
            node.position = SCNVector3(Float(pos.x), Float(pos.y), Float(pos.z))
            cubeContainer.addChildNode(node)
            let isBlue = (i == blueIndex)
            if isBlue {
                box.materials = [blueMat, blueMat, blueMat, blueMat, blueMat, blueMat]
            }
            let cubie = Cubie(id: i, node: node, isBlue: isBlue)
            cubies.append(cubie)
        }
    }
    
    /// Returns the RL state as a string representing the blue cubie's index.
    func getBlueCornerState() -> String {
        if let blueCubie = cubies.first(where: { $0.isBlue }) {
            return "\(blueCubie.id)"
        }
        return "?"
    }
    
    /// Given an RL move, update the RL state (which is the index of the blue cubie) and update the colors.
    func performMove(_ move: CubeMove, record: Bool = true, completion: (() -> Void)? = nil) {
        // Do not animate the entire cube container.
        // Instead, update the RL state using the move's permutation mapping.
        let currentState = getBlueCornerState()  // e.g. "3"
        guard let index = Int(currentState) else { return }
        let perm = move.cornerPermutation
        let newIndex = perm[index]
        let newState = "\(newIndex)"
        
        // Now update the color assignment: set the cubie with canonical id equal to newState as blue,
        // and all others red. (The physical positions remain unchanged.)
        updateColors(for: newState)
        
        if record {
            moveHistory.append(move)
        }
        
        // Call the completion handler.
        completion?()
    }
    
    /// Update the color assignment: set cubie with given index as blue, others red.
    func updateColors(for state: String) {
        guard let blueIndex = Int(state) else { return }
        for cubie in cubies {
            let box = cubie.node.geometry as? SCNBox
            if cubie.id == blueIndex {
                let blueMat = SCNMaterial()
                blueMat.diffuse.contents = UIColor.blue
                box?.materials = [blueMat, blueMat, blueMat, blueMat, blueMat, blueMat]
                cubie.isBlue = true
            } else {
                let redMat = SCNMaterial()
                redMat.diffuse.contents = UIColor.red
                box?.materials = [redMat, redMat, redMat, redMat, redMat, redMat]
                cubie.isBlue = false
            }
        }
    }
    
    func randomizeCube() {
        guard !isAnimating else { return }
        // Instead of performing a move on cubies, we simply choose a random state and update colors.
        let randomIndex = Int.random(in: 0..<8)
        updateColors(for: "\(randomIndex)")
    }
    
    func animateSolution(moves: [CubeMove]) {
        guard !moves.isEmpty else { return }
        let first = moves.first!
        performMove(first, record: false) {
            let remaining = Array(moves.dropFirst())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateSolution(moves: remaining)
            }
        }
    }
}
