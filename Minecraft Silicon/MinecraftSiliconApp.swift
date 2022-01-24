//
//  MinecraftSiliconApp.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationWillFinishLaunching(_ notification: Notification) {
		NSWindow.allowsAutomaticWindowTabbing = false
	}
}

@main
struct MinecraftSiliconApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	private let launcherDataModel = LauncherDataModel()
	
    var body: some Scene {
        WindowGroup {
            ContentView()
				.environmentObject(launcherDataModel)
		}
		.commands {
			CommandGroup(replacing: .newItem, addition: {})
			
			CommandGroup(after: .sidebar) { 
				Button("Reload") {
					launcherDataModel.reload()
				}.keyboardShortcut("r", modifiers: [.command])
			}
			
			SidebarCommands()
		}
    }
}
