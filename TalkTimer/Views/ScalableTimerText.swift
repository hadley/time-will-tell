import SwiftUI

struct ScalableTimerText: View {
    let text: String
    let textColor: Color

    @State private var fontSize: CGFloat = 500
    @State private var availableSize: CGSize = .zero

    private let referenceText = "00:00"

    private func timerFont(size: CGFloat) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size, weight: .bold)
            .fontDescriptor
            .addingAttributes([
                .featureSettings: [[
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
                ]],
            ])
        return UIFont(descriptor: descriptor, size: size)
    }

    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(Font(timerFont(size: fontSize)))
                .lineLimit(1)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    updateFontSize(for: geometry.size)
                }
                .onChange(of: geometry.size) { newSize in
                    updateFontSize(for: newSize)
                }
        }
    }

    private func updateFontSize(for size: CGSize) {
        guard size != availableSize else { return }
        availableSize = size
        calculateFontSize()
    }

    private func calculateFontSize() {
        let maxWidth = availableSize.width
        let maxHeight = availableSize.height

        guard maxWidth > 0, maxHeight > 0 else { return }

        var low: CGFloat = 1
        var high: CGFloat = 500

        // Binary search to find the optimal font size
        while high - low > 1 {
            let mid = (low + high) / 2
            let font = timerFont(size: mid)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let size = (referenceText as NSString).size(withAttributes: attributes)

            if size.width <= maxWidth, size.height <= maxHeight {
                low = mid
            } else {
                high = mid
            }
        }

        fontSize = low
    }
}
