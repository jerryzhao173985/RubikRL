import SceneKit

class Cubie {
    let id: Int          // The solved corner ID (0...7).
    let node: SCNNode
    var orientation: Int // 0, 1, or 2.
    
    init(id: Int, node: SCNNode, orientation: Int = 0) {
        self.id = id
        self.node = node
        self.orientation = orientation
    }
}
