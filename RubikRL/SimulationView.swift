import SwiftUI

struct SimulationView: View {
    let settings: CubeSettings
    @StateObject private var cubeManager: CubeManager
    @StateObject private var rlAgent: RLAgentSimple
    
    init(settings: CubeSettings) {
        self.settings = settings
        let manager = CubeManager(settings: settings)
        _cubeManager = StateObject(wrappedValue: manager)
        var config = RLConfig()
        // For RL parameters we use the minimum dimension.
        config.size = min(settings.sizeX, settings.sizeY, settings.sizeZ)
        let dims = (X: settings.sizeX, Y: settings.sizeY, Z: settings.sizeZ)
        _rlAgent = StateObject(wrappedValue: RLAgentSimple(config: config, dims: dims))
    }
    
    var body: some View {
        ZStack {
            RubiksCubeFullView(cubeManager: cubeManager)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                VStack(spacing: 20) {
                    Text("Episode: \(rlAgent.currentEpisode) / \(rlAgent.totalEpisodes)")
                        .foregroundColor(.white)
                    Text("Max Reward: \(String(format: "%.2f", rlAgent.maxReward))")
                        .foregroundColor(.white)
                    HStack(spacing: 30) {
                        Button(action: {
//                            cubeManager.randomizeCube()
                            cubeManager.scrambleCube(steps: 20)
                        }) {
                            Text("Random")
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Button(action: {
                            rlAgent.startTraining(environment: cubeManager) {
                                print("Training converged or stopped.")
                            }
                        }) {
                            Text("Learn")
                                .padding()
                                .background(rlAgent.isTraining ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(rlAgent.isTraining)
                        Button(action: {
                            let currentState = cubeManager.getBlueCornerState()
                            print("Current blue corner state: \(currentState)")
                            let solution = rlAgent.getSolution(from: currentState, maxDepth: rlAgent.config.maxSteps)
                            print("RL solution: \(solution.map { $0.description })")
                            cubeManager.animateSolution(moves: solution)
                        }) {
                            Text("Run")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
            }
        }
        .onAppear {
            print("SimulationView onAppear: Layout updated.")
        }
        .preferredColorScheme(.dark)
    }
}

struct SimulationView_Previews: PreviewProvider {
    static var previews: some View {
        SimulationView(settings: CubeSettings())
    }
}
