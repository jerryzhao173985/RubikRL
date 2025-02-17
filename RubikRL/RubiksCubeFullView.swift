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
