import SwiftUI

struct ContentView: View {
    @State private var settings = CubeSettings()
    @State private var showSimulation = false
    
    var body: some View {
        NavigationView {
            VStack {
                SettingsView(settings: $settings)
                Button("Start Simulation") {
                    showSimulation = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                NavigationLink(destination: SimulationView(settings: settings), isActive: $showSimulation) {
                    EmptyView()
                }
            }
            .navigationTitle("Cube Settings")
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
