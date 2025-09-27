//
//  EffectsRenderer.swift
//  runner
//
//  SpriteKit renderer for particle effects and celebrations
//

import SpriteKit
import UIKit

protocol EffectsRendererProtocol {
    func createHoleInCelebration(at position: Position, celebrationLevel: CelebrationLevel, in scene: SKScene)
    func createScoreMessage(text: String, at position: Position, in scene: SKScene)
    func createPenaltyMessage(text: String, at position: Position, in scene: SKScene)
}

class EffectsRenderer: EffectsRendererProtocol {

    func createHoleInCelebration(at position: Position, celebrationLevel: CelebrationLevel, in scene: SKScene) {
        // Create particle-like celebration effects
        let particleCount = celebrationLevel.particleCount

        for i in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: 4)
            particle.fillColor = [.yellow, .orange, .green, .blue, .white][i % 5]
            particle.position = position.cgPoint
            particle.zPosition = 50
            scene.addChild(particle)

            let angle = CGFloat(i) * .pi * 2 / CGFloat(particleCount)
            let distance: CGFloat = 60
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance

            let moveOut = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.8)
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([
                SKAction.group([moveOut, fadeOut]),
                remove
            ]))
        }

        // Add sparkle effects for higher celebration levels
        if celebrationLevel == .major || celebrationLevel == .spectacular {
            createSparkleEffect(at: position, in: scene)
        }
    }

    func createScoreMessage(text: String, at position: Position, in scene: SKScene) {
        let scoreLabel = SKLabelNode(text: text)
        scoreLabel.fontName = "Arial-BoldMT"
        scoreLabel.fontSize = 48
        scoreLabel.fontColor = text.contains("!") ? .yellow : .white
        scoreLabel.position = CGPoint(x: position.x, y: position.y + 100)
        scoreLabel.zPosition = 100
        scoreLabel.alpha = 0
        scoreLabel.setScale(0.1)
        scene.addChild(scoreLabel)

        // Dramatic entrance animation
        let appearScale = SKAction.scale(to: 1.2, duration: 0.3)
        let settleScale = SKAction.scale(to: 1.0, duration: 0.2)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleSequence = SKAction.sequence([appearScale, settleScale])

        scoreLabel.run(SKAction.group([scaleSequence, fadeIn])) {
            // Hold for a moment, then fade out
            let wait = SKAction.wait(forDuration: 2.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()

            scoreLabel.run(SKAction.sequence([wait, fadeOut, remove]))
        }
    }

    func createPenaltyMessage(text: String, at position: Position, in scene: SKScene) {
        let penaltyLabel = SKLabelNode(text: text)
        penaltyLabel.fontName = "Arial-BoldMT"
        penaltyLabel.fontSize = 24
        penaltyLabel.fontColor = .red
        penaltyLabel.position = position.cgPoint
        penaltyLabel.zPosition = 100
        penaltyLabel.alpha = 0
        scene.addChild(penaltyLabel)

        // Simple fade in/out animation
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()

        penaltyLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    // MARK: - Private Effects
    private func createSparkleEffect(at position: Position, in scene: SKScene) {
        for _ in 0..<10 {
            let sparkle = SKShapeNode(circleOfRadius: 2)
            sparkle.fillColor = .white
            sparkle.strokeColor = .yellow
            sparkle.lineWidth = 1
            sparkle.position = CGPoint(
                x: position.x + (Double.random(in: 0...1) - 0.5) * 100,
                y: position.y + (Double.random(in: 0...1) - 0.5) * 100
            )
            sparkle.zPosition = 55
            scene.addChild(sparkle)

            // Sparkle animation
            let twinkle = SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.scale(to: 0.5, duration: 0.2)
            ])
            let repeatAction = SKAction.repeat(twinkle, count: 3)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()

            sparkle.run(SKAction.sequence([repeatAction, fadeOut, remove]))
        }
    }

    // MARK: - Penalty Effects
    func createWaterSplash(at position: Position, in scene: SKScene) {
        for i in 0..<6 {
            let droplet = SKShapeNode(circleOfRadius: 3)
            droplet.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.8)
            droplet.position = position.cgPoint
            droplet.zPosition = 40
            scene.addChild(droplet)

            let angle = CGFloat(i) * .pi / 3
            let distance: CGFloat = 30
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance

            let splash = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.4)
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()

            droplet.run(SKAction.sequence([
                SKAction.group([splash, fadeOut]),
                remove
            ]))
        }
    }

    func createSandPuff(at position: Position, in scene: SKScene) {
        for _ in 0..<4 {
            let puff = SKShapeNode(circleOfRadius: 5)
            puff.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 0.6)
            puff.strokeColor = .clear
            puff.position = CGPoint(
                x: position.x + (Double.random(in: 0...1) - 0.5) * 20,
                y: position.y + (Double.random(in: 0...1) - 0.5) * 20
            )
            puff.zPosition = 40
            scene.addChild(puff)

            let expand = SKAction.scale(to: 2.0, duration: 0.6)
            let fadeOut = SKAction.fadeOut(withDuration: 0.6)
            let remove = SKAction.removeFromParent()

            puff.run(SKAction.sequence([
                SKAction.group([expand, fadeOut]),
                remove
            ]))
        }
    }
}