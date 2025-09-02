extends Node
class_name LogicJsonCombiner

static func combine_jsons(main : Main, loadPaths : PackedStringArray) -> Array:
	var arrayPaths = Array(loadPaths)
	var firstPath = arrayPaths.pop_back()
	var baseLogic = main.load_from_path(firstPath)
	for eachPath in arrayPaths:
		baseLogic = combine_logic(baseLogic, main.load_from_path(eachPath))
	return baseLogic

static func combine_logic(logicA, logicB):
	var logicC = []
	for worldIndex in logicA.size():
		logicC.append({})
		for levelKey in logicA[worldIndex].keys():
			#For each check in each world and level
			var combinedChecks : Dictionary
			var aChecks = logicA[worldIndex][levelKey]
			var bChecks = logicB[worldIndex][levelKey]
			#Checks in the A JSON
			for aCheckKey in aChecks.keys():
				#If both A and B have it, merge
				if bChecks.keys().has(aCheckKey):
					combinedChecks[aCheckKey] = merge_entries(aChecks[aCheckKey], bChecks[aCheckKey])
				else:
					#If only A has it, use A as a fallback
					combinedChecks[aCheckKey] = aChecks[aCheckKey]
			#Checks in the B JSON
			for bCheckKey in bChecks.keys():
				#Only look for checks that B has and not A
				if !aChecks.keys().has(bCheckKey):
					combinedChecks[bCheckKey] = bChecks[bCheckKey]
			#Apply the combined checks
			logicC[worldIndex][levelKey] = combinedChecks
	return logicC

static func merge_entries(entryA, entryB):
	var merged_entry
	#Account for Region/Location conflict
	if typeof(entryA) != typeof(entryB):
		push_error("Region and location of 2 logic files share an entry name!")
	#Otherwise, if they match, use A to figure out
	match typeof(entryA):
		#Regions
		TYPE_DICTIONARY:
			merged_entry = {
				"B" : combine_methods(entryA["B"], entryB["B"]),
				"D" : combine_methods(entryA["D"], entryB["D"])
			}
		#Locations
		TYPE_ARRAY:
			merged_entry = combine_methods(entryA, entryB)
	return merged_entry

static func combine_methods(aMethods, bMethods) -> Array[Dictionary]:
	var combinedMethods : Array[Dictionary]
	var invalidAMethods : Array[bool]
	var invalidBMethods : Array[bool]
	#Figure out which checks become invalid
	invalidAMethods.resize(aMethods.size())
	invalidBMethods.resize(bMethods.size())
	for eachB in bMethods.size():
		for eachA in aMethods.size():
			if eachA == 0 or eachB == 0:
				continue
			if invalidAMethods[eachA] || invalidBMethods[eachB]:
				continue
			match MethodData.compare_from_dictionary(aMethods[eachA], bMethods[eachB]):
				MethodData.CompareInfo.KEEP_A:
					invalidBMethods[eachB] = true
				MethodData.CompareInfo.KEEP_B:
					invalidAMethods[eachA] = true
				MethodData.CompareInfo.KEEP_BOTH:
					continue
	#Add all valid A methods
	for eachMethod in aMethods.size():
		if eachMethod == 0:
			continue
		if !invalidAMethods[eachMethod]:
			combinedMethods.append(aMethods[eachMethod])
	#Add all valid B methods
	for eachMethod in bMethods.size():
		if eachMethod == 0:
			continue
		if !invalidBMethods[eachMethod]:
			combinedMethods.append(bMethods[eachMethod])
	combinedMethods.insert(0, aMethods[0])
	return combinedMethods
