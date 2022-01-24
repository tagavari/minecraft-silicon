//
//  Adapter.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2021-12-25.
//

import Foundation

class Adapter {
	///Adapts the base Minecraft version to an Apple Silicon-compatible version, returning its version ID
	static func adaptVersion(versionID: String) async throws -> String {
		let versionDir = Paths.versionsDir.appendingPathComponent(versionID, isDirectory: true)
		
		//Make sure the version directory is actually a version directory
		let versionFileJSON = versionDir.appendingPathComponent("\(versionID).json")
		let versionFileJar = versionDir.appendingPathComponent("\(versionID).jar")
		guard FileManager.default.fileExists(atPath: versionFileJSON.path),
			  FileManager.default.fileExists(atPath: versionFileJar.path) else {
				  throw AdapterError("\(versionID) is not a valid Minecraft version")
			  }
		
		LoggingHelper.main.info("Adapting Minecraft version \(versionID) for arm64")
		
		//Read the version file
		var jsonData = try JSONSerialization.jsonObject(with: Data(contentsOf: versionFileJSON), options: .mutableContainers) as! [String: Any]
		
		//Read the base version
		//let baseVersion = jsonData["assets"] as! String
		
		//Iterate over libraries
		for (i, var library) in (jsonData["libraries"] as! [[String: Any]]).enumerated() {
			//Match library rules
			if let ruleArray = library["rules"] as? [[String: Any]] {
				guard checkVersionRules(ruleArray) else { continue }
			}
			
			//Parse the library name
			let libraryInfo = JavaLibrary(string: library["name"] as! String)
			
			if libraryInfo.group == "org.lwjgl" {
				/**
				 LWJGL provides Apple Silicon-compatible builds starting with version 3.3.0,
				 so we'll swap out any references to LWJGL libraries to their official releases.
				 */
				LoggingHelper.main.debug("Checking library \(libraryInfo.id)...")
				
				let downloads = library["downloads"] as! [String: Any]
				
				do {
					//Get the official LWJGL file info
					let lwjglFileURL = "https://build.lwjgl.org/release/\(AdapterConstants.lwjglVersion)/bin/\(libraryInfo.id)/\(libraryInfo.id).jar"
					let (lwjglFileHash, lwjglFileSize) = try await analyzeLibraryURL(url: URL(string: lwjglFileURL)!)
					
					//Upgrade the common artifact
					var libraryArtifact = (downloads["artifact"] as! [String: Any])
					libraryArtifact["sha1"] = lwjglFileHash
					libraryArtifact["size"] = lwjglFileSize
					libraryArtifact["url"] = lwjglFileURL
					
					try DictionaryHelper.update(dictionary: &library, at: ["downloads", "artifact"], with: libraryArtifact)
				}
				
				//Check for natives
				if let nativesID = (library["natives"] as? [String: String])?[AdapterConstants.launcherOSID] {
					LoggingHelper.main.debug("Checking library \(libraryInfo.id) natives...")
					
					//Get the official LWJGL file info
					let lwjglFileURL = "https://build.lwjgl.org/release/\(AdapterConstants.lwjglVersion)/bin/\(libraryInfo.id)/\(libraryInfo.id)-natives-\(AdapterConstants.lwjglOSID)-arm64.jar"
					let (lwjglFileHash, lwjglFileSize) = try await analyzeLibraryURL(url: URL(string: lwjglFileURL)!)
					
					//Update the library classifier
					var libraryClassifier = (downloads["classifiers"] as! [String: [String: Any]])[nativesID]!
					//let libraryPath = URL(fileURLWithPath: libraryClassifier["path"] as! String, isDirectory: false)
					//libraryClassifier["path"] = libraryPath.deletingLastPathComponent().appendingPathComponent(libraryPath.deletingPathExtension().lastPathComponent + Constants.suffixARM + "." + libraryPath.pathExtension).relativePath
					libraryClassifier["sha1"] = lwjglFileHash
					libraryClassifier["size"] = lwjglFileSize
					libraryClassifier["url"] = lwjglFileURL
					
					try DictionaryHelper.update(dictionary: &library, at: ["downloads", "classifiers", nativesID], with: libraryClassifier)
				}
				
				//Copy back to jsonData
				var jsonDataLibraries = jsonData["libraries"] as! [[String: Any]]
				jsonDataLibraries[i] = library
				jsonData["libraries"] = jsonDataLibraries
			} else if libraryInfo.group == "ca.weblite" && libraryInfo.id == "java-objc-bridge" {
				/**
				 This is a library used make native Objective-C calls from Java.
				 It has been updated to produce universal builds, but Minecraft uses an older version that doesn't support Apple Silicon.
				 */
				LoggingHelper.main.debug("Checking library \(libraryInfo.id)...")
				
				let downloads = library["downloads"] as! [String: Any]
				
				do {
					//Get the native file info
					let updatedFileURL = "https://repo1.maven.org/maven2/ca/weblite/java-objc-bridge/1.1/java-objc-bridge-1.1.jar"
					let (updatedFileHash, updatedFileSize) = try await analyzeLibraryURL(url: URL(string: updatedFileURL)!)
					
					//Upgrade the common artifact
					var libraryArtifact = (downloads["artifact"] as! [String: Any])
					libraryArtifact["sha1"] = updatedFileHash
					libraryArtifact["size"] = updatedFileSize
					libraryArtifact["url"] = updatedFileURL
					
					try DictionaryHelper.update(dictionary: &library, at: ["downloads", "artifact"], with: libraryArtifact)
				}
				
				//Copy back to jsonData
				var jsonDataLibraries = jsonData["libraries"] as! [[String: Any]]
				jsonDataLibraries[i] = library
				jsonData["libraries"] = jsonDataLibraries
			}
		}

		//Update version ID
		jsonData["id"] = (jsonData["id"] as! String) + Constants.suffixARM
		
		//Create the new the version directory
		let updatedVersionID = versionID + Constants.suffixARM
		let updatedVersionDir = Paths.versionsDir.appendingPathComponent(updatedVersionID)
		let updatedVersionFileJSON = updatedVersionDir.appendingPathComponent("\(updatedVersionID).json")
		let updatedVersionFileJar = updatedVersionDir.appendingPathComponent("\(updatedVersionID).jar")
		
		if !FileManager.default.fileExists(atPath: updatedVersionDir.path) {
			try FileManager.default.createDirectory(at: updatedVersionDir, withIntermediateDirectories: false, attributes: .none)
		}
		
		//Copy over the jar file
		try FileManager.default.copyItem(at: versionFileJar, to: updatedVersionFileJar)
		
		//Write the updated JSON file
		do {
			let outputStream = OutputStream(url: updatedVersionFileJSON, append: false)!
			outputStream.open()
			defer { outputStream.close() }
			
			var error: NSError?
			JSONSerialization.writeJSONObject(jsonData, to: outputStream, options: [.withoutEscapingSlashes], error: &error)

			if let error = error {
				throw error
			}
		}
		
		LoggingHelper.main.info("Successfully created Minecraft version version \(updatedVersionID)")
		
		return updatedVersionID
	}
}

struct AdapterError: Error {
	let message: String
	
	init(_ message: String) {
		self.message = message
	}
	
	public var errorDescription: String { message }
}
