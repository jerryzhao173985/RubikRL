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
