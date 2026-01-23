# PuzzleCore Phase-0 Demo

This repository contains the Phase-0 vertical slice for the PuzzleCore 3D puzzle game.

## Architecture

The project is divided into two parts:
1.  **PuzzleCore (App)**: The iOS Application using UIKit and SceneKit.
2.  **PuzzleCore (Package)**: A pure Swift local package containing the game logic, grid math, and validation rules.

## Setup Instructions

Since this project was generated in a text-based environment, you need to link the local package to the Xcode project manually:

1.  Open `PuzzleCore.xcodeproj` in Xcode.
2.  Open Finder and navigate to `LocalPackages/`.
3.  Drag the `PuzzleCore` folder (the one inside `LocalPackages`) into the Xcode Project Navigator (the left sidebar). This adds it as a Local Swift Package.
4.  Select the `PuzzleCore` **App Target** (click the Blue Project Icon -> Select Target `PuzzleCore` -> General tab).
5.  Scroll to **Frameworks, Libraries, and Embedded Content**.
6.  Click `+` and select `PuzzleCore` (the library with the building icon).
7.  **Important**: Ensure the `.ahap` files are included in the bundle.
    -   Locate `PuzzleCore/Resources` folder in the Project Navigator (or drag it in from Finder if missing).
    -   Ensure `grab.ahap`, `snap.ahap`, and `invalid.ahap` are in the **Copy Bundle Resources** build phase of the App Target.

## Running Tests

To run the unit tests for the logic core:

1.  Select the `PuzzleCore` scheme (the package scheme) in Xcode (it might appear as a puzzle piece icon).
2.  Press `Cmd+U`.
3.  Alternatively, use the command line:
    ```bash
    cd LocalPackages/PuzzleCore
    swift test
    ```

## Tuning

-   **Snap Thresholds & Drag Height**: Check `GameViewController.swift` constants:
    ```swift
    private let cellSize: Float = 1.0
    private let dragPlaneY: Float = 0.5
    private let snapThreshold: Float = 0.5
    ```
-   **Haptics**:
    -   Modify `.ahap` files in `PuzzleCore/Resources/`.
    -   Trigger logic is in `GameViewController.swift` (`handlePan`, `handleTap`).
    -   Haptic engine logic is in `HapticsManager.swift`.

## Key Files

-   **Logic**: `LocalPackages/PuzzleCore/Sources/PuzzleCore/PuzzleCore.swift` (Grid, Piece, Validation).
-   **Game Loop**: `PuzzleCore/GameViewController.swift` (Gestures, SceneKit, State Management).
-   **Haptics**: `PuzzleCore/HapticsManager.swift`.

## Features Implemented

-   **Grid**: 4x4 mathematical grid.
-   **Piece**: L-shape (rotateable).
-   **Interaction**: Drag to move, tap to rotate.
-   **Validation**: Bounds check, Overlap check (Logic-based).
-   **Feedback**: Visual snap/color change, Haptic feedback (Core Haptics).
