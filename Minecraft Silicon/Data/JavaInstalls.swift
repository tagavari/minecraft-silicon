//
//  JavaInstalls.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import Foundation

struct JavaInstall: Equatable {
	let name: String
	let path: URL
	let version: Int
}

func loadJavaInstalls() -> [JavaInstall] {
	//Make sure the directory exists
	let javaInstallDirArray: [URL]
	do {
		javaInstallDirArray = try FileManager.default.contentsOfDirectory(at: Paths.javaVirtualMachines, includingPropertiesForKeys: [], options: [])
	} catch {
		LoggingHelper.main.error("Failed to list Java install directories: \(error.localizedDescription)")
		return []
	}
	
	var javaInstallArray: [JavaInstall] = []
	
	for installDir in javaInstallDirArray {
		let homeDir = installDir.appendingPathComponent("Contents/Home", isDirectory: true)
		let releaseFile = homeDir.appendingPathComponent("release", isDirectory: false)
		
		//Read the Java release details
		let releaseDetails: String
		do {
			releaseDetails = try String(contentsOf: releaseFile, encoding: .ascii)
		} catch {
			LoggingHelper.main.error("Failed to read release details of Java install at \(releaseFile.path): \(error.localizedDescription)")
			continue
		}
		
		//Iterate over the lines of the release property file
		var releaseOSName, releaseOSArch: String?
		var releaseJavaVersion: Int?
		for line in releaseDetails.split(whereSeparator: \.isNewline) {
			let lineComponents = line.components(separatedBy: "=")
			guard lineComponents.count == 2 else {
				LoggingHelper.main.error("Failed to read release details of Java install at \(releaseFile.path): unrecognized release property file line \(line)")
				continue
			}
			let key = lineComponents[0]
			var value = lineComponents[1]
			//Remove quotes from string values
			if value.first == "\"" && value.last == "\"" {
				let lowerBound = value.index(value.startIndex, offsetBy: 1)
				let upperBound = value.index(value.endIndex, offsetBy: -1)
				value = String(value[lowerBound..<upperBound])
			}
			
			switch key {
				case "OS_NAME":
					releaseOSName = value
				case "OS_ARCH":
					releaseOSArch = value
				case "JAVA_VERSION":
					//Only keep the major Java version
					let versionSplit = value.split(separator: ".")
					guard versionSplit.count > 0 else { continue }
					releaseJavaVersion = Int(versionSplit[0])
				default: break
			}
		}
		
		//Make sure we have all the properties, and that this version is applicable
		guard let releaseOSName = releaseOSName,
			  releaseOSName == "Darwin",
			  let releaseOSArch = releaseOSArch,
			  releaseOSArch == "aarch64",
			  let releaseJavaVersion = releaseJavaVersion else {
				  LoggingHelper.main.error("Failed to read release details of Java install at \(releaseFile.path): incomplete release property file")
				  continue
		}
		
		javaInstallArray.append(JavaInstall(name: installDir.lastPathComponent, path: homeDir, version: releaseJavaVersion))
	}
	
	return javaInstallArray
}
