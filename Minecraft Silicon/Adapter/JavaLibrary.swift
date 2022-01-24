//
//  JavaLibrary.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2021-12-26.
//

import Foundation

struct JavaLibrary {
	let group: String
	let id: String
	let version: String
	
	///Initializes a java library from an artifact coordinate
	init(string: String) {
		let stringSplits = string.components(separatedBy: ":")
		group = stringSplits[0]
		id = stringSplits[1]
		version = stringSplits[2]
	}
}
