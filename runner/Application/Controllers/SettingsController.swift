//
//  SettingsController.swift
//  runner
//
//  Manages user preferences and settings persistence
//

import Foundation
import Combine

class SettingsController: ObservableObject {
    @Published var userPreferences: UserPreferences = .default

    private let persistenceService: PersistenceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(persistenceService: PersistenceServiceProtocol) {
        self.persistenceService = persistenceService
        loadPreferences()
    }

    // MARK: - Preference Management

    func loadPreferences() {
        do {
            userPreferences = try persistenceService.loadUserPreferences()
            print("⚙️ Loaded user preferences")
        } catch {
            print("❌ Failed to load preferences, using defaults: \(error)")
            userPreferences = .default
        }
    }

    func savePreferences() {
        do {
            let updatedPreferences = UserPreferences(
                soundEnabled: userPreferences.soundEnabled,
                musicEnabled: userPreferences.musicEnabled,
                hapticFeedback: userPreferences.hapticFeedback,
                showTrajectoryPreview: userPreferences.showTrajectoryPreview,
                autoZoomOnShot: userPreferences.autoZoomOnShot,
                showControlRadius: userPreferences.showControlRadius,
                courseDifficulty: userPreferences.courseDifficulty,
                courseLength: userPreferences.courseLength,
                obstacleFrequency: userPreferences.obstacleFrequency,
                showCelebrations: userPreferences.showCelebrations,
                enableTrailEffects: userPreferences.enableTrailEffects,
                cameraSpeed: userPreferences.cameraSpeed,
                highContrastMode: userPreferences.highContrastMode,
                reducedMotion: userPreferences.reducedMotion,
                largerText: userPreferences.largerText,
                lastUpdated: Date()
            )

            try persistenceService.saveUserPreferences(updatedPreferences)
            userPreferences = updatedPreferences
            print("💾 Saved user preferences")
        } catch {
            print("❌ Failed to save preferences: \(error)")
        }
    }

    // MARK: - Individual Setting Updates

    func updateSoundEnabled(_ enabled: Bool) {
        userPreferences = UserPreferences(
            soundEnabled: enabled,
            musicEnabled: userPreferences.musicEnabled,
            hapticFeedback: userPreferences.hapticFeedback,
            showTrajectoryPreview: userPreferences.showTrajectoryPreview,
            autoZoomOnShot: userPreferences.autoZoomOnShot,
            showControlRadius: userPreferences.showControlRadius,
            courseDifficulty: userPreferences.courseDifficulty,
            courseLength: userPreferences.courseLength,
            obstacleFrequency: userPreferences.obstacleFrequency,
            showCelebrations: userPreferences.showCelebrations,
            enableTrailEffects: userPreferences.enableTrailEffects,
            cameraSpeed: userPreferences.cameraSpeed,
            highContrastMode: userPreferences.highContrastMode,
            reducedMotion: userPreferences.reducedMotion,
            largerText: userPreferences.largerText,
            lastUpdated: userPreferences.lastUpdated
        )
        savePreferences()
    }

    func updateCameraSpeed(_ speed: Double) {
        userPreferences = UserPreferences(
            soundEnabled: userPreferences.soundEnabled,
            musicEnabled: userPreferences.musicEnabled,
            hapticFeedback: userPreferences.hapticFeedback,
            showTrajectoryPreview: userPreferences.showTrajectoryPreview,
            autoZoomOnShot: userPreferences.autoZoomOnShot,
            showControlRadius: userPreferences.showControlRadius,
            courseDifficulty: userPreferences.courseDifficulty,
            courseLength: userPreferences.courseLength,
            obstacleFrequency: userPreferences.obstacleFrequency,
            showCelebrations: userPreferences.showCelebrations,
            enableTrailEffects: userPreferences.enableTrailEffects,
            cameraSpeed: speed,
            highContrastMode: userPreferences.highContrastMode,
            reducedMotion: userPreferences.reducedMotion,
            largerText: userPreferences.largerText,
            lastUpdated: userPreferences.lastUpdated
        )
        savePreferences()
    }

    func resetToDefaults() {
        userPreferences = .default
        savePreferences()
    }

    // MARK: - Statistics Access

    func getPlayerStatistics() -> PlayerStatistics? {
        do {
            return try persistenceService.loadPlayerStats()
        } catch {
            print("❌ Failed to load player statistics: \(error)")
            return nil
        }
    }

    func clearAllData() {
        do {
            try persistenceService.clearCache()
            userPreferences = .default
            print("🗑️ Cleared all data and reset to defaults")
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
}