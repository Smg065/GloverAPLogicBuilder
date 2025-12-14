class_name PopTrackerBuilder

##A map of move names indexed by how they appear in the logic builder
const MOVE_LOOKUP = [
	"cartwheel",
	"crawl",
	"double jump",
	"slam",
	"ledge grab",
	"push",
	"locate garibs",
	"locate ball",
	"dribble",
	"l piston",
	"slap",
	"throw",
	"ball toss",
	"rubber ball",
	"bowling ball",
	"ball berring",
	"crystal_b",
	"beach",
	"death",
	"fly",
	"frog",
	"return",
	"speed",
	"sticky",
	"strength",
	"jump",
	"$not_crystal",
	"$not_bowling",
	"$sinks",
	"$floats",
	"grab",
	"$ball_up",
	"power_ball",
    "$not_bowling_or_crystal"
]

static func construct(main : Main) -> Array:
	var output := []
	var allWorlds : Array[WorldInfo] = [main.hubworld]
	allWorlds.append_array(main.allWorlds)
	for eachWorld in allWorlds:
		var worldData := {}
		worldData.name = eachWorld.worldName
		worldData.children = []
		for eachLevel in eachWorld.levels:
			##If your checkpoints spawn you with the ball by default
			var spawnWithBall = eachLevel.levelSuffix != "1" or eachWorld.worldName == "Out of This World"
			var levelData := {}
			levelData.name = eachWorld.worldShorthand + eachLevel.levelSuffix
			levelData.children = []
			var prefix := (eachWorld.worldShorthand + eachLevel.levelSuffix).to_lower()
			var allLocations : Dictionary
			#First pass to discover all locations
			for eachCheck in eachLevel.levelChecks:
				var accessRules := methods_to_access_rules(prefix, eachLevel.levelRegions, eachCheck.allMethods)
				allLocations[eachCheck.checkName] = create_abstract_location(accessRules, eachCheck)
			#First pass to discover all regions
			for eachRegion in eachLevel.levelRegions:
				var regionName : String = levelData.name.to_lower().replace(" ", "_") + "_" + eachRegion.regionName.to_snake_case()
				var ballRegionMethod := methods_to_access_rules(prefix, eachLevel.levelRegions, eachRegion.ballCheck.allMethods)
				var noBallRegionMethod := methods_to_access_rules(prefix, eachLevel.levelRegions, eachRegion.defaultCheck.allMethods)
				#You spawn from these, make sure the poptracker can handle that
				var fromSpawnBallAccess : Array[String] = []
				var fromSpawnNoBallAccess : Array[String] = []
				#Default for most
				if eachWorld.worldName != "Hubworld":
					for checkpointNumber in eachLevel.checkpointRegions.size():
						if eachLevel.checkpointRegions[checkpointNumber] != eachRegion.regionIndex:
							continue
						var checkpointName = levelData.name.to_lower() + "_cp_" + str(checkpointNumber + 1)
						if spawnWithBall:
							#Levels that spawn with the ball don't need ball contact spawn logic
							fromSpawnBallAccess.append(checkpointName)
						else:
							#Levels that spawn without the ball will put you in the ballless region
							fromSpawnNoBallAccess.append(checkpointName)
							#AND they'll require you to get to any region with the ball once to access the ball checkpoints
							fromSpawnBallAccess.append("%s, @%s" % [checkpointName, levelData.name.to_lower() + "_ball"])
				#Access locations to the regions are added here
				allLocations["%s_ball_access" % regionName] = create_abstract_location(ballRegionMethod, eachRegion.ballCheck)
				allLocations["%s_access" % regionName] = create_abstract_location(noBallRegionMethod, eachRegion.defaultCheck)
				#You can drop the ball
				allLocations["%s_access" % regionName].methods["%s_ball" % regionName] = PackedStringArray([""])
				
				#Now create a child that represents the region
				levelData.children.append_array(
					[build_region(regionName, fromSpawnNoBallAccess),
					build_region(regionName + "_ball", fromSpawnBallAccess)]
				)
			
			#Where you get the ball from in no ball start levels
			if !spawnWithBall:
				var ballRegionName : String = levelData.name.to_lower().replace(" ", "_") + "_" + eachLevel.levelRegions[eachLevel.ballOrigin].regionName.to_snake_case()
				levelData.children.append({
					"name" : levelData.name.to_lower().replace(" ", "_") + "_ball",
					"access_rules" : "@" + ballRegionName
				})
			
			#Second pass to put access locations at each region
			for regionIndex in levelData.children.size():
				var eachRegion = levelData.children[regionIndex]
				var regionName : String = eachRegion.name
				for eachLocation in allLocations:
					if !allLocations[eachLocation].methods.has(regionName):
						continue
					if !levelData.children[regionIndex].has("sections"):
						levelData.children[regionIndex]["sections"] = []
					var accessRules : PackedStringArray = allLocations[eachLocation].methods[regionName]
					match allLocations[eachLocation].checkInfo.checkType:
						CheckInfo.CheckType.REGION:
							levelData.children[regionIndex].sections.append(
								build_location(eachLocation, accessRules)
							)
						CheckInfo.CheckType.LOADING_ZONE:
							levelData.children[regionIndex].sections.append(
								build_location(eachLocation, accessRules)
							)
						_:
							levelData.children[regionIndex].sections.append(
								build_location(eachLocation, accessRules, allLocations[eachLocation].checkInfo.apIds.size())
							)
			worldData.children.append(levelData)
		output.append(worldData)
	return output

##Creates a region
static func build_region(inName : String, accessRules : Array[String]) -> Dictionary:
	accessRules.append("@%s_access" % inName)
	return {
		"name" : inName,
		"access_rules" : accessRules
	}

##Creates a location
static func build_location(inName : String, accessRules : PackedStringArray, inCount : int = 0) -> Dictionary:
	var output = {
		"name" : inName
	}
	if inCount > 0:
		output["item_count"] = inCount
	accessRules.erase("")
	if accessRules.size() > 0:
		output["access_rules"] = accessRules
	return output

##Creates a location
static func create_abstract_location(inMethods : Dictionary[String, PackedStringArray], checkInfo : CheckInfo) -> Dictionary:
	var output = {}
	output.methods = inMethods
	output.checkInfo = checkInfo
	return output

##Constructs an dictionary of regions that lead to access rules
static func methods_to_access_rules(prefix : String, regions : Array[RegionInfo], inMethods : Array[MethodData]) -> Dictionary[String, PackedStringArray]:
	var output : Dictionary[String, PackedStringArray]
	for eachMethod in inMethods:
		var methodEntries : PackedStringArray
		#Easy and hard rules
		match eachMethod.trickDifficulty:
			MethodData.TrickDifficulty.EASY:
				methodEntries.append("[$easy]")
			MethodData.TrickDifficulty.HARD:
				methodEntries.append("[$hard]")
		for eachCheck in eachMethod.requiredChecks:
			methodEntries.append("%s_%s" % [prefix.to_lower(), eachCheck.to_snake_case()])
		for eachMove in eachMethod.requiredMoves:
			methodEntries.append(MOVE_LOOKUP[eachMove])
		#Not bowling or crystal is a combined funciton
		if methodEntries.has("$not_bowling") and methodEntries.has("$not_crystal"):
			methodEntries.erase("$not_bowling")
			methodEntries.erase("$not_crystal")
			methodEntries.append("$not_bowling_or_crystal")
		#You need double jump to jump
		if methodEntries.has("double_jump") and !methodEntries.has("jump"):
			methodEntries.append("jump")
		var accessMethod := ",".join(methodEntries)
		var ballSuffix := ""
		if eachMethod.ballRequirement:
			ballSuffix = "_ball"
		var accessRegion := prefix + "_" + regions[eachMethod.regionIndex].regionName.to_snake_case() + ballSuffix
		if !output.has(accessRegion):
			output[accessRegion] = PackedStringArray()
		output[accessRegion].append(accessMethod)
	return output
