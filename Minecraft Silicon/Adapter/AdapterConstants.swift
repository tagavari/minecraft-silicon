//
//  AdapterConstants.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2021-12-26.
//

import Foundation

class AdapterConstants {
	//The LWJGL version to use
	static let lwjglVersion = "3.3.0"
	
	///The ID of the current operating system, as used by Minecraft Launcher
	#if os(macOS)
	static let launcherOSID = "osx"
	#elseif os(Linux)
	static let launcherOSID = "linux"
	#elseif os(Windows)
	static let launcherOSID = "windows"
	#endif

	///The ID of the current operating system, as used by LWJGL
	#if os(macOS)
	static let lwjglOSID = "macos"
	#elseif os(Linux)
	static let lwjglOSID = "linux"
	#elseif os(Windows)
	static let lwjglOSID = "windows"
	#endif
}
