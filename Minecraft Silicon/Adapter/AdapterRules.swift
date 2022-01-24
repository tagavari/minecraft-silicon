//
//  AdapterRules.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2021-12-26.
//

import Foundation

///Checks an array of rules, and returns whether the rules allow this system
func checkVersionRules(_ ruleArray: [[String: Any]]) -> Bool {
	for rule in ruleArray {
		//Ignore rules that don't match this OS
		guard let rulesOS = rule["os"] as? [String: Any],
			  rulesOS["name"] as! String == AdapterConstants.launcherOSID else { continue }
		
		//Read the rule action
		let ruleAllowRaw = rule["action"] as! String
		let ruleAllow: Bool
		if ruleAllowRaw == "allow" {
			ruleAllow = true
		} else if ruleAllowRaw == "disallow" {
			ruleAllow = false
		} else {
			print("Unknown rule type: \(ruleAllowRaw)")
			exit(EXIT_FAILURE)
		}
		
		//If this rule blocks this OS, return false
		guard ruleAllow else {
			return false
		}
	}
	
	return true
}
