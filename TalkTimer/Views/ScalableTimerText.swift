import SwiftUI

struct ScalableTimerText: View {
    let text: String
    let textColor: Color
    let geometry: GeometryProxy

    var body: some View {
        Text(text)
            .font(.system(size: 500, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.01)
            .lineLimit(1)
            .foregroundColor(textColor)
            .frame(maxWidth: geometry.size.width * 0.95)
            .frame(maxHeight: geometry.size.height * 0.7)
    }
}
