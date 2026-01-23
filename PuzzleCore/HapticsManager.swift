import Foundation
import CoreHaptics
import UIKit

public class HapticsManager {
    public static let shared = HapticsManager()
    
    private var engine: CHHapticEngine?
    
    private init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Handle reset
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            print("Haptics error: \(error)")
        }
    }
    
    public func playPattern(_ name: String) {
        guard let engine = engine else { return }
        
        // In a real app, we might preload these or cache them.
        guard let path = Bundle.main.path(forResource: name, ofType: "ahap") else {
            print("Haptic file not found: \(name)")
            return
        }
        
        do {
            try engine.start()
            let url = URL(fileURLWithPath: path)
            let player = try engine.makePlayer(with: CHHapticPattern(contentsOf: url))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play pattern \(name): \(error)")
        }
    }
    
    // Fallback for simple feedback if needed
    public func playSimpleSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
