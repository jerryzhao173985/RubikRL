import SceneKit
import SwiftUI

class CubeManager: ObservableObject {
    let scene: SCNScene
    let cubeContainer: SCNNode
    var cubies: [Cubie] = []
    var sizeX: Int
    var sizeY: Int
    var sizeZ: Int
    var moveHistory: [CubeAction] = []
    var isAnimating = false
    
    @Published var activeAction: CubeAction? = nil
    let settings: CubeSettings
    
    init(settings: CubeSettings) {
        self.settings = settings
        self.sizeX = settings.sizeX
        self.sizeY = settings.sizeY
        self.sizeZ = settings.sizeZ
        scene = SCNScene()
        cubeContainer = SCNNode()
        scene.rootNode.addChildNode(cubeContainer)
        setupCameraAndLights()
        buildCube(initialBlue: settings.initialBlue)
        updateIndexLabels()
    }
    
    private func setupCameraAndLights() {
        // Use the maximum dimension for camera distance.
        let d = Double(max(sizeX, sizeY, sizeZ))
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(Float(d), Float(d), Float(d))
        let constraint = SCNLookAtConstraint(target: cubeContainer)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        scene.rootNode.addChildNode(cameraNode)
        
        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.position = SCNVector3(Float(d * 1.5), Float(d * 1.5), Float(d * 1.5))
        scene.rootNode.addChildNode(omniLight)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLight)
    }
    
    private func buildCube(initialBlue: Int?) {
        cubies.removeAll()
        let total = sizeX * sizeY * sizeZ
        let blueIndex = initialBlue ?? Int.random(in: 0..<total)
        print("Building cube of size \(sizeX)x\(sizeY)x\(sizeZ); total cubies: \(total), blueIndex: \(blueIndex)")
        // Canonical ordering: for z in 0..<sizeZ, for y in 0..<sizeY, for x in 0..<sizeX.
        // Linear index = x + sizeX*y + sizeX*sizeY*z.
        let offsetX = Double(sizeX - 1) / 2.0
        let offsetY = Double(sizeY - 1) / 2.0
        let offsetZ = Double(sizeZ - 1) / 2.0
        for z in 0..<sizeZ {
            for y in 0..<sizeY {
                for x in 0..<sizeX {
                    let index = x + sizeX * y + sizeX * sizeY * z
                    let posX = Double(x) - offsetX
                    let posY = Double(y) - offsetY
                    let posZ = Double(z) - offsetZ
                    let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.05)
                    let redMat = SCNMaterial(); redMat.diffuse.contents = UIColor.red
                    let blueMat = SCNMaterial(); blueMat.diffuse.contents = UIColor.blue
                    // For the goal cubie, we want a distinct color (say green) if it is not blue.
                    let goalIndex = settings.goal ?? 1
                    box.materials = [redMat, redMat, redMat, redMat, redMat, redMat]
                    let node = SCNNode(geometry: box)
                    node.position = SCNVector3(Float(posX), Float(posY), Float(posZ))
                    cubeContainer.addChildNode(node)
                    var isBlue = (index == blueIndex)
                    // If not blue and if this cubie is the goal, highlight it.
                    if !isBlue && index == goalIndex {
                        let greenMat = SCNMaterial()
                        greenMat.diffuse.contents = UIColor.green
                        box.materials = [greenMat, greenMat, greenMat, greenMat, greenMat, greenMat]
                    }
                    if isBlue {
                        box.materials = [blueMat, blueMat, blueMat, blueMat, blueMat, blueMat]
                    }
                    let cubie = Cubie(id: index, node: node, isBlue: isBlue)
                    cubies.append(cubie)
                }
            }
        }
        print("Cube built: cubeContainer has \(cubeContainer.childNodes.count) children")
    }
    
    func getBlueCornerState() -> String {
        if let blueCubie = cubies.first(where: { $0.isBlue }) {
            return "\(blueCubie.id)"
        }
        return "?"
    }
    
    /// Add a label (SCNText) on each cubie showing its canonical index.
    func updateIndexLabels() {
        for cubie in cubies {
            cubie.node.childNodes.filter { $0.name == "indexLabel" }.forEach { $0.removeFromParentNode() }
            let textGeometry = SCNText(string: "\(cubie.id)", extrusionDepth: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.font = UIFont.systemFont(ofSize: 0.3)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.name = "indexLabel"
            textNode.scale = SCNVector3(0.2, 0.2, 0.2)
            // Position the label on one face (e.g., above the cube)
            textNode.position = SCNVector3(0, 0.6, 0)
            cubie.node.addChildNode(textNode)
        }
    }
    
    /// Update colors based on the new RL state.
    func updateColors(for state: String) {
        guard let blueIndex = Int(state) else { return }
        let goalIndex = settings.goal ?? 1
        for cubie in cubies {
            let box = cubie.node.geometry as? SCNBox
            if cubie.id == blueIndex {
                let blueMat = SCNMaterial()
                blueMat.diffuse.contents = UIColor.blue
                box?.materials = [blueMat, blueMat, blueMat, blueMat, blueMat, blueMat]
                cubie.isBlue = true
            } else if cubie.id == goalIndex {
                // Highlight the goal cubie with green (if it’s not blue).
                let greenMat = SCNMaterial()
                greenMat.diffuse.contents = UIColor.green
                box?.materials = [greenMat, greenMat, greenMat, greenMat, greenMat, greenMat]
                cubie.isBlue = false
            } else {
                let redMat = SCNMaterial()
                redMat.diffuse.contents = UIColor.red
                box?.materials = [redMat, redMat, redMat, redMat, redMat, redMat]
                cubie.isBlue = false
            }
        }
        // Update the index labels (so they always show the correct canonical index).
        updateIndexLabels()
    }
    
    /// Perform an action (a slice rotation) that updates the RL state.
    func performAction(_ action: CubeAction, currentState: String? = nil, record: Bool = true, completion: (() -> Void)? = nil) {
        let state = currentState ?? getBlueCornerState()
        guard let index = Int(state) else { return }
        let X = sizeX, Y = sizeY, Z = sizeZ
        let i = index % X
        let j = (index / X) % Y
        let k = index / (X * Y)
        let newCoord = action.transform(state: (i, j, k), dims: (X: X, Y: Y, Z: Z))
        let newIndex = newCoord.i + X * newCoord.j + X * Y * newCoord.k
        let newState = "\(newIndex)"
        updateColors(for: newState)
        if record { moveHistory.append(action) }
        completion?()
    }
    
    /// Previous "Randomize" to any initial state possible with random index
    func randomizeCube() {
        let total = sizeX * sizeY * sizeZ
        let randomIndex = Int.random(in: 0..<total)
        updateColors(for: "\(randomIndex)")
    }
    
    /// “Random” Button Scramble:
    /// Instead of directly setting a random blue index, the “Random” button now calls a new function that applies (by default) 20 random actions to scramble the cube.
    /// This makes the test initial state more realistic.
    func scrambleCube(steps: Int = 20) {
        // Check if the current blue state is "?"
        if getBlueCornerState() == "?" {
            let goalState = settings.goal.map { "\($0)" } ?? "1"
            print("Current blue state is '?'. Resetting to goal state \(goalState)")
            updateColors(for: goalState)
        }
        // Now perform a scramble: apply a sequence of random actions.
        let actions = allCubeActions(forCubeSize: sizeX) // Use sizeX (assuming canonical ordering)
        for _ in 0..<steps {
            let randomAction = actions.randomElement()!
            performAction(randomAction, record: false, completion: nil)
        }
    }
    
    func animateSolution(moves: [CubeAction]) {
        guard !moves.isEmpty else { return }
        let first = moves.first!
        performAction(first, record: false) {
            let remaining = Array(moves.dropFirst())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateSolution(moves: remaining)
            }
        }
    }
}
