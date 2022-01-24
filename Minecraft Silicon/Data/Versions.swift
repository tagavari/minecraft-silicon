//
//  Versions.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import Foundation

///Represents Minecraft Silicon-specific data about a single Minecraft version
struct MinecraftVersion: Identifiable {
	let folder: String //The name of the folder that holds this version
	let id: String //The ID of this version
	let gameVersion: String //The base Minecraft version of this version (ex. '1.18', useful for snapshots)
	let javaVersion: Int //The major Java version required to run this version
	let isARM: Bool //Whether this version has been patched
}

///Represents a Java version for a JSON Minecraft version
private struct BasicMinecraftVersionJSONJavaVersion: Decodable {
	let component: String
	let majorVersion: Int
}

///Represents the bare mimimum JSON structure of a Minecraft version
private struct BasicMinecraftVersionJSON: Decodable {
	let id: String
	let inheritsFrom: String?
	let javaVersion: BasicMinecraftVersionJSONJavaVersion?
	let assets: String
}

///Loads Minecraft versions from disk
func loadMinecraftVersions() -> [MinecraftVersion] {
	var versions: [MinecraftVersion] = []
	let decoder = JSONDecoder()
	
	//Iterate over version folders
	for versionDir in try! FileManager.default.contentsOfDirectory(at: Paths.versionsDir, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
		//Make sure the file is a folder
		guard try! versionDir.resourceValues(forKeys: [.isDirectoryKey]).isDirectory! else { continue }
		
		let versionDirName = versionDir.lastPathComponent
		
		//Get the version JSON
		let versionJSONFile = versionDir.appendingPathComponent("\(versionDirName).json")
		
		let versionJSON: BasicMinecraftVersionJSON
		do {
			versionJSON = try decoder.decode(BasicMinecraftVersionJSON.self, from: Data(contentsOf: versionJSONFile))
		} catch {
			LoggingHelper.main.error("Failed to read Minecraft version for \(versionDirName): \(error.localizedDescription)")
			continue
		}
		
		if versionJSON.inheritsFrom != nil {
			/* //If this version inherits from another version, wait until we index all base versions before resolving this one
			extensionVersions.append((versionDirName, versionJSON)) */
			continue
		} else if let javaVersion = versionJSON.javaVersion {
			//Add the version
			versions.append(MinecraftVersion(
				folder: versionDirName,
				id: versionJSON.id,
				gameVersion: versionJSON.assets,
				javaVersion: javaVersion.majorVersion,
				isARM: versionJSON.id.hasSuffix("-arm")
			))
		} else {
			LoggingHelper.main.error("Failed to read Minecraft version for \(versionDirName): Unsupported JSON structure")
		}
	}
	
	//Resolve inherited versions
	/* for (extensionVersionDir, extensionVersion) in extensionVersions {
		//Search the indexes for the base version
		let baseVersionID = extensionVersion.inheritsFrom!
		guard let baseVersion = versions.first(where: { $0.id == baseVersionID }) else {
			Logging.main.error("Unable to find base version \(baseVersionID) for version \(extensionVersion.id)")
			continue
		}
		
		versions.append(MinecraftVersion(
			folder: extensionVersionDir,
			id: extensionVersion.id,
			javaVersion: baseVersion.javaVersion,
			isARM: baseVersion.id.hasSuffix("-arm")
		))
	} */
	
	return versions
}
