//
//  UIRenderer.swift
//  runner
//
//  SpriteKit renderer for HUD and UI overlay elements
//

import SpriteKit
import UIKit

protocol UIRendererProtocol {
    func createBroadcastScoreboard(
        hole: Int,
        par: Int,
        strokes: Int,
        score: Score,
        screenSize: CGSize
    ) -> SKNode

    func updateScoreboard(
        scoreboard: SKNode,
        hole: Int,
        par: Int,
        strokes: Int,
        score: Score
    )

    func createResetButton(near ballPosition: Position) -> SKNode
    func clearResetButton(from scene: SKScene)
}

class UIRenderer: UIRendererProtocol {
    private let scoringService: ScoringServiceProtocol

    init(scoringService: ScoringServiceProtocol) {
        self.scoringService = scoringService
    }

    func createBroadcastScoreboard(
        hole: Int,
        par: Int,
        strokes: Int,
        score: Score,
        screenSize: CGSize
    ) -> SKNode {
        let scoreboardContainer = SKNode()
        scoreboardContainer.name = "scoreboardContainer"
        scoreboardContainer.zPosition = 1000

        // Main scoreboard background
        let scoreboardWidth: CGFloat = screenSize.width * 0.9
        let scoreboardHeight: CGFloat = 70
        let scoreboard = SKShapeNode(rectOf: CGSize(width: scoreboardWidth, height: scoreboardHeight), cornerRadius: 8)
        scoreboard.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.92)
        scoreboard.strokeColor = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)
        scoreboard.lineWidth = 2
        scoreboard.position = CGPoint(x: 0, y: screenSize.height * 0.42)
        scoreboardContainer.addChild(scoreboard)

        // Gradient overlay
        let gradientOverlay = SKShapeNode(rectOf: CGSize(width: scoreboardWidth - 4, height: scoreboardHeight - 4), cornerRadius: 6)
        gradientOverlay.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.7)
        gradientOverlay.strokeColor = .clear
        gradientOverlay.position = scoreboard.position
        gradientOverlay.zPosition = -1
        scoreboardContainer.addChild(gradientOverlay)

        // Create sections
        createHoleSection(in: scoreboardContainer, scoreboard: scoreboard, hole: hole)
        createParSection(in: scoreboardContainer, scoreboard: scoreboard, par: par)
        createStrokesSection(in: scoreboardContainer, scoreboard: scoreboard, strokes: strokes, score: score)
        createScoreSection(in: scoreboardContainer, scoreboard: scoreboard, score: score)

        // Add dividers
        addScoreboardDividers(to: scoreboardContainer, scoreboard: scoreboard, screenSize: screenSize)

        return scoreboardContainer
    }

    func updateScoreboard(
        scoreboard: SKNode,
        hole: Int,
        par: Int,
        strokes: Int,
        score: Score
    ) {
        // Update hole number
        if let holeLabel = scoreboard.childNode(withName: "holeNumber") as? SKLabelNode {
            holeLabel.text = "\(hole)"
        }

        // Update par
        if let parLabel = scoreboard.childNode(withName: "parNumber") as? SKLabelNode {
            parLabel.text = "\(par)"
        }

        // Update strokes
        if let strokeLabel = scoreboard.childNode(withName: "strokeNumber") as? SKLabelNode {
            strokeLabel.text = "\(strokes)"
            strokeLabel.fontColor = scoringService.getScoreColor(for: score)
        }

        // Update score display
        if let scoreLabel = scoreboard.childNode(withName: "scoreDisplay") as? SKLabelNode {
            scoreLabel.text = score.displayText
            scoreLabel.fontColor = scoringService.getScoreDisplayColor(for: score)
        }
    }

    func createResetButton(near ballPosition: Position) -> SKNode {
        let buttonSize: CGFloat = 40
        let resetButton = SKShapeNode(circleOfRadius: buttonSize / 2)
        resetButton.fillColor = SKColor.red.withAlphaComponent(0.8)
        resetButton.strokeColor = .white
        resetButton.lineWidth = 3
        resetButton.zPosition = 100
        resetButton.name = "resetButton"

        // Position offset from ball
        let offsetX: CGFloat = 60
        let offsetY: CGFloat = 60
        resetButton.position = CGPoint(x: ballPosition.x + offsetX, y: ballPosition.y + offsetY)

        // Add reset icon
        let resetLabel = SKLabelNode(text: "R")
        resetLabel.fontName = "Arial-BoldMT"
        resetLabel.fontSize = 20
        resetLabel.fontColor = .white
        resetLabel.position = CGPoint.zero
        resetLabel.verticalAlignmentMode = .center
        resetButton.addChild(resetLabel)

        return resetButton
    }

    func clearResetButton(from scene: SKScene) {
        scene.childNode(withName: "resetButton")?.removeFromParent()
    }

    // MARK: - Private Helpers
    private func createHoleSection(in container: SKNode, scoreboard: SKShapeNode, hole: Int) {
        let holeContainer = SKNode()
        holeContainer.position = CGPoint(x: -container.frame.width * 0.3, y: scoreboard.position.y)
        container.addChild(holeContainer)

        let holeTitle = SKLabelNode(text: "HOLE")
        holeTitle.fontName = "Helvetica-Bold"
        holeTitle.fontSize = 14
        holeTitle.fontColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        holeTitle.position = CGPoint(x: 0, y: 12)
        holeTitle.horizontalAlignmentMode = .center
        holeContainer.addChild(holeTitle)

        let holeNumber = SKLabelNode(text: "\(hole)")
        holeNumber.fontName = "Helvetica-Bold"
        holeNumber.fontSize = 28
        holeNumber.fontColor = .white
        holeNumber.position = CGPoint(x: 0, y: -15)
        holeNumber.horizontalAlignmentMode = .center
        holeNumber.name = "holeNumber"
        holeContainer.addChild(holeNumber)
    }

    private func createParSection(in container: SKNode, scoreboard: SKShapeNode, par: Int) {
        let parContainer = SKNode()
        parContainer.position = CGPoint(x: -container.frame.width * 0.1, y: scoreboard.position.y)
        container.addChild(parContainer)

        let parTitle = SKLabelNode(text: "PAR")
        parTitle.fontName = "Helvetica-Bold"
        parTitle.fontSize = 14
        parTitle.fontColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        parTitle.position = CGPoint(x: 0, y: 12)
        parTitle.horizontalAlignmentMode = .center
        parContainer.addChild(parTitle)

        let parNumber = SKLabelNode(text: "\(par)")
        parNumber.fontName = "Helvetica-Bold"
        parNumber.fontSize = 28
        parNumber.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Gold
        parNumber.position = CGPoint(x: 0, y: -15)
        parNumber.horizontalAlignmentMode = .center
        parNumber.name = "parNumber"
        parContainer.addChild(parNumber)
    }

    private func createStrokesSection(in container: SKNode, scoreboard: SKShapeNode, strokes: Int, score: Score) {
        let strokeContainer = SKNode()
        strokeContainer.position = CGPoint(x: container.frame.width * 0.1, y: scoreboard.position.y)
        container.addChild(strokeContainer)

        let strokeTitle = SKLabelNode(text: "STROKES")
        strokeTitle.fontName = "Helvetica-Bold"
        strokeTitle.fontSize = 14
        strokeTitle.fontColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        strokeTitle.position = CGPoint(x: 0, y: 12)
        strokeTitle.horizontalAlignmentMode = .center
        strokeContainer.addChild(strokeTitle)

        let strokeNumber = SKLabelNode(text: "\(strokes)")
        strokeNumber.fontName = "Helvetica-Bold"
        strokeNumber.fontSize = 28
        strokeNumber.fontColor = scoringService.getScoreColor(for: score)
        strokeNumber.position = CGPoint(x: 0, y: -15)
        strokeNumber.horizontalAlignmentMode = .center
        strokeNumber.name = "strokeNumber"
        strokeContainer.addChild(strokeNumber)
    }

    private func createScoreSection(in container: SKNode, scoreboard: SKShapeNode, score: Score) {
        let scoreContainer = SKNode()
        scoreContainer.position = CGPoint(x: container.frame.width * 0.3, y: scoreboard.position.y)
        container.addChild(scoreContainer)

        let scoreTitle = SKLabelNode(text: "SCORE")
        scoreTitle.fontName = "Helvetica-Bold"
        scoreTitle.fontSize = 14
        scoreTitle.fontColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        scoreTitle.position = CGPoint(x: 0, y: 12)
        scoreTitle.horizontalAlignmentMode = .center
        scoreContainer.addChild(scoreTitle)

        let scoreNumber = SKLabelNode(text: score.displayText)
        scoreNumber.fontName = "Helvetica-Bold"
        scoreNumber.fontSize = 24
        scoreNumber.fontColor = scoringService.getScoreDisplayColor(for: score)
        scoreNumber.position = CGPoint(x: 0, y: -15)
        scoreNumber.horizontalAlignmentMode = .center
        scoreNumber.name = "scoreDisplay"
        scoreContainer.addChild(scoreNumber)
    }

    private func addScoreboardDividers(to container: SKNode, scoreboard: SKShapeNode, screenSize: CGSize) {
        let dividerHeight: CGFloat = 40
        let dividerPositions: [CGFloat] = [-screenSize.width * 0.2, 0, screenSize.width * 0.2]

        for xPos in dividerPositions {
            let divider = SKShapeNode(rect: CGRect(x: -0.5, y: -dividerHeight/2, width: 1, height: dividerHeight))
            divider.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6)
            divider.strokeColor = .clear
            divider.position = CGPoint(x: xPos, y: scoreboard.position.y)
            container.addChild(divider)
        }
    }
}
