//
//  PlayableEntry.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2022-01-22.
//

import Foundation

struct PlayableEntry {
	var baseVersion: String
	var adaptedVersion: String?
	var gameVersion: String
	var javaVersion: Int
}

///Reduces a list of Minecraft versions into a list of playable entries
func reducePlayableEntries(from versions: [MinecraftVersion]) -> [PlayableEntry] {
	//Partition the versions by whether or not they are an ARM port
	var partitionedVersions = versions
	let partitionedVersionSplit = partitionedVersions.partition { $0.isARM }
	
	let versionsIntel = partitionedVersions[..<partitionedVersionSplit]
	let versionsARM = partitionedVersions[partitionedVersionSplit...]
	
	return versionsIntel.map { intelVersion in
		//Try to find a matching ARM version
		let armVersion = versionsARM.first(where: { armVersion in armVersion.id.dropLast(Constants.suffixARM.count) == intelVersion.id })
		
		return PlayableEntry(baseVersion: intelVersion.id, adaptedVersion: armVersion?.id, gameVersion: intelVersion.gameVersion, javaVersion: intelVersion.javaVersion)
	}.sorted(by: { ($0.gameVersion, $0.baseVersion) > ($1.gameVersion, $0.baseVersion) })
}
