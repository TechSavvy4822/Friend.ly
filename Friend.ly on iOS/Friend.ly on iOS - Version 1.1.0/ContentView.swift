import SwiftUI

// MARK: - ContentView (Login)
struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var showSignup = false
    @State private var showLoginError = false
    @State private var loginErrorMessage = ""
    
    let signupURL = URL(string: "http://localhost/Friend.ly/signup.php")!
    let loginURL  = URL(string: "http://localhost/Friend.ly/login.php")!
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.accentColor.ignoresSafeArea()
                
                VStack(spacing: 5) {
                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 70)
                        .padding(.top, 40)

                    Spacer().frame(height: 450)

                    // Login Form
                    VStack(spacing: 16) {
                        textFieldWithPlaceholder("Email Address", text: $email)
                        secureFieldWithPlaceholder("Password", text: $password)
                    }

                    Spacer().frame(height: 30)

                    // Login Button
                    Button(action: loginUser) {
                        Text("Log In")
                            .font(.headline)
                            .bold()
                            .frame(width: 110, height: 45)
                            .background(Color.forestiereGreen)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 3)
                    }
                    .alert("Login Error", isPresented: $showLoginError) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(loginErrorMessage)
                    }
                    .offset(x: 120, y: -20)
                    .navigationDestination(isPresented: $isLoggedIn) {
                        RootView_Profile()
                    }

                    // Signup prompt
                    HStack(spacing: 8) {
                        Text("New to Friend.ly?")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))

                        Button(action: { showSignup = true }) {
                            Text("Signup")
                                .foregroundColor(Color.blue.opacity(0.8))
                                .font(.system(size: 20, weight: .bold))
                        }
                        .navigationDestination(isPresented: $showSignup) {
                            SignupView()
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
    
    // MARK: - Login via PHP API
    func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            loginErrorMessage = "Please fill in both fields."
            showLoginError = true
            return
        }

        guard let url = URL(string: "http://localhost/Friend.ly/login.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                loginErrorMessage = "Network error: \(error.localizedDescription)"
                showLoginError = true
                return
            }

            // Check the HTTP response code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                DispatchQueue.main.async {
                    loginErrorMessage = "Server returned error code \(httpResponse.statusCode)"
                    showLoginError = true
                }
                return
            }

            // Parse the JSON response
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    loginErrorMessage = "Invalid server response."
                    showLoginError = true
                }
                return
            }

            // Handle the response status
            DispatchQueue.main.async {
                if let status = json["status"] as? String, status == "success" {
                    let userID = json["user_id"] as! Int
                    let firstName = json["first_name"] as! String
                    let email = json["email"] as! String

                    UserDefaults.standard.set(String(userID), forKey: "user_id")
                    UserDefaults.standard.set(firstName, forKey: "first_name")
                    UserDefaults.standard.set(email, forKey: "email")

                    DispatchQueue.main.async {
                        isLoggedIn = true
                    }

                } else {
                    loginErrorMessage = json["error"] as? String ?? "Login failed"
                    showLoginError = true
                }
            }
        }.resume()
    }

    struct HomeView: View {
        @State private var firstName: String = ""

        var body: some View {
            ZStack {
                Color.green.opacity(0.1).ignoresSafeArea()
                VStack {
                    Text("Welcome, \(firstName)!")
                        .font(.largeTitle)
                        .bold()
                        .onAppear {
                            // Retrieve the first name from UserDefaults
                            if let name = UserDefaults.standard.string(forKey: "first_name") {
                                firstName = name
                            }
                        }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    // MARK: - Signup Screen
    struct SignupView: View {
        @State private var firstName = ""
        @State private var lastName = ""
        @State private var email = ""
        @State private var password = ""
        @State private var dateOfBirth = Date()
        @State private var showAlert = false
        @State private var alertMessage = ""
        
        var thirteenYearsAgo: Date {
            Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
        }
        
        var body: some View {
            ZStack {
                Color.accentColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 70)
                            .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            textFieldWithPlaceholder("First Name", text: $firstName)
                            textFieldWithPlaceholder("Last Name", text: $lastName)
                            textFieldWithPlaceholder("Email Address", text: $email)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            secureFieldWithPlaceholder("Password", text: $password)
                            
                            Text("Date of Birth:")
                                .bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                            
                            DatePicker(
                                "Select Date",
                                selection: $dateOfBirth,
                                in: ...thirteenYearsAgo,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                            .frame(width: 350, height: 320)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                            
                            Text("You must be 13 years of age or older to use this app.")
                                .bold()
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            
                            Button(action: registerUser) {
                                Text("Create Account")
                                    .bold()
                                    .frame(width: 200, height: 50)
                                    .background(Color.forestiereGreen)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.bottom, 50)
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Signup"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        // MARK: - Signup via PHP API
        func registerUser() {
            guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
                alertMessage = "Please fill in all fields."
                showAlert = true
                return
            }

            guard let url = URL(string: "http://localhost/Friend.ly/signup.php") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dobString = dateFormatter.string(from: dateOfBirth)

            let body: [String: Any] = [
                "first_name": firstName,
                "last_name": lastName,
                "email": email,
                "password": password,
                "dob": dobString
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        alertMessage = "Network error: \(error.localizedDescription)"
                        showAlert = true
                    }
                    return
                }

                // Check the HTTP response code
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        alertMessage = "Server returned error code \(httpResponse.statusCode)"
                        showAlert = true
                    }
                    return
                }

                // Print the raw response data for debugging
                if let data = data {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response Data: \(jsonString)")  // Log raw response for debugging
                    }
                }

                // Parse the JSON response
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async {
                        alertMessage = "Invalid server response."
                        showAlert = true
                    }
                    return
                }

                // Handle the response status
                DispatchQueue.main.async {
                    if let status = json["status"] as? String, status == "success" {
                        alertMessage = "Account created successfully!"
                    } else {
                        alertMessage = json["error"] as? String ?? "Signup failed"
                    }
                    showAlert = true
                }
            }.resume()
        }
    }
}

// MARK: - Reusable Fields
extension View {
    func textFieldWithPlaceholder(_ placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundColor(.black.opacity(0.5)).padding(.leading, 25)
            }
            TextField(placeholder, text: text)
                .padding().frame(width: 350, height: 45)
                .background(Color.white).foregroundColor(.black)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }

    func secureFieldWithPlaceholder(_ placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundColor(.black.opacity(0.5)).padding(.leading, 25)
            }
            SecureField(placeholder, text: text)
                .padding().frame(width: 350, height: 45)
                .background(Color.white).foregroundColor(.black)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
        }
    }
}
