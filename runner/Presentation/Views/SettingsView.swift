//
//  SettingsView.swift
//  runner
//
//  Simple settings view placeholder
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Game Settings
    @State private var soundEnabled = true
    @State private var musicEnabled = true
    @State private var hapticFeedback = true
    @State private var showTrajectoryPreview = true
    @State private var autoZoomOnShot = true
    @State private var showControlRadius = true

    // Course Generation Settings
    @State private var courseDifficulty: CourseDifficulty = .medium
    @State private var courseLength: CourseLength = .nine
    @State private var obstacleFrequency: ObstacleFrequency = .medium

    // Visual Settings
    @State private var showCelebrations = true
    @State private var enableTrailEffects = true
    @State private var cameraSpeed: Double = 0.5

    // Accessibility
    @State private var highContrastMode = false
    @State private var reducedMotion = false
    @State private var largerText = false

    // Development
    #if DEBUG
    @State private var showEnvironmentPicker = false
    #endif

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
                        isOn: $showTrajectoryPreview,
                        icon: "arrow.trianglehead.clockwise"
                    )

                    SettingsToggle(
                        title: "Auto Zoom on Shot",
                        subtitle: "Follow ball during shot",
                        isOn: $autoZoomOnShot,
                        icon: "viewfinder"
                    )

                    SettingsToggle(
                        title: "Show Control Radius",
                        subtitle: "Display touch area around ball",
                        isOn: $showControlRadius,
                        icon: "circle.dashed"
                    )

                    HStack {
                        Label("Camera Speed", systemImage: "camera")
                        Spacer()
                        Slider(value: $cameraSpeed, in: 0.1...1.0)
                            .frame(width: 120)
                        Text("\(Int(cameraSpeed * 100))%")
                            .foregroundColor(.secondary)
                            .frame(width: 35)
                    }
                }

                // Audio & Visual Section
                Section("Audio & Visual") {
                    SettingsToggle(
                        title: "Sound Effects",
                        subtitle: "Ball hits, hole completion",
                        isOn: $soundEnabled,
                        icon: "speaker.wave.2"
                    )

                    SettingsToggle(
                        title: "Background Music",
                        subtitle: "Ambient golf course sounds",
                        isOn: $musicEnabled,
                        icon: "music.note"
                    )

                    SettingsToggle(
                        title: "Haptic Feedback",
                        subtitle: "Vibration on ball contact",
                        isOn: $hapticFeedback,
                        icon: "iphone.radiowaves.left.and.right"
                    )

                    SettingsToggle(
                        title: "Celebration Effects",
                        subtitle: "Animations for good shots",
                        isOn: $showCelebrations,
                        icon: "party.popper"
                    )

                    SettingsToggle(
                        title: "Ball Trail Effects",
                        subtitle: "Show ball movement trail",
                        isOn: $enableTrailEffects,
                        icon: "scribble.variable"
                    )
                }

                // Course Generation Section
                Section("Course Generation") {
                    Picker("Course Difficulty", selection: $courseDifficulty) {
                        ForEach(CourseDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Course Length", selection: $courseLength) {
                        ForEach(CourseLength.allCases, id: \.self) { length in
                            Text(length.rawValue).tag(length)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Obstacle Frequency", selection: $obstacleFrequency) {
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
                        isOn: $highContrastMode,
                        icon: "circle.lefthalf.filled"
                    )

                    SettingsToggle(
                        title: "Reduce Motion",
                        subtitle: "Minimize animations",
                        isOn: $reducedMotion,
                        icon: "tortoise"
                    )

                    SettingsToggle(
                        title: "Larger Text",
                        subtitle: "Increase text size",
                        isOn: $largerText,
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
                        resetToDefaults()
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

    private func resetToDefaults() {
        soundEnabled = true
        musicEnabled = true
        hapticFeedback = true
        showTrajectoryPreview = true
        autoZoomOnShot = true
        showControlRadius = true
        courseDifficulty = .medium
        courseLength = .nine
        obstacleFrequency = .medium
        showCelebrations = true
        enableTrailEffects = true
        cameraSpeed = 0.5
        highContrastMode = false
        reducedMotion = false
        largerText = false
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