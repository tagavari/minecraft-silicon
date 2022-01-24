//
//  Profiles.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import Foundation

struct LauncherProfile: Identifiable {
	let id: String
	let created: String
	let icon: String
	let lastUsed: String
	let lastVersionId: String
	let name: String
	let type: String
	
	init(from json: LauncherProfileJSON, withID id: String) {
		self.id = id
		created = json.created
		icon = json.icon
		lastUsed = json.lastUsed
		lastVersionId = json.lastVersionId
		name = json.name
		type = json.type
	}
}

struct LauncherProfileJSON: Codable {
	let created: String
	let icon: String
	let lastUsed: String
	let lastVersionId: String
	let name: String
	let type: String
	let javaDir: String?
	
	func toJSONDictionary() -> [String: Any] {
		let data = try! JSONEncoder().encode(self)
		return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
	}
}

private struct LauncherProfileRoot: Decodable {
	let profiles: [String: LauncherProfileJSON]
}

///Loads a list of launcher profiles from disk
func loadLauncherProfiles() -> [LauncherProfile] {
	do {
		//Read the profiles from the file
		let profileRoot = try JSONDecoder().decode(LauncherProfileRoot.self, from: Data(contentsOf: Paths.launcherProfiles))
		
		//Convert the profile map into a flat array
		return profileRoot.profiles.map { (id, profile) in
			LauncherProfile.init(from: profile, withID: id)
		}
	} catch {
		LoggingHelper.main.error("Failed to load launcher profiles: \(error.localizedDescription)")
		return []
	}
}

///Generates a random string to be used as a launcher profile ID
private func generateLauncherProfileID() -> String {
	//Launcher IDs are 32-character lowercase hexadecimal strings
	(0..<32).map { _ in
		let digit = Int.random(in: 0..<16)
		return String(digit, radix: 16)
	}.joined()
}

///Creates a new launcher profile and returns it
func createLauncherProfile(name: String, version: String, javaExec: String) throws -> LauncherProfile {
	//Create the new profile
	let profileID = generateLauncherProfileID()
	let date = ISO8601DateFormatter().string(from: Date())
	let profile = LauncherProfileJSON(
		created: date,
		icon: "Grass",
		lastUsed: date,
		lastVersionId: version,
		name: name,
		type: "custom",
		javaDir: javaExec
	)
	
	//Read the launcher profile file
	var jsonData = try JSONSerialization.jsonObject(with: Data(contentsOf: Paths.launcherProfiles), options: .mutableContainers) as! [String: Any]
	
	//Add the new profile
	try DictionaryHelper.update(dictionary: &jsonData, at: ["profiles", profileID], with: profile.toJSONDictionary())
	
	//Write the changes to the launcher profile file
	do {
		let outputStream = OutputStream(url: Paths.launcherProfiles, append: false)!
		outputStream.open()
		defer { outputStream.close() }
		
		var error: NSError?
		JSONSerialization.writeJSONObject(jsonData, to: outputStream, options: [.withoutEscapingSlashes, .prettyPrinted], error: &error)

		if let error = error {
			throw error
		}
	}
	
	LoggingHelper.main.info("Created profile \(name) for version \(version) with ID \(profileID)")
	
	//Return the updated launcher profile
	return LauncherProfile(from: profile, withID: profileID)
}

///Removes a launcher profile
func removeLauncherProfile(id profileID: String) throws {
	//Read the launcher profile file
	var jsonData = try JSONSerialization.jsonObject(with: Data(contentsOf: Paths.launcherProfiles), options: .mutableContainers) as! [String: Any]
	
	//Remove the profile
	try DictionaryHelper.update(dictionary: &jsonData, at: ["profiles", profileID], with: nil)
	
	//Write the changes to the launcher profile file
	do {
		let outputStream = OutputStream(url: Paths.launcherProfiles, append: false)!
		outputStream.open()
		defer { outputStream.close() }
		
		var error: NSError?
		JSONSerialization.writeJSONObject(jsonData, to: outputStream, options: [.withoutEscapingSlashes, .prettyPrinted], error: &error)

		if let error = error {
			throw error
		}
	}
	
	LoggingHelper.main.info("Removed profile \(profileID)")
}
