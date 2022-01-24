//
//  VersionDetailView.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import SwiftUI

struct VersionDetailView: View {
	@EnvironmentObject private var launcherData: LauncherDataModel
	
	@State private var isLoading = false
	@State private var adapterError: Error?
	@State private var isShowAdapterError = false
	@State private var selectedJavaInstall: String = ""
	
	var entry: PlayableEntry
	
	///A list of Java installations that can be used with this version
	private var matchingJavaInstalls: [JavaInstall] {
		launcherData.javaInstalls.filter { $0.version == entry.javaVersion }
	}
	
	///The first launcher profile that can be used with this version
	private var matchingArmProfile: LauncherProfile? {
		//Match the ARM version of this playable entry
		guard let versionID = entry.adaptedVersion else { return nil }
		
		return launcherData.profiles.first { profile in
			profile.lastVersionId == versionID
		}
	}

    var body: some View {
		VStack(alignment: .center, spacing: 12) {
			let versionExists = entry.adaptedVersion != nil
			
			if !versionExists || matchingArmProfile == nil {
				let javaInstalls = matchingJavaInstalls
				if javaInstalls.isEmpty {
					Text("No matching Java installation available")
						.font(.body)
						.bold()
					Text("Please download Java \(entry.javaVersion) to play this version")
						.font(.body)
						.foregroundColor(Color(nsColor: .secondaryLabelColor))
					
					Button("Download JRE") {
						let url = URL(string: "https://www.azul.com/downloads/?os=macos&architecture=arm-64-bit&package=jre&show-old-builds=true#download-openjdk")!
						NSWorkspace.shared.open(url)
					}
				} else {
					Spacer()
					
					if !versionExists {
						Text("Minecraft \(entry.baseVersion) can be adapted for Apple Silicon")
							.font(.body)
							.bold()
					} else {
						Text("Adapted for Apple Silicon")
							.font(.body)
							.bold()
						
						Text("A launcher profile must be created to play this version")
							.font(.body)
							.foregroundColor(Color(nsColor: .secondaryLabelColor))
					}
					
					Picker("Java installation:", selection: $selectedJavaInstall) {
						ForEach(javaInstalls.sorted { $0.name < $1.name }, id: \.name) { java in
							Text(java.name).tag(java.name)
						}
					}.frame(maxWidth: 300)
					
					Button(versionExists ? "Create Launcher Profile " : "Create Version and Profile") {
						Task.init {
							//Start loading
							isLoading = true
							
							do {
								//Adapt the version
								let versionID: String
								if versionExists {
									versionID = entry.adaptedVersion!
								} else {
									versionID = try await Adapter.adaptVersion(versionID: entry.baseVersion)
								}
								
								//Create the launcher profile
								let javaExecPath = javaInstalls.first { $0.name == selectedJavaInstall }!.path.appendingPathComponent("bin/java", isDirectory: false).path
								let launcherProfile = try createLauncherProfile(name: "\(entry.baseVersion) ARM", version: versionID, javaExec: javaExecPath)
								
								//Update the state
								if !versionExists {
									let updatedMinecraftVersion = MinecraftVersion(folder: versionID, id: versionID, gameVersion: entry.gameVersion, javaVersion: entry.javaVersion, isARM: true)
									launcherData.versions.append(updatedMinecraftVersion)
								}
								launcherData.profiles.append(launcherProfile)
							} catch {
								//Show the error
								adapterError = error
								isShowAdapterError = true
							}
							
							isLoading = false
						}
					}
					.keyboardShortcut(.defaultAction)
					.sheet(isPresented: $isLoading) {
						ProgressView("Generating version…")
							.padding(32)
							.fixedSize()
					}
					.alert("Failed to adapt Minecraft version", isPresented: $isShowAdapterError, actions: {}, message: {
						if let description = adapterError?.localizedDescription {
							Text(description)
						}
					})
					
					Spacer()
					
					Text("Make sure to restart Minecraft Launcher after creating an adapted version")
						.font(.footnote)
						.multilineTextAlignment(.center)
				}
			} else {
				Spacer()
				
				Text("Adapted for Apple Silicon")
					.font(.body)
					.bold()
				
				Text("Play with the launcher profile \"\(matchingArmProfile!.name)\"")
					.font(.body)
					.foregroundColor(Color(nsColor: .secondaryLabelColor))
				
				Button("Quit and Open Minecraft Launcher") {
					Task.init {
						do {
							try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Minecraft.app"), configuration: NSWorkspace.OpenConfiguration())
							NSApplication.shared.terminate(self)
						} catch {
							//Ignore, error is automatically displayed to the user
						}
					}
				}
				
				Spacer()
				
				Text("TIP: To play with mods like OptiFine or mod loaders like Forge, select the base version as \"\(entry.adaptedVersion!)\" in the installer")
					.font(.footnote)
					.multilineTextAlignment(.center)
			}
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
		.background(Color(nsColor: .textBackgroundColor))
		.navigationTitle("Minecraft \(entry.baseVersion)")
		.onAppear {
			selectedJavaInstall = matchingJavaInstalls.first?.name ?? ""
		}
		.onChange(of: matchingJavaInstalls) { matchingJavaInstalls in
			selectedJavaInstall = matchingJavaInstalls.first?.name ?? ""
		}
    }
}

struct VersionDetailView_Previews: PreviewProvider {
    static var previews: some View {
		VersionDetailView(entry: PlayableEntry(
			baseVersion: "1.18",
			adaptedVersion: nil,
			gameVersion: "1.18",
			javaVersion: 17
		))
			.environmentObject(LauncherDataModel())
			.frame(width: 850, height: 700)
    }
}
