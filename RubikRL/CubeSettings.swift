struct CubeSettings {
    var sizeX: Int = 2  // Range: 2–5
    var sizeY: Int = 2  // Range: 2–5
    var sizeZ: Int = 2  // Range: 2–5
    var initialBlue: Int? = nil   // Optional; if nil, randomize.
    var goal: Int? = nil          // Optional; if nil, default is 1.
    
    // You can add computed properties if needed.
}
