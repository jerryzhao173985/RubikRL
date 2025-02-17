import Foundation

struct CubeAction: Identifiable, Equatable, Hashable, CustomStringConvertible {
    let id = UUID()
    let axis: String    // "x", "y", or "z"
    let layer: Int      // slice index (0 .. dimension-1)
    let direction: Int  // +1 for clockwise, -1 for anticlockwise
    
    /// Given a cubie’s coordinate (i, j, k) and full dimensions (X, Y, Z),
    /// if the cubie is in the affected slice (its coordinate along the axis equals layer),
    /// apply a 90° cyclic rotation on the two coordinates of that face.
    func transform(state: (i: Int, j: Int, k: Int), dims: (X: Int, Y: Int, Z: Int)) -> (i: Int, j: Int, k: Int) {
        var (i, j, k) = state
        switch axis {
        case "x":
            if i == layer {
                if direction == 1 {
                    let newJ = k
                    let newK = dims.Z - 1 - j
                    j = newJ; k = newK
                } else {
                    let newJ = dims.Z - 1 - k
                    let newK = j
                    j = newJ; k = newK
                }
            }
        case "y":
            if j == layer {
                if direction == 1 {
                    let newI = k
                    let newK = dims.Z - 1 - i
                    i = newI; k = newK
                } else {
                    let newI = dims.Z - 1 - k
                    let newK = i
                    i = newI; k = newK
                }
            }
        case "z":
            if k == layer {
                if direction == 1 {
                    let newI = j
                    let newJ = dims.Y - 1 - i
                    i = newI; j = newJ
                } else {
                    let newI = dims.Y - 1 - j
                    let newJ = i
                    i = newI; j = newJ
                }
            }
        default:
            break
        }
        return (i, j, k)
    }
    
    var description: String {
        return "\(axis.uppercased())\(layer)\(direction == 1 ? "" : "Prime")"
    }
}

func allCubeActions(forCubeSize n: Int) -> [CubeAction] {
    var actions: [CubeAction] = []
    for axis in ["x", "y", "z"] {
        for layer in 0..<n {
            actions.append(CubeAction(axis: axis, layer: layer, direction: 1))
            actions.append(CubeAction(axis: axis, layer: layer, direction: -1))
        }
    }
    return actions
}
