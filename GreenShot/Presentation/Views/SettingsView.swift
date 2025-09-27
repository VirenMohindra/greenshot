//
//  SettingsView.swift
//  GreenShot
//
//  Simple settings view placeholder
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsController: SettingsController

    init() {
        // Get SettingsController from DependencyContainer
        let container = DependencyContainer()
        _settingsController = StateObject(wrappedValue: container.settingsController)
    }

    // Development
    #if DEBUG
    @State private var showEnvironmentPicker = false
    #endif

    // UI Helper Enums
    enum CourseDifficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
    }

    enum CourseLength: String, CaseIterable {
        case three = "3 Holes"
        case six = "6 Holes"
        case nine = "9 Holes"
        case eighteen = "18 Holes"
    }

    enum ObstacleFrequency: String, CaseIterable {
        case minimal = "Minimal"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }

    var body: some View {
        NavigationView {
            Form {
                // Game Settings Section
                Section("Game Settings") {
                    SettingsToggle(
                        title: "Trajectory Preview",
                        subtitle: "Show shot prediction line",
                        isOn: Binding(
                            get: { settingsController.userPreferences.showTrajectoryPreview },
                            set: { settingsController.updateShowTrajectoryPreview($0) }
                        ),
                        icon: "arrow.trianglehead.clockwise"
                    )

                    SettingsToggle(
                        title: "Auto Zoom on Shot",
                        subtitle: "Follow ball during shot",
                        isOn: Binding(
                            get: { settingsController.userPreferences.autoZoomOnShot },
                            set: { settingsController.updateAutoZoomOnShot($0) }
                        ),
                        icon: "viewfinder"
                    )

                    SettingsToggle(
                        title: "Show Control Radius",
                        subtitle: "Display touch area around ball",
                        isOn: Binding(
                            get: { settingsController.userPreferences.showControlRadius },
                            set: { settingsController.updateShowControlRadius($0) }
                        ),
                        icon: "circle.dashed"
                    )

                    HStack {
                        Label("Camera Speed", systemImage: "camera")
                        Spacer()
                        Slider(
                            value: Binding(
                                get: { settingsController.userPreferences.cameraSpeed },
                                set: { settingsController.updateCameraSpeed($0) }
                            ),
                            in: 0.1...1.0
                        )
                            .frame(width: 120)
                        Text("\(Int(settingsController.userPreferences.cameraSpeed * 100))%")
                            .foregroundColor(.secondary)
                            .frame(width: 35)
                    }
                }

                // Audio & Visual Section
                Section("Audio & Visual") {
                    SettingsToggle(
                        title: "Sound Effects",
                        subtitle: "Ball hits, hole completion",
                        isOn: Binding(
                            get: { settingsController.userPreferences.soundEnabled },
                            set: { settingsController.updateSoundEnabled($0) }
                        ),
                        icon: "speaker.wave.2"
                    )

                    SettingsToggle(
                        title: "Background Music",
                        subtitle: "Ambient golf course sounds",
                        isOn: Binding(
                            get: { settingsController.userPreferences.musicEnabled },
                            set: { settingsController.updateMusicEnabled($0) }
                        ),
                        icon: "music.note"
                    )

                    SettingsToggle(
                        title: "Haptic Feedback",
                        subtitle: "Vibration on ball contact",
                        isOn: Binding(
                            get: { settingsController.userPreferences.hapticFeedback },
                            set: { settingsController.updateHapticFeedback($0) }
                        ),
                        icon: "iphone.radiowaves.left.and.right"
                    )

                    SettingsToggle(
                        title: "Celebration Effects",
                        subtitle: "Animations for good shots",
                        isOn: Binding(
                            get: { settingsController.userPreferences.showCelebrations },
                            set: { settingsController.updateShowCelebrations($0) }
                        ),
                        icon: "party.popper"
                    )

                    SettingsToggle(
                        title: "Ball Trail Effects",
                        subtitle: "Show ball movement trail",
                        isOn: Binding(
                            get: { settingsController.userPreferences.enableTrailEffects },
                            set: { settingsController.updateEnableTrailEffects($0) }
                        ),
                        icon: "scribble.variable"
                    )
                }

                // Course Generation Section
                Section("Course Generation") {
                    Picker("Course Difficulty", selection: Binding(
                        get: {
                            CourseDifficulty.allCases.first { $0.rawValue.lowercased() == settingsController.userPreferences.courseDifficulty.lowercased() } ?? .medium
                        },
                        set: { difficulty in
                            var prefs = settingsController.userPreferences
                            prefs = UserPreferences(
                                soundEnabled: prefs.soundEnabled,
                                musicEnabled: prefs.musicEnabled,
                                hapticFeedback: prefs.hapticFeedback,
                                showTrajectoryPreview: prefs.showTrajectoryPreview,
                                autoZoomOnShot: prefs.autoZoomOnShot,
                                showControlRadius: prefs.showControlRadius,
                                courseDifficulty: difficulty.rawValue.lowercased(),
                                courseLength: prefs.courseLength,
                                obstacleFrequency: prefs.obstacleFrequency,
                                showCelebrations: prefs.showCelebrations,
                                enableTrailEffects: prefs.enableTrailEffects,
                                cameraSpeed: prefs.cameraSpeed,
                                highContrastMode: prefs.highContrastMode,
                                reducedMotion: prefs.reducedMotion,
                                largerText: prefs.largerText,
                                lastUpdated: Date()
                            )
                            settingsController.userPreferences = prefs
                            settingsController.savePreferences()
                        }
                    )) {
                        ForEach(CourseDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Course Length", selection: Binding(
                        get: {
                            CourseLength.allCases.first { $0.rawValue.lowercased().contains(settingsController.userPreferences.courseLength) } ?? .nine
                        },
                        set: { length in
                            var prefs = settingsController.userPreferences
                            prefs = UserPreferences(
                                soundEnabled: prefs.soundEnabled,
                                musicEnabled: prefs.musicEnabled,
                                hapticFeedback: prefs.hapticFeedback,
                                showTrajectoryPreview: prefs.showTrajectoryPreview,
                                autoZoomOnShot: prefs.autoZoomOnShot,
                                showControlRadius: prefs.showControlRadius,
                                courseDifficulty: prefs.courseDifficulty,
                                courseLength: length.rawValue.lowercased(),
                                obstacleFrequency: prefs.obstacleFrequency,
                                showCelebrations: prefs.showCelebrations,
                                enableTrailEffects: prefs.enableTrailEffects,
                                cameraSpeed: prefs.cameraSpeed,
                                highContrastMode: prefs.highContrastMode,
                                reducedMotion: prefs.reducedMotion,
                                largerText: prefs.largerText,
                                lastUpdated: Date()
                            )
                            settingsController.userPreferences = prefs
                            settingsController.savePreferences()
                        }
                    )) {
                        ForEach(CourseLength.allCases, id: \.self) { length in
                            Text(length.rawValue).tag(length)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Obstacle Frequency", selection: Binding(
                        get: {
                            ObstacleFrequency.allCases.first { $0.rawValue.lowercased() == settingsController.userPreferences.obstacleFrequency.lowercased() } ?? .medium
                        },
                        set: { frequency in
                            var prefs = settingsController.userPreferences
                            prefs = UserPreferences(
                                soundEnabled: prefs.soundEnabled,
                                musicEnabled: prefs.musicEnabled,
                                hapticFeedback: prefs.hapticFeedback,
                                showTrajectoryPreview: prefs.showTrajectoryPreview,
                                autoZoomOnShot: prefs.autoZoomOnShot,
                                showControlRadius: prefs.showControlRadius,
                                courseDifficulty: prefs.courseDifficulty,
                                courseLength: prefs.courseLength,
                                obstacleFrequency: frequency.rawValue.lowercased(),
                                showCelebrations: prefs.showCelebrations,
                                enableTrailEffects: prefs.enableTrailEffects,
                                cameraSpeed: prefs.cameraSpeed,
                                highContrastMode: prefs.highContrastMode,
                                reducedMotion: prefs.reducedMotion,
                                largerText: prefs.largerText,
                                lastUpdated: Date()
                            )
                            settingsController.userPreferences = prefs
                            settingsController.savePreferences()
                        }
                    )) {
                        ForEach(ObstacleFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // Accessibility Section
                Section("Accessibility") {
                    SettingsToggle(
                        title: "High Contrast Mode",
                        subtitle: "Increase visual contrast",
                        isOn: Binding(
                            get: { settingsController.userPreferences.highContrastMode },
                            set: { settingsController.updateHighContrastMode($0) }
                        ),
                        icon: "circle.lefthalf.filled"
                    )

                    SettingsToggle(
                        title: "Reduce Motion",
                        subtitle: "Minimize animations",
                        isOn: Binding(
                            get: { settingsController.userPreferences.reducedMotion },
                            set: { settingsController.updateReducedMotion($0) }
                        ),
                        icon: "tortoise"
                    )

                    SettingsToggle(
                        title: "Larger Text",
                        subtitle: "Increase text size",
                        isOn: Binding(
                            get: { settingsController.userPreferences.largerText },
                            set: { settingsController.updateLargerText($0) }
                        ),
                        icon: "textformat.size"
                    )
                }

                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text("2024.1")
                            .foregroundColor(.secondary)
                    }

                    #if DEBUG
                    Button(action: {
                        showEnvironmentPicker = true
                    }) {
                        HStack {
                            Label("Environment", systemImage: "server.rack")
                            Spacer()
                            Text(EnvironmentSwitcher.getCurrentEnvironment().displayName)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .foregroundColor(.primary)
                    }
                    #endif

                    Button(action: {
                        // Reset to defaults
                        settingsController.resetToDefaults()
                    }) {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if DEBUG
        .sheet(isPresented: $showEnvironmentPicker) {
            EnvironmentPickerView()
        }
        #endif
    }

}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

#Preview {
    SettingsView()
}