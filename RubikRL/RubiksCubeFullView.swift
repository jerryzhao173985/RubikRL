import SwiftUI
import SceneKit

struct RubiksCubeFullView: UIViewRepresentable {
    let cubeManager: CubeManager

    func makeUIView(context: Context) -> SCNView {
        let fixedFrame = CGRect(x: 0, y: 0, width: 430, height: 932)
        let scnView = SCNView(frame: fixedFrame)
        scnView.scene = cubeManager.scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.black
        scnView.antialiasingMode = .multisampling4X
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.debugOptions = [] // No debug options.
        print("makeUIView: SCNView fixed frame = \(scnView.frame)")
        print("CubeManager scene: \(cubeManager.scene)")
        print("Cube container child count: \(cubeManager.cubeContainer.childNodes.count)")
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        print("updateUIView called. SCNView frame: \(uiView.frame)")
        if let scene = uiView.scene {
            print("Scene root node child count: \(scene.rootNode.childNodes.count)")
        } else {
            print("Scene is nil!")
        }
    }
}
