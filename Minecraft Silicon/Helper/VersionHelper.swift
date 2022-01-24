//
//  VersionHelper.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-24.
//

import Foundation

///Compares 2 version strings, returning a positive number if version 1 is greater than version 2
func compareVersionStrings(_ version1String: String, _ version2String: String) -> Int {
	//Split the strings by their version numbers
	let versionArray1 = version1String.split(separator: ".").map { Int($0)! }
	let versionArray2 = version2String.split(separator: ".").map { Int($0)! }
	
	//Compare the versions
	for i in (0..<max(versionArray1.count, versionArray2.count)) {
		//Get the version digit
		let version1 = i >= versionArray1.count ? 0 : versionArray1[i]
		let version2 = i >= versionArray2.count ? 0 : versionArray2[i]
		
		//If the digits aren't the same, return the comparison
		let comparison = version1 - version2
		if comparison != 0 {
			return comparison
		}
	}
	
	//We compared all the digits, versions are the same
	return 0
}
