import SceneKit
import SwiftUI

class CubeManager: ObservableObject {
    let scene: SCNScene
    let cubeContainer: SCNNode
    var cubies: [Cubie] = []
    // For visualization, we still place them according to their positions.
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
        // Canonical ordering:
        // 0: front-top-left, 1: front-top-right, 2: front-bottom-left, 3: front-bottom-right,
        // 4: back-top-left, 5: back-top-right, 6: back-bottom-left, 7: back-bottom-right.
        let positionsOrdered: [(x: Double, y: Double, z: Double)] = [
            (-0.5, 0.5, 0.5),  // 0
            (0.5, 0.5, 0.5),   // 1
            (-0.5, -0.5, 0.5), // 2
            (0.5, -0.5, 0.5),  // 3
            (-0.5, 0.5, -0.5), // 4
            (0.5, 0.5, -0.5),  // 5
            (-0.5, -0.5, -0.5),// 6
            (0.5, -0.5, -0.5)  // 7
        ]
        
        for i in 0..<positionsOrdered.count {
            let pos = positionsOrdered[i]
            let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.01)
            let redMat = SCNMaterial(); redMat.diffuse.contents = UIColor.red
            let blueMat = SCNMaterial(); blueMat.diffuse.contents = UIColor.blue
            box.materials = [redMat, blueMat, redMat, blueMat, redMat, blueMat]
            
            let node = SCNNode(geometry: box)
            node.position = SCNVector3(Float(pos.x), Float(pos.y), Float(pos.z))
            cubeContainer.addChildNode(node)
            let cubie = Cubie(id: i, node: node, orientation: 0)
            cubies.append(cubie)
        }
    }
    
    /// Returns a compact 16-character state string representing the corners.
    /// For each cubie (sorted by solved id 0...7), we encode as two digits: first digit = id, second digit = orientation.
    func getCornerState() -> String {
        let sortedCubies = cubies.sorted { $0.id < $1.id }
        var state = ""
        for cubie in sortedCubies {
            state += "\(cubie.id)\(cubie.orientation)"
        }
        return state
    }
    
    func performMove(_ move: CubeMove, record: Bool = true, completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        DispatchQueue.main.async { self.activeMove = move }
        
        // For visualization we use physical positions (not used for RL state).
        let layer = move.affectedLayer
        let affectedCubies = cubies.filter { cubie in
            switch layer.axis {
            case "x": return cubie.node.position.x == Float(layer.value)
            case "y": return cubie.node.position.y == Float(layer.value)
            case "z": return cubie.node.position.z == Float(layer.value)
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
            // In a complete implementation, physical positions and orientations are updated.
            // For RL, we update the cubies' orientation values.
            for cubie in affectedCubies {
                let delta = move.cornerOrientationDelta[cubie.id]
                cubie.orientation = (cubie.orientation + delta) % 3
            }
            groupNode.removeFromParentNode()
            if record { self.moveHistory.append(move) }
            self.isAnimating = false
            DispatchQueue.main.async { self.activeMove = nil }
            completion?()
        }
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
    
    // For debugging: add labels to each cubie showing its state.
    func updateDebugLabels() {
        for cubie in cubies {
            // Remove existing text nodes.
            cubie.node.childNodes.filter { $0.name == "debugLabel" }.forEach { $0.removeFromParentNode() }
            let textGeometry = SCNText(string: "\(cubie.id),\(cubie.orientation)", extrusionDepth: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.font = UIFont.systemFont(ofSize: 0.2)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.name = "debugLabel"
            // Scale and position text so it sits on the cubie.
            textNode.scale = SCNVector3(0.2, 0.2, 0.2)
            textNode.position = SCNVector3(0, 0.6, 0)  // adjust as needed.
            cubie.node.addChildNode(textNode)
        }
    }
}
