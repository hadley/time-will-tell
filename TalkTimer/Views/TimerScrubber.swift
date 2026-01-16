import SwiftUI

struct TimerScrubber: View {
    @ObservedObject var viewModel: TimerViewModel
    let textColor: Color

    @State private var isDragging = false

    private var progress: Double {
        guard viewModel.totalSeconds > 0 else { return 0 }
        let total = Double(viewModel.totalSeconds)
        let remaining = Double(viewModel.remainingSeconds)
        return 1 - (remaining / total)
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.toggle) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 32))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(textColor.opacity(0.3))
                        .frame(height: 8)

                    // Progress
                    Capsule()
                        .fill(textColor.opacity(0.7))
                        .frame(width: max(0, geometry.size.width * progress), height: 8)

                    // Thumb
                    Circle()
                        .fill(textColor)
                        .frame(width: 24, height: 24)
                        .offset(x: max(0, min(geometry.size.width - 24, geometry.size.width * progress - 12)))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let percent = max(0, min(1, value.location.x / geometry.size.width))
                                    let totalSeconds = viewModel.totalSeconds
                                    viewModel.scrub(toRemainingSeconds: Int(Double(totalSeconds) * (1 - percent)))
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
                .frame(height: 24)
            }
            .frame(height: 24)
        }
        .foregroundColor(textColor.opacity(0.7))
    }

    private var playPauseIcon: String {
        (viewModel.status == .running || viewModel.status == .finished) ? "pause.fill" : "play.fill"
    }
}
