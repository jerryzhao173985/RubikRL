import SceneKit
import SwiftUI

class CubeManager: ObservableObject {
    let scene: SCNScene
    let cubeContainer: SCNNode  // Container node for the cube.
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
                    // Two colors: red for front, back, top; blue for right, left, bottom.
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

    // Fallback function: animate the sequence of moves.
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

    /// In our reduced corner representation, we simply represent the state by the y-coordinate.
    /// For example, if a cubie’s y > 0, output "0" (top) else "1" (bottom).
    func getCornerState() -> String {
        let sortedCubies = cubies.sorted { $0.id < $1.id }
        let state = sortedCubies.map { cubie -> String in
            return (cubie.logicalPosition.y > 0) ? "0" : "1"
        }
        return state.joined()
    }
}
