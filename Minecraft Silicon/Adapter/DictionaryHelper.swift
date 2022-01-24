//
//  DictionaryHelper.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2021-12-27.
//

import Foundation

struct DictionaryUpdateError: Error {
	let key: String
	
	init(key: String) {
		self.key = key
	}
	
	public var errorDescription: String {
		"Tried to assign to key \(key) at invalid dictionary position"
	}
}

class DictionaryHelper {
	///Updates a nested dictionary value using its path
	static func update(dictionary dict: inout [String: Any], at keys: [String], with value: Any?) throws {
		guard !keys.isEmpty else { return }
		
		if keys.count == 1 {
			dict[keys[0]] = value
			return
		}
		
		//Index the levels following the key path
		var levels: [[String: Any]] = []
		
		for key in keys.dropLast() {
			if let lastLevel = levels.last {
				guard let currentLevel = lastLevel[key] as? [String: Any] else {
					throw DictionaryUpdateError(key: key)
				}
				levels.append(currentLevel)
			} else {
				let key = keys[0]
				guard let firstLevel = dict[key] as? [String: Any] else {
					throw DictionaryUpdateError(key: key)
				}
				levels.append(firstLevel)
			}
		}
		
		//Set the value
		levels[levels.indices.last!][keys.last!] = value
		
		//Apply the updated value back up the dictionary tree
		for index in levels.indices.dropLast().reversed() {
			levels[index][keys[index + 1]] = levels[index + 1]
		}
		
		dict[keys[0]] = levels[0]
	}
}
