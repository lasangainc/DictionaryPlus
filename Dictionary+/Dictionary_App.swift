//
//  Dictionary_App.swift
//  Dictionary+
//
//  Created by Benji on 2025-08-11.
//

import SwiftUI

@main
struct Dictionary_App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 700, height: 700)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)

        Settings {
            SettingsView()
        }
    }
}
