import SwiftUI
import UIKit

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Data Model
struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.accent,
                Color.forestiereGreen,
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 14)
                .repeatForever(autoreverses: true)
            ) {
                animate.toggle()
            }
        }
    }
}

// MARK: - View
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage: Int = 0
    
    private let haptic = UIImpactFeedbackGenerator(style: .soft)
    
    let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Welcome to Friend.ly",
            subtitle: "A safe-to-use, community based social media platform.",
            imageName: "onboarding-01"
        ),
        OnboardingSlide(
            title: "Connect. Share. Smile.",
            subtitle: "Friend.ly brings you closer to friends and new connections in a safe, positive space where sharing moments is easy and fun.",
            imageName: "onboarding-02"
        ),
        OnboardingSlide(
            title: "Your Social World, Your Way.",
            subtitle: "Customize your feed, discover communities, and share your life with friends who care—Friend.ly makes social networking friendly again.",
            imageName: "onboarding-03"
        ),
        OnboardingSlide(
            title: "Your Space, Your Rules",
            subtitle: "Create an account and make it yours.",
            imageName: "onboarding-01"
        )
    ]
    
    var body: some View {
        ZStack {
            
            // MARK: Background
            LiquidGlassBackground()
            
            VStack {
                
                // MARK: Top Bar
                HStack {
                    Button {
                        haptic.impactOccurred()
                        if currentPage > 0 { currentPage -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.primary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .opacity(currentPage == 0 ? 0 : 1)
                    
                    Spacer()
                    
                    Button("Skip") {
                        haptic.impactOccurred()
                        hasSeenOnboarding = true
                    }
                    .foregroundStyle(.primary.opacity(0.9))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .padding()
                
                Spacer()
                
                // MARK: Pages
                TabView(selection: $currentPage) {
                    ForEach(slides.indices, id: \.self) { index in
                        VStack(spacing: 34) {
                            
                            // Mock iPhone with Glass Overlay
                            ZStack {
                                Image(slides[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 320)
                                
                            }
                            .offset(y: currentPage == index ? 0 : 14)
                            .animation(.easeInOut(duration: 0.6), value: currentPage)
                            
                            VStack(spacing: 12) {
                                Text(slides[index].title)
                                    .font(.custom("Mercenary-Medium", size: 28))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text(slides[index].subtitle)
                                    .font(.custom("Mercenary-Regular", size: 17))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                
                            }
                            .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 580)
                
                // MARK: Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { dot in
                        Capsule()
                            .fill(
                                dot == currentPage
                                ? Color.white
                                : Color.white.opacity(0.3)
                            )
                            .frame(
                                width: dot == currentPage ? 16 : 6,
                                height: 6
                            )
                    }
                }
                .padding(.top, 12)
                
                Spacer()
                
                // MARK: Continue Button
                Button {
                    haptic.impactOccurred()
                    if currentPage < slides.count - 1 {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        hasSeenOnboarding = true // RootView will navigate to ContentView
                    }
                } label: {
                    Text(currentPage == slides.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.white)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.blue.opacity(0.45), lineWidth: 1)
                        )
                }
            }
        }
    }
}

