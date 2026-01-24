import XCTest
@testable import PuzzleCoreKit

final class PuzzleCoreTests: XCTestCase {
    
    // MARK: - Rotation Tests
    
    func testRotationTransforms() {
        // Test L Shape rotation
        // Shape L: (0,0), (0,1), (1,0)
        let shape = PieceShape.shapeL
        let anchor = Cell(x: 2, y: 2)
        
        // 0 degrees
        let state0 = PieceState(anchor: anchor, rotation: .r0)
        let cells0 = PuzzleEngine.transformedCells(shape: shape, state: state0)
        // Expected: (2,2), (2,3), (3,2)
        XCTAssertTrue(cells0.contains(Cell(x: 2, y: 2)))
        XCTAssertTrue(cells0.contains(Cell(x: 2, y: 3)))
        XCTAssertTrue(cells0.contains(Cell(x: 3, y: 2)))
        
        // 90 degrees: (x,y) -> (-y, x)
        // (0,0)->(0,0), (0,1)->(-1,0), (1,0)->(0,1)
        // Anchor (2,2) -> (2,2), (1,2), (2,3)
        let state90 = PuzzleEngine.rotate(state0)
        XCTAssertEqual(state90.rotation, .r90)
        let cells90 = PuzzleEngine.transformedCells(shape: shape, state: state90)
        XCTAssertTrue(cells90.contains(Cell(x: 2, y: 2)))
        XCTAssertTrue(cells90.contains(Cell(x: 1, y: 2)))
        XCTAssertTrue(cells90.contains(Cell(x: 2, y: 3)))
        
        // 180 degrees: (x,y) -> (-x, -y)
        // (0,0)->(0,0), (0,1)->(0,-1), (1,0)->(-1,0)
        // Anchor (2,2) -> (2,2), (2,1), (1,2)
        let state180 = PuzzleEngine.rotate(state90)
        XCTAssertEqual(state180.rotation, .r180)
        let cells180 = PuzzleEngine.transformedCells(shape: shape, state: state180)
        XCTAssertTrue(cells180.contains(Cell(x: 2, y: 2)))
        XCTAssertTrue(cells180.contains(Cell(x: 2, y: 1)))
        XCTAssertTrue(cells180.contains(Cell(x: 1, y: 2)))
        
        // 270 degrees: (x,y) -> (y, -x)
        // (0,0)->(0,0), (0,1)->(1,0), (1,0)->(0,-1)
        // Anchor (2,2) -> (2,2), (3,2), (2,1)
        let state270 = PuzzleEngine.rotate(state180)
        XCTAssertEqual(state270.rotation, .r270)
        let cells270 = PuzzleEngine.transformedCells(shape: shape, state: state270)
        XCTAssertTrue(cells270.contains(Cell(x: 2, y: 2)))
        XCTAssertTrue(cells270.contains(Cell(x: 3, y: 2)))
        XCTAssertTrue(cells270.contains(Cell(x: 2, y: 1)))
        
        // Back to 0
        let state360 = PuzzleEngine.rotate(state270)
        XCTAssertEqual(state360.rotation, .r0)
    }
    
    // MARK: - Grid Tests

    func testGridStateLocking() {
        var grid = GridState(size: GridSize(width: 4, height: 4))
        
        // Initially empty
        XCTAssertFalse(grid.isOccupied(at: Cell(x: 0, y: 0)))
        XCTAssertFalse(grid.isOccupied(at: Cell(x: 3, y: 3)))
        
        // Lock some cells
        let cellsToLock = [Cell(x: 1, y: 1), Cell(x: 2, y: 2)]
        grid.lock(cells: cellsToLock)
        
        // Verify locked
        XCTAssertTrue(grid.isOccupied(at: Cell(x: 1, y: 1)))
        XCTAssertTrue(grid.isOccupied(at: Cell(x: 2, y: 2)))
        
        // Verify others still empty
        XCTAssertFalse(grid.isOccupied(at: Cell(x: 0, y: 0)))
        XCTAssertFalse(grid.isOccupied(at: Cell(x: 1, y: 2)))
    }
    
    func testTShapeRotation() {
        // T Shape: (0,0), (1,0), (2,0), (1,1)
        // Center-ish is (1,0) if we consider bounding box? No, anchor is (0,0).
        let shape = PieceShape.shapeT
        let anchor = Cell(x: 1, y: 1)
        
        // 0 deg: (1,1), (2,1), (3,1), (2,2)
        let state0 = PieceState(anchor: anchor, rotation: .r0)
        let cells0 = PuzzleEngine.transformedCells(shape: shape, state: state0)
        XCTAssertTrue(cells0.contains(Cell(x: 1, y: 1)))
        XCTAssertTrue(cells0.contains(Cell(x: 2, y: 1)))
        XCTAssertTrue(cells0.contains(Cell(x: 3, y: 1)))
        XCTAssertTrue(cells0.contains(Cell(x: 2, y: 2)))
        
        // 90 deg: (x,y) -> (-y, x)
        // (0,0)->(0,0), (1,0)->(0,1), (2,0)->(0,2), (1,1)->(-1,1)
        // Anchor (1,1) -> (1,1), (1,2), (1,3), (0,2)
        let state90 = PuzzleEngine.rotate(state0)
        let cells90 = PuzzleEngine.transformedCells(shape: shape, state: state90)
        XCTAssertTrue(cells90.contains(Cell(x: 1, y: 1)))
        XCTAssertTrue(cells90.contains(Cell(x: 1, y: 2)))
        XCTAssertTrue(cells90.contains(Cell(x: 1, y: 3)))
        XCTAssertTrue(cells90.contains(Cell(x: 0, y: 2)))
    }

    // MARK: - Validation Tests
    
    func testValidationBounds() {
        let grid = GridState() // 4x4
        let shape = PieceShape.shapeL // (0,0), (0,1), (1,0)
        
        // Valid placement at (0,0)
        let validState = PieceState(anchor: Cell(x: 0, y: 0), rotation: .r0)
        let validCells = PuzzleEngine.transformedCells(shape: shape, state: validState)
        XCTAssertTrue(PuzzleEngine.validate(grid: grid, cells: validCells))
        
        // Invalid placement (out of bounds)
        // Anchor at (3,3) -> cells (3,3), (3,4), (4,3) -> (3,4) and (4,3) are OOB
        let invalidState = PieceState(anchor: Cell(x: 3, y: 3), rotation: .r0)
        let invalidCells = PuzzleEngine.transformedCells(shape: shape, state: invalidState)
        XCTAssertFalse(PuzzleEngine.validate(grid: grid, cells: invalidCells))
        
        // Anchor at (-1, 0) -> (-1,0) is OOB
        let invalidState2 = PieceState(anchor: Cell(x: -1, y: 0), rotation: .r0)
        let invalidCells2 = PuzzleEngine.transformedCells(shape: shape, state: invalidState2)
        XCTAssertFalse(PuzzleEngine.validate(grid: grid, cells: invalidCells2))
    }
    
    func testValidationOverlap() {
        var grid = GridState()
        // Lock (0,0)
        grid.lock(cells: [Cell(x: 0, y: 0)])
        
        let shape = PieceShape.shapeL // (0,0), (0,1), (1,0)
        
        // Try to place L at (0,0) -> overlaps at (0,0)
        let state = PieceState(anchor: Cell(x: 0, y: 0), rotation: .r0)
        let cells = PuzzleEngine.transformedCells(shape: shape, state: state)
        XCTAssertFalse(PuzzleEngine.validate(grid: grid, cells: cells))
        
        // Place L at (1,1) -> (1,1), (1,2), (2,1) -> Valid
        let state2 = PieceState(anchor: Cell(x: 1, y: 1), rotation: .r0)
        let cells2 = PuzzleEngine.transformedCells(shape: shape, state: state2)
        XCTAssertTrue(PuzzleEngine.validate(grid: grid, cells: cells2))
    }
    
    // MARK: - Determinism & Snapping Tests
    
    func testSnapCandidate() {
        // Test rounding
        let c1 = PuzzleEngine.snapCandidate(x: 1.2, y: 1.2, rotation: .r0)
        XCTAssertEqual(c1.anchor, Cell(x: 1, y: 1))
        
        let c2 = PuzzleEngine.snapCandidate(x: 1.8, y: 1.8, rotation: .r0)
        XCTAssertEqual(c2.anchor, Cell(x: 2, y: 2))
        
        // Deterministic
        XCTAssertEqual(PuzzleEngine.snapCandidate(x: 1.2, y: 1.2, rotation: .r0), c1)
    }
    
    func testApplyPlacement() {
        let grid = GridState()
        let shape = PieceShape.shapeL
        
        // Valid snap
        let candidate = PieceState(anchor: Cell(x: 0, y: 0), rotation: .r0)
        let fallback = PieceState(anchor: Cell(x: 10, y: 10), rotation: .r0) // Invalid fallback
        
        let result = PuzzleEngine.applyPlacement(grid: grid, shape: shape, candidate: candidate, fallback: fallback)
        if case .valid(let snapped) = result {
            XCTAssertEqual(snapped, candidate)
        } else {
            XCTFail("Should be valid")
        }
        
        // Invalid snap (OOB)
        let candidateInvalid = PieceState(anchor: Cell(x: 3, y: 3), rotation: .r0)
        let resultInvalid = PuzzleEngine.applyPlacement(grid: grid, shape: shape, candidate: candidateInvalid, fallback: fallback)
        if case .invalid(let returned) = resultInvalid {
            XCTAssertEqual(returned, fallback)
        } else {
            XCTFail("Should be invalid")
        }
    }
}
