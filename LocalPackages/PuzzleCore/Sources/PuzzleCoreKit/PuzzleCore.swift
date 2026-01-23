import Foundation

// MARK: - Types

public struct GridSize: Sendable {
    public let width: Int
    public let height: Int
    
    public static let standard = GridSize(width: 4, height: 4)
}

public struct Cell: Hashable, Equatable, CustomStringConvertible, Sendable {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    public var description: String {
        return "(\(x), \(y))"
    }
}

public enum Rotation: Int, CaseIterable, Sendable {
    case r0 = 0
    case r90 = 90
    case r180 = 180
    case r270 = 270
    
    public func rotated() -> Rotation {
        switch self {
        case .r0: return .r90
        case .r90: return .r180
        case .r180: return .r270
        case .r270: return .r0
        }
    }
}

public struct PieceShape: Sendable {
    /// Local coordinates relative to an anchor (0,0)
    public let localCells: [Cell]
    
    public init(localCells: [Cell]) {
        self.localCells = localCells
    }
    
    public static let shapeL = PieceShape(localCells: [
        Cell(x: 0, y: 0), Cell(x: 0, y: 1), Cell(x: 1, y: 0) // Simple L
    ])
    
    public static let shapeT = PieceShape(localCells: [
        Cell(x: 0, y: 0), Cell(x: 1, y: 0), Cell(x: 2, y: 0), Cell(x: 1, y: 1) // T shape
    ])
}

public struct PieceState: Equatable, Sendable {
    public let anchor: Cell
    public let rotation: Rotation
    
    public init(anchor: Cell, rotation: Rotation) {
        self.anchor = anchor
        self.rotation = rotation
    }
}

public struct GridState: Sendable {
    // 4x4 grid flattened: index = y * width + x
    private var occupied: [Bool]
    public let size: GridSize
    
    public init(size: GridSize = .standard) {
        self.size = size
        self.occupied = Array(repeating: false, count: size.width * size.height)
    }
    
    public func isOccupied(at cell: Cell) -> Bool {
        guard contains(cell) else { return false }
        return occupied[cell.y * size.width + cell.x]
    }
    
    public mutating func lock(cells: [Cell]) {
        for cell in cells {
            if contains(cell) {
                occupied[cell.y * size.width + cell.x] = true
            }
        }
    }
    
    public func contains(_ cell: Cell) -> Bool {
        return cell.x >= 0 && cell.x < size.width && cell.y >= 0 && cell.y < size.height
    }
}

public enum PlacementResult: Equatable, Sendable {
    case valid(snappedState: PieceState)
    case invalid(returnTo: PieceState) // Could be origin or last valid
}

// MARK: - Logic Functions

public struct PuzzleEngine {
    
    public static func rotate(_ state: PieceState) -> PieceState {
        return PieceState(anchor: state.anchor, rotation: state.rotation.rotated())
    }
    
    /// Transforms local cells based on rotation and anchor.
    /// Rotation logic: Rotate around (0,0) then translate to anchor.
    /// 90 deg clockwise: (x, y) -> (y, -x) ?
    /// Let's use standard 2D rotation matrix for clockwise:
    /// x' = x cos(t) + y sin(t)
    /// y' = -x sin(t) + y cos(t)
    /// For 90 deg (t=-90 in standard math if y is up? or t=90 if y is down?
    /// Let's assume grid: x right, y down (standard UI).
    /// Clockwise 90: (1, 0) -> (0, 1). (0, 1) -> (-1, 0).
    /// x' = -y
    /// y' = x
    /// Wait, (1,0) is x=1. Rot 90 CW -> x=0, y=1.
    /// (0,1) is y=1. Rot 90 CW -> x=-1, y=0.
    /// So: x' = -y, y' = x.
    /// Let's verify 180: x'' = -y' = -x, y'' = x' = -y. Correct.
    public static func transformedCells(shape: PieceShape, state: PieceState) -> [Cell] {
        return shape.localCells.map { cell in
            var rx = cell.x
            var ry = cell.y
            
            switch state.rotation {
            case .r0:
                break
            case .r90:
                (rx, ry) = (-ry, rx)
            case .r180:
                (rx, ry) = (-rx, -ry)
            case .r270:
                (rx, ry) = (ry, -rx)
            }
            
            return Cell(x: state.anchor.x + rx, y: state.anchor.y + ry)
        }
    }
    
    public static func validate(grid: GridState, cells: [Cell]) -> Bool {
        for cell in cells {
            // Check bounds
            if !grid.contains(cell) {
                return false
            }
            // Check overlap
            if grid.isOccupied(at: cell) {
                return false
            }
        }
        return true
    }
    
    /// Snaps a continuous position to the nearest anchor cell.
    /// - Parameters:
    ///   - x: Continuous x (grid space, 1.0 = 1 cell width)
    ///   - y: Continuous y
    ///   - threshold: Max distance to center to consider a snap (optional, if we want strict snapping)
    ///   - currentRotation: The current rotation of the piece
    /// - Returns: A candidate PieceState (snapped to nearest integer coordinates)
    public static func snapCandidate(x: Float, y: Float, rotation: Rotation) -> PieceState {
        let ix = Int(round(x))
        let iy = Int(round(y))
        return PieceState(anchor: Cell(x: ix, y: iy), rotation: rotation)
    }
    
    /// Attempts to apply a placement.
    public static func applyPlacement(
        grid: GridState,
        shape: PieceShape,
        candidate: PieceState,
        fallback: PieceState
    ) -> PlacementResult {
        let cells = transformedCells(shape: shape, state: candidate)
        if validate(grid: grid, cells: cells) {
            return .valid(snappedState: candidate)
        } else {
            return .invalid(returnTo: fallback)
        }
    }
}
