import SwiftUI

struct ContentView: View {
    @StateObject private var cubeManager = CubeManager()
    @StateObject private var rlAgent = RLAgent2x2()
    
    var body: some View {
        VStack {
            RubiksCubeFullView(cubeManager: cubeManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 20) {
                Text("Episode: \(rlAgent.currentEpisode) / \(rlAgent.totalEpisodes)")
                    .foregroundColor(.white)
                    .font(.headline)
                Text("Max Reward: \(String(format: "%.2f", rlAgent.maxReward))")
                    .foregroundColor(.white)
                    .font(.headline)
                HStack(spacing: 30) {
                    Button(action: {
                        cubeManager.randomizeCube()
                    }) {
                        Text("Random")
                            .font(.title2)
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
                            .font(.title2)
                            .padding()
                            .background(rlAgent.isTraining ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(rlAgent.isTraining)
                    Button(action: {
                        let currentState = cubeManager.getCornerState()
                        print("Current corner state: \(currentState)")
                        let solution = rlAgent.getSolution(from: currentState, maxDepth: 50)
                        print("RL solution: \(solution.map { $0.rawValue })")
                        rlAgent.printQStatistics()
                        cubeManager.animateSolution(moves: solution)
                    }) {
                        Text("Run")
                            .font(.title2)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .onAppear {
                // Optionally update debug labels after each move.
                cubeManager.updateDebugLabels()
            }
            .padding()
            .background(Color.black)
            .frame(height: 160)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
