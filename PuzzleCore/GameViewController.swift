import UIKit
import SceneKit
import PuzzleCoreKit

class GameViewController: UIViewController {
    
    // MARK: - Constants & Tuning
    
    private let cellSize: Float = 1.0
    private let dragPlaneY: Float = 0.5 // Lift piece slightly when dragging
    private let snapThreshold: Float = 0.5 // Distance to snap
    
    // MARK: - Scene Properties
    
    private var scnView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!
    private var gridNode: SCNNode!
    private var pieceNode: SCNNode!
    
    // MARK: - Game State
    
    private var gridState = GridState()
    private var currentPieceShape = PieceShape.shapeL // Start with L
    private var currentPieceState = PieceState(anchor: Cell(x: -2, y: 1), rotation: .r0) // Start outside
    private var lastValidState: PieceState?
    
    private var isDragging = false
    private var startDragLocation: CGPoint = .zero
    private var pieceDragOffset: SCNVector3 = SCNVector3(0, 0, 0)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupGrid()
        spawnPiece()
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupScene() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = false // We handle gestures
        view.addSubview(scnView)
        
        scene = SCNScene()
        scnView.scene = scene
        
        // Camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(2, 6, 8) // Look down at angle
        cameraNode.look(at: SCNVector3(2, 0, 2)) // Look at center of 4x4 grid (approx)
        scene.rootNode.addChildNode(cameraNode)
        
        // Light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(2, 10, 2)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)
    }
    
    private func setupGrid() {
        gridNode = SCNNode()
        
        // 4x4 Grid
        // Visual representation: Checkers or lines
        let floorGeo = SCNPlane(width: CGFloat(4 * cellSize), height: CGFloat(4 * cellSize))
        floorGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.eulerAngles.x = -.pi / 2
        floorNode.position = SCNVector3(1.5, 0, 1.5) // Center (0..3, 0..3) is at (1.5, 1.5)
        gridNode.addChildNode(floorNode)
        
        // Draw cells
        for x in 0..<4 {
            for y in 0..<4 {
                let box = SCNBox(width: CGFloat(cellSize * 0.95), height: 0.1, length: CGFloat(cellSize * 0.95), chamferRadius: 0.02)
                box.firstMaterial?.diffuse.contents = UIColor.gray.withAlphaComponent(0.5)
                let node = SCNNode(geometry: box)
                node.position = gridToWorld(Cell(x: x, y: y), yOffset: -0.05)
                gridNode.addChildNode(node)
            }
        }
        
        scene.rootNode.addChildNode(gridNode)
    }
    
    private func spawnPiece() {
        pieceNode?.removeFromParentNode()
        pieceNode = createPieceNode(shape: currentPieceShape, color: .orange)
        updatePieceTransform(state: currentPieceState, animated: false)
        scene.rootNode.addChildNode(pieceNode)
        
        // Initial valid state is the start state (assuming it's valid outside or we don't check outside validity strictly yet)
        lastValidState = currentPieceState
    }
    
    private func createPieceNode(shape: PieceShape, color: UIColor) -> SCNNode {
        let container = SCNNode()
        for cell in shape.localCells {
            let box = SCNBox(width: CGFloat(cellSize), height: 0.2, length: CGFloat(cellSize), chamferRadius: 0.05)
            box.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: box)
            // Local position relative to anchor
            node.position = SCNVector3(Float(cell.x) * cellSize, 0, Float(cell.y) * cellSize)
            container.addChildNode(node)
        }
        return container
    }
    
    // MARK: - Helpers
    
    private func gridToWorld(_ cell: Cell, yOffset: Float = 0) -> SCNVector3 {
        return SCNVector3(Float(cell.x) * cellSize, yOffset, Float(cell.y) * cellSize)
    }
    
    private func worldToGrid(_ pos: SCNVector3) -> (x: Float, y: Float) {
        // Inverse of gridToWorld
        // x_world = x_grid * cellSize
        // z_world = y_grid * cellSize
        return (pos.x / cellSize, pos.z / cellSize)
    }
    
    private func updatePieceTransform(state: PieceState, animated: Bool) {
        let targetPos = gridToWorld(state.anchor, yOffset: isDragging ? dragPlaneY : 0)
        // Rotation
        // Rotation enum is degrees. SceneKit uses radians.
        // We rotate around the anchor (0,0 of the piece node)
        // Note: Our PieceShape localCells are relative to anchor.
        // PieceState rotation means we rotate the whole piece around Y.
        let angle = Float(state.rotation.rawValue) * .pi / 180.0
        
        // Animation
        if animated {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
        }
        
        pieceNode.position = targetPos
        // Rotate around Y axis. Note: SceneKit rotation is counter-clockwise positive usually?
        // PuzzleCore rotation is 0, 90, 180, 270.
        // If we map 90 -> -90 (CW) or check visual.
        // Let's assume standard Y-up, negative rotation for CW.
        pieceNode.eulerAngles.y = -angle 
        
        if animated {
            SCNTransaction.commit()
        }
    }
    
    private func updateVisualFeedback(valid: Bool) {
        // Change color or opacity based on validity
        pieceNode.childNodes.forEach { node in
            node.geometry?.firstMaterial?.diffuse.contents = valid ? UIColor.orange : UIColor.red
        }
    }
    
    // MARK: - Gestures
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        scnView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tap)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: scnView)
        
        switch gesture.state {
        case .began:
            // Hit test to pick up piece
            let hitResults = scnView.hitTest(location, options: [.rootNode: pieceNode!])
            if !hitResults.isEmpty {
                isDragging = true
                HapticsManager.shared.playPattern("grab")
                
                // Lift piece
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                pieceNode.position.y = dragPlaneY
                SCNTransaction.commit()
                
                // Calculate offset from anchor to touch point
                let touchPos = projectOnPlane(location)
                pieceDragOffset = SCNVector3(pieceNode.position.x - touchPos.x, 0, pieceNode.position.z - touchPos.z)
            }
            
        case .changed:
            guard isDragging else { return }
            
            let touchPos = projectOnPlane(location)
            let newPos = SCNVector3(touchPos.x + pieceDragOffset.x, dragPlaneY, touchPos.z + pieceDragOffset.z)
            pieceNode.position = newPos
            
            // Preview Snap
            let (gx, gy) = worldToGrid(newPos)
            let candidate = PuzzleEngine.snapCandidate(x: gx, y: gy, rotation: currentPieceState.rotation)
            let cells = PuzzleEngine.transformedCells(shape: currentPieceShape, state: candidate)
            let valid = PuzzleEngine.validate(grid: gridState, cells: cells)
            
            updateVisualFeedback(valid: valid)
            
        case .ended, .cancelled:
            guard isDragging else { return }
            isDragging = false
            
            // Attempt Placement
            let (gx, gy) = worldToGrid(pieceNode.position)
            let candidate = PuzzleEngine.snapCandidate(x: gx, y: gy, rotation: currentPieceState.rotation)
            
            // Fallback is last valid state (or origin if none)
            let fallback = lastValidState ?? PieceState(anchor: Cell(x: -2, y: 1), rotation: .r0)
            
            let result = PuzzleEngine.applyPlacement(grid: gridState, shape: currentPieceShape, candidate: candidate, fallback: fallback)
            
            switch result {
            case .valid(let snappedState):
                currentPieceState = snappedState
                lastValidState = snappedState
                // Lock grid
                let cells = PuzzleEngine.transformedCells(shape: currentPieceShape, state: snappedState)
                gridState.lock(cells: cells)
                
                // Visual Snap
                updatePieceTransform(state: snappedState, animated: true)
                updateVisualFeedback(valid: true)
                HapticsManager.shared.playPattern("snap")
                
                // Spawn new piece or reset for demo?
                // Demo: Reset piece to outside after a delay? Or just leave it locked.
                // Spec says "lock in place".
                // We'll leave it there. User can't move it anymore if we check overlap correctly (overlap fails).
                // Actually, if it's locked, can we pick it up?
                // "If valid: snap to grid + lock in place."
                // "Overlap with ALREADY LOCKED cells".
                // This implies once placed, it's part of the grid.
                // For this demo, maybe we just spawn a new piece or let user drag the locked one?
                // Spec says "One piece only".
                // Let's just keep it there.
                
            case .invalid(let returnTo):
                currentPieceState = returnTo
                updatePieceTransform(state: returnTo, animated: true)
                updateVisualFeedback(valid: true) // Reset color
                HapticsManager.shared.playPattern("invalid")
            }
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Quick retap rotates
        // Only if we hit the piece? Or anywhere?
        // Spec: "Quick retap on the piece"
        let location = gesture.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: [.rootNode: pieceNode!])
        
        if !hitResults.isEmpty {
            let newState = PuzzleEngine.rotate(currentPieceState)
            
            // Re-evaluate snap (if we were dragging, or just in place)
            // If in place, check validity.
            // "then re-evaluates snap"
            
            let cells = PuzzleEngine.transformedCells(shape: currentPieceShape, state: newState)
            if PuzzleEngine.validate(grid: gridState, cells: cells) {
                currentPieceState = newState
                updatePieceTransform(state: newState, animated: true)
                HapticsManager.shared.playPattern("grab") // Small feedback
            } else {
                // Cannot rotate here (blocked)
                HapticsManager.shared.playPattern("invalid")
                // Shake animation?
            }
        }
    }
    
    // Project screen point to y=0 plane (or dragPlaneY)
    private func projectOnPlane(_ point: CGPoint) -> SCNVector3 {
        let results = scnView.hitTest(point, options: [
            .boundingBoxOnly: true,
            .ignoreHiddenNodes: false
        ])
        
        // We want to intersect with a mathematical plane, not necessarily nodes.
        // scnView.unprojectPoint needs depth.
        // Better: Raycast against plane y = dragPlaneY
        
        let rayOrigin = scnView.unprojectPoint(SCNVector3(point.x, point.y, 0))
        let rayEnd = scnView.unprojectPoint(SCNVector3(point.x, point.y, 1))
        
        let direction = SCNVector3(rayEnd.x - rayOrigin.x, rayEnd.y - rayOrigin.y, rayEnd.z - rayOrigin.z)
        
        // Plane: y = dragPlaneY
        // P = O + t * D
        // P.y = dragPlaneY
        // O.y + t * D.y = dragPlaneY
        // t = (dragPlaneY - O.y) / D.y
        
        if abs(direction.y) < 0.0001 { return SCNVector3(rayOrigin.x, dragPlaneY, rayOrigin.z) }
        
        let t = (dragPlaneY - rayOrigin.y) / direction.y
        return SCNVector3(rayOrigin.x + t * direction.x, dragPlaneY, rayOrigin.z + t * direction.z)
    }
}
