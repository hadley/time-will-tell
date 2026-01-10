import SwiftUI

struct ScalableTimerText: View {
    let text: String
    let textColor: Color
    let geometry: GeometryProxy

    @State private var fontSize: CGFloat = 500
    @State private var hasCalculatedSize = false

    private let referenceText = "00:00"

    // UI dimensions (must match TimerView)
    private let topBarHeight: CGFloat = 44
    private let scrubberHeight: CGFloat = 76

    private func timerFont(size: CGFloat) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size, weight: .bold)
            .fontDescriptor
            .addingAttributes([
                .featureSettings: [[
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
                ]]
            ])
        return UIFont(descriptor: descriptor, size: size)
    }

    var body: some View {
        Text(text)
            .font(Font(timerFont(size: fontSize)))
            .lineLimit(1)
            .foregroundColor(textColor)
            .onAppear {
                if !hasCalculatedSize {
                    calculateFontSize()
                }
            }
            .onChange(of: geometry.size) { _ in
                calculateFontSize()
            }
    }

    private func calculateFontSize() {
        let horizontalSafeArea = geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing
        let maxWidth = geometry.size.width - horizontalSafeArea
        let maxHeight = geometry.size.height - topBarHeight - scrubberHeight

        var low: CGFloat = 1
        var high: CGFloat = 500

        // Binary search to find the optimal font size
        while high - low > 1 {
            let mid = (low + high) / 2
            let font = timerFont(size: mid)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let size = (referenceText as NSString).size(withAttributes: attributes)

            if size.width <= maxWidth && size.height <= maxHeight {
                low = mid
            } else {
                high = mid
            }
        }

        // Apply safety margin to account for rendering differences
        fontSize = low
        hasCalculatedSize = true
    }
}
