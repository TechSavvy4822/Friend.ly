//
//  ProfileSetup.swift
//  Friend.ly on iOS v1.1.0
//
//  Created by Gage Dowley on 1/25/26.
//

import SwiftUI

// MARK: - Profile Customization View
struct ProfileSetup: View {
    @State private var username = ""
    @State private var bio = ""
    @State private var profile_picture: UIImage?
    @State private var profile_cover: UIImage?
    @State private var showProfilePicker = false
    @State private var showCoverPicker = false
    @State private var isCompleted = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                GreenBackground()
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 70)
                            .padding(.top, 40)
                        
                        TextField("Enter Username", text: $username)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                        
                        TextField("Enter Bio", text: $bio)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                        
                        VStack {
                            if let profile_picture {
                                Image(uiImage: profile_picture)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .overlay(
                                        Text("Profile Photo")
                                            .foregroundColor(.white)
                                    )
                            }
                            Button("Choose Profile Photo") {
                                showProfilePicker = true
                                
                            }
                        }
                        
                        VStack {
                            if let profile_cover {
                                Image(uiImage: profile_cover)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .cornerRadius(12)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .overlay(
                                        Text("Cover Photo")
                                            .foregroundColor(.white)
                                    )
                                    .cornerRadius(12)
                            }
                            Button("Choose Cover Photo") {
                                showCoverPicker = true
                            }
                        }
                        
                        Button("Finish Setup") {
                            uploadProfile()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.forestiereGreen)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(.horizontal, 20)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showProfilePicker) {
                ImagePicker(image: $profile_picture)
            }
            .sheet(isPresented: $showCoverPicker) {
                ImagePicker(image: $profile_cover)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Profile Setup"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(isPresented: $isCompleted) {
                ContentView()
            }
        }
    }
    func uploadProfile() {
        // Ensure username is not empty
        guard !username.isEmpty else {
            alertMessage = "Username cannot be empty"
            showAlert = true
            return
        }
        
        // Ensure user_id exists in UserDefaults
        guard let userID = UserDefaults.standard.string(forKey: "user_id") else {
            alertMessage = "User session not found. Please log in again."
            showAlert = true
            return
        }
        
        print("Uploading profile with userID: \(userID), username: \(username)")
        
        let url = URL(string: "http://localhost/Friend.ly/upload_profile.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Helper function to add a text field
        func addField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add required fields
        addField("user_id", userID)
        addField("username", username)
        addField("bio", bio)
        
        // Add profile image if exists
        if let profileImage = profile_picture,
           let imageData = profileImage.pngData(){
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile_image\"; filename=\"profile.png\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add cover image if exists
        if let coverImage = profile_cover,
           let coverData = coverImage.pngData() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"cover_image\"; filename=\"cover.png\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(coverData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Upload task
        URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    alertMessage = "Upload failed: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let data else {
                    alertMessage = "No response from server"
                    showAlert = true
                    return
                }
                
                // Debug: print server response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Server response: \(responseString)")
                }
                
                // Parse JSON
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   status == "success" {
                    isCompleted = true
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let errorMsg = json["error"] as? String {
                    alertMessage = "Server error: \(errorMsg)"
                    showAlert = true
                } else {
                    alertMessage = "Invalid server response"
                    showAlert = true
                }
            }
        }.resume()
    }
}

