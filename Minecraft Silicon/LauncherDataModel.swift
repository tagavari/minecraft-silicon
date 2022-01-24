//
//  LauncherDataModel.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import Foundation

final class LauncherDataModel: ObservableObject {
	@Published var versions: [MinecraftVersion] = loadMinecraftVersions()
	@Published var profiles: [LauncherProfile] = loadLauncherProfiles()
	@Published var javaInstalls: [JavaInstall] = loadJavaInstalls()
	
	func reload() {
		versions = loadMinecraftVersions()
		profiles = loadLauncherProfiles()
		javaInstalls = loadJavaInstalls()
	}
	
	var entries: [PlayableEntry] { reducePlayableEntries(from: versions) }
}
