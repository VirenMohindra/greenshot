//
//  EnvironmentSwitcher.swift
//  GreenShot
//
//  Easy environment switching for development and testing
//

import Foundation
import SwiftUI

// MARK: - Environment Switch Helper
struct EnvironmentSwitcher {
    // MARK: - Environment Detection
    static func determineEnvironment() -> AppEnvironment {
        #if DEBUG
        // Check for environment override from UserDefaults or launch arguments
        if let override = ProcessInfo.processInfo.environment["FORCE_ENVIRONMENT"] {
            switch override.lowercased() {
            case "production": return .production
            case "staging": return .staging
            default: return .development
            }
        }

        // Check UserDefaults for runtime switching (useful for debugging)
        let userDefaults = UserDefaults.standard
        if let envString = userDefaults.string(forKey: "selected_environment") {
            switch envString {
            case "production": return .production
            case "staging": return .staging
            case "development": return .development
            default: return .development
            }
        }

        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    // MARK: - Runtime Environment Switching (Debug only)
    #if DEBUG
    static func switchToEnvironment(_ environment: AppEnvironment) {
        UserDefaults.standard.set(environment.rawValue, forKey: "selected_environment")

        // Post notification for services to reconfigure
        NotificationCenter.default.post(
            name: .environmentChanged,
            object: nil,
            userInfo: ["newEnvironment": environment]
        )

        print("🔄 Environment switched to: \(environment)")
    }

    static func getCurrentEnvironment() -> AppEnvironment {
        let envString = UserDefaults.standard.string(forKey: "selected_environment") ?? "development"
        return AppEnvironment(rawValue: envString) ?? .development
    }
    #endif
}

// MARK: - Environment Extension
extension AppEnvironment {
    var rawValue: String {
        switch self {
        case .development: return "development"
        case .staging: return "staging"
        case .production: return "production"
        }
    }

    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "development": self = .development
        case "staging": self = .staging
        case "production": self = .production
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .development: return "Development (Local/Mock)"
        case .staging: return "Staging (Test Server)"
        case .production: return "Production (Live Server)"
        }
    }

    var supportsNetworking: Bool {
        switch self {
        case .development: return false  // Use mock services
        case .staging, .production: return true  // Use real networking
        }
    }
}

// MARK: - Notification Names Extension
extension NSNotification.Name {
    static let environmentChanged = NSNotification.Name("environmentChanged")
}

// MARK: - Debug Environment Picker (SwiftUI)
#if DEBUG
struct EnvironmentPickerView: View {
    @State private var selectedEnvironment: AppEnvironment = EnvironmentSwitcher.getCurrentEnvironment()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Current Environment") {
                    Text(selectedEnvironment.displayName)
                        .foregroundColor(.primary)
                        .font(.headline)
                }

                Section("Available Environments") {
                    ForEach([AppEnvironment.development, .staging, .production], id: \.rawValue) { env in
                        Button(action: {
                            selectedEnvironment = env
                            EnvironmentSwitcher.switchToEnvironment(env)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(env.displayName)
                                        .foregroundColor(.primary)

                                    Text(environmentDescription(env))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedEnvironment == env {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                Section("Info") {
                    Text("Development mode uses mock data and local course generation.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Staging/Production modes will attempt to connect to real servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Environment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func environmentDescription(_ env: AppEnvironment) -> String {
        switch env {
        case .development:
            return "Local course generation, mock leaderboards, no network calls"
        case .staging:
            return "Test server, real networking, safe for development"
        case .production:
            return "Live server, real players, production data"
        }
    }
}
#endif