//
//  Paths.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import Foundation

class Paths {
	//The primary Minecraft directory
	static let minecraft = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Library/Application Support/minecraft", isDirectory: true)
	
	//Minecraft versions directory
	static let versionsDir = minecraft.appendingPathComponent("versions", isDirectory: true)
	
	//Launcher profiles file
	static let launcherProfiles = minecraft.appendingPathComponent("launcher_profiles.json", isDirectory: false)
	
	//JVM installations
	static let javaVirtualMachines = URL(fileURLWithPath: "/Library/Java/JavaVirtualMachines", isDirectory: true)
}
