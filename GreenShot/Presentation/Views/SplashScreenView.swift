//
//  SplashScreenView.swift
//  GreenShot
//
//  Golf game splash screen with animated logo and loading
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isLogoAnimated = false
    @State private var isTextVisible = false
    @State private var rotationAngle: Double = 0

    let onSplashComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.golfGreen,
                    Color.golfGreen.opacity(0.8),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Golf ball icon with animation
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isLogoAnimated ? 1.2 : 0.8)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isLogoAnimated)
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: rotationAngle)

                    // Golf ball dimples pattern
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .scaleEffect(isLogoAnimated ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isLogoAnimated)
                }

                // App title
                VStack(spacing: 12) {
                    Text("GreenShot")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isTextVisible ? 1.0 : 0.0)
                        .scaleEffect(isTextVisible ? 1.0 : 0.5)
                        .animation(.easeOut(duration: 1.0).delay(0.5), value: isTextVisible)

                    Text("Premium Golf Experience")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.goldenYellow)
                        .opacity(isTextVisible ? 0.8 : 0.0)
                        .animation(.easeOut(duration: 1.0).delay(1.0), value: isTextVisible)
                }

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .goldenYellow))
                        .opacity(isTextVisible ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.5).delay(1.5), value: isTextVisible)

                    Text("Loading your course...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(isTextVisible ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.5).delay(2.0), value: isTextVisible)
                }

                Spacer()
            }
            .padding(40)
        }
        .onAppear {
            startAnimations()

            // Auto-complete splash after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onSplashComplete()
            }
        }
    }

    private func startAnimations() {
        // Start logo animation
        isLogoAnimated = true
        rotationAngle = 360

        // Start text animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTextVisible = true
        }
    }
}

#Preview {
    SplashScreenView {
        print("Splash completed")
    }
}