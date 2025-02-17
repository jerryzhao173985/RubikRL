import SceneKit

class Cubie {
    let id: Int       // Canonical corner index.
    let node: SCNNode
    var isBlue: Bool  // true if this cubie is blue.
    
    init(id: Int, node: SCNNode, isBlue: Bool = false) {
        self.id = id
        self.node = node
        self.isBlue = isBlue
    }
}
