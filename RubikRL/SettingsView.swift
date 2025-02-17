import SwiftUI

struct SettingsView: View {
    @Binding var settings: CubeSettings
    @State private var sizeX: Int = 2
    @State private var sizeY: Int = 2
    @State private var sizeZ: Int = 2
    @State private var initialBlueText: String = ""
    @State private var goalText: String = "1"
    
    var body: some View {
        Form {
            Section(header: Text("Cube Dimensions")) {
                Stepper("X: \(sizeX)", value: $sizeX, in: 2...5)
                Stepper("Y: \(sizeY)", value: $sizeY, in: 2...5)
                Stepper("Z: \(sizeZ)", value: $sizeZ, in: 2...5)
            }
            Section(header: Text("Optional: Initial Blue Position (0 .. \(sizeX * sizeY * sizeZ - 1))")) {
                TextField("Initial Blue", text: $initialBlueText)
                    .keyboardType(.numberPad)
            }
            Section(header: Text("Optional: Goal Position (0 .. \(sizeX * sizeY * sizeZ - 1))")) {
                TextField("Goal", text: $goalText)
                    .keyboardType(.numberPad)
            }
        }
        .onAppear {
            sizeX = settings.sizeX
            sizeY = settings.sizeY
            sizeZ = settings.sizeZ
            if let ib = settings.initialBlue {
                initialBlueText = "\(ib)"
            }
            if let goal = settings.goal {
                goalText = "\(goal)"
            }
        }
        .onDisappear {
            settings.sizeX = sizeX
            settings.sizeY = sizeY
            settings.sizeZ = sizeZ
            settings.initialBlue = Int(initialBlueText)
            settings.goal = Int(goalText)
        }
    }
}
