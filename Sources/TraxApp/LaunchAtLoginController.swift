import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable

    var isEnabled: Bool {
        self == .enabled
    }

    var canToggle: Bool {
        switch self {
        case .enabled, .disabled:
            return true
        case .requiresApproval, .unavailable:
            return false
        }
    }

    var message: String? {
        switch self {
        case .enabled, .disabled:
            return nil
        case .requiresApproval:
            return "Approval needed in System Settings."
        case .unavailable:
            return "Install the app bundle before enabling this."
        }
    }
}

enum LaunchAtLoginController {
    static func status() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    static func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
