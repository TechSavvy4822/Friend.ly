import SwiftUI
import UIKit

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Slide Model
struct CustomizingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

// MARK: - Background
struct Background: View {
    var body: some View {
        LinearGradient(
            colors: [Color.white, Color.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [ Color.accent, Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Customizing View (Slides)
struct CustomizingView: View {
    @State private var currentPage: Int = 0
    @State private var navigateToCustomize = false
    private let haptic = UIImpactFeedbackGenerator(style: .soft)
    private var firstName: String { UserDefaults.standard.string(forKey: "first_name") ?? "Friend" }

    private var slides: [CustomizingSlide] {
        [
            CustomizingSlide(title: "Welcome to Friend.ly, \(firstName)!",
                             subtitle: "Now that you've created an account, let's continue setting up your profile!",
                             imageName: "onboarding-01"),
            CustomizingSlide(title: "Customize Your Profile",
                             subtitle: "Add a profile picture, bio, and preferences to make your account truly yours.",
                             imageName: "onboarding-03"),
            CustomizingSlide(title: "Explore & Connect",
                             subtitle: "Discover friends and communities that share your interests.",
                             imageName: "onboarding-02")
        ]
    }
    

    var body: some View {
        NavigationStack {
            ZStack {
                Background()
                VStack {
                    Spacer()

                    TabView(selection: $currentPage) {
                        ForEach(slides.indices, id: \.self) { index in
                            VStack(spacing: 20) {
                                Image(slides[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 700)
                                Text(slides[index].title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                Text(slides[index].subtitle)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .tag(index)
                            .padding(.horizontal, 24)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 500)

                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { dot in
                            Capsule()
                                .fill(dot == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: dot == currentPage ? 16 : 6, height: 6)
                        }
                    }
                    .padding(.top, 12)

                    // Continue / Finish Setup Button
                    Button {
                        haptic.impactOccurred()
                        if currentPage < slides.count - 1 {
                            withAnimation(.easeInOut(duration: 0.4)) { currentPage += 1 }
                        } else {
                            // Navigate to CustomizeView
                            navigateToCustomize = true
                        }
                    } label: {
                        Text(currentPage == slides.count - 1 ? "Finish Setup" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundColor(.white)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.blue.opacity(0.45), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationDestination(isPresented: $navigateToCustomize) {
                ProfileSetup()
            }
        }
    }
}
