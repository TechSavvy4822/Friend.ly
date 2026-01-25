//
//  RootView_Profile.swift
//  Friend.ly on iOS v1.1.0
//
//  Created by Gage Dowley on 12/22/25.
//

import SwiftUI

struct RootView_Profile: View {
    @AppStorage("FirstTimeProfileCustomization") private var FirstTimeProfileCustomization = false

    var body: some View {
        if FirstTimeProfileCustomization {
            ContentView()
        } else {
            CustomizingView()
        }
    }
}
