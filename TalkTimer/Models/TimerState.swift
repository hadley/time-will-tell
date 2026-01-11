import SwiftUI

enum TimerZone: Equatable {
    case black
    case yellow
    case red
    case flashing

    var backgroundColor: Color {
        switch self {
        case .black:
            .black
        case .yellow:
            .yellow
        case .red:
            .red
        case .flashing:
            .red
        }
    }

    var textColor: Color {
        switch self {
        case .black:
            .white
        case .yellow:
            .black
        case .red:
            .white
        case .flashing:
            .white
        }
    }
}

enum TimerStatus {
    case idle
    case running
    case paused
    case finished
}
