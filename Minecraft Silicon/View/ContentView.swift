//
//  ContentView.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject private var launcherData: LauncherDataModel
	@State private var showDirectoryAlert = false
	
    var body: some View {
		NavigationView {
			List(launcherData.entries, id: \.baseVersion) { entry in
				NavigationLink {
					VersionDetailView(entry: entry)
				} label: {
					Label(entry.baseVersion, systemImage: entry.adaptedVersion != nil ? "cpu.fill" : "cpu")
				}.disabled(compareVersionStrings(entry.gameVersion, Constants.minSupportedMinecraftVersion) < 0)
			}
			.frame(minWidth: 100)
			
			VStack(alignment: .center, spacing: 12) {
				Text("Select a Minecraft version to get started")
					.font(.body)
					.bold()
				
				Text("If the version you want isn't appearing, run the version once through Minecraft Launcher to install it.")
					.font(.body)
					.foregroundColor(Color(nsColor: .secondaryLabelColor))
					.multilineTextAlignment(.center)
			}.padding()
		}
		.listStyle(.sidebar)
		.onAppear {
			//Make sure Minecraft directory exists
			guard FileManager.default.fileExists(atPath: Paths.minecraft.path) else {
				showDirectoryAlert = true
				
				return
			}
		}
		.alert("Minecraft installation not found", isPresented: $showDirectoryAlert, actions: {}, message: {
			Text("Please run Minecraft launcher first")
		})
		.toolbar {
			ToolbarItem {
				Button {
					launcherData.reload()
				} label: {
					Label("Reload", systemImage: "arrow.clockwise")
				}
			}
			
			/* ToolbarItem {
				Button {
					
				} label: {
					Label("Help", systemImage: "questionmark.circle")
				}
			} */
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
			.environmentObject(LauncherDataModel())
    }
}
