import UIKit

class HapticManager {
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init() {
        impactGenerator.prepare()
    }

    func zoneTransition() {
        impactGenerator.impactOccurred()
        impactGenerator.prepare()
    }
}
