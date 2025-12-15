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

const MAP_TABLE = {
	"Atl1" : ["a1", Vector2i(1492, 910)],
	"Atl2" : ["a2", Vector2i(1616, 583)],
	"Atl3" : ["a3", Vector2i(1041, 1002)],
	"Atl?" : ["ab", Vector2i(1743, 175)],
	"Crn1" : ["c1", Vector2i(875, 1006)],
	"Crn2" : ["c2", Vector2i(1122, 1040)],
	"Crn3" : ["c3", Vector2i(883, 958)],
	"FoF1" : ["f1", Vector2i(1599, 631)],
	"FoF2" : ["f2", Vector2i(1544, 985)],
	"FoF3" : ["f3", Vector2i(947, 947)],
	"FoF?" : ["fb", Vector2i(926, 926)],
	"Prt1" : ["p1", Vector2i(1444, 1000)],
	"Prt2" : ["p2", Vector2i(1900, 1010)],
	"Prt3" : ["p3", Vector2i(1808, 730)],
	"Prt?" : ["pb", Vector2i(360, 1000)],
	"Pht1" : ["pr1", Vector2i(1215, 1058)],
	"Pht2" : ["pr2", Vector2i(1870, 525)],
	"Pht3" : ["pr3", Vector2i(1177, 944)],
	"Pht?" : ["prb", Vector2i(1815, 146)],
	"Otw1" : ["s1", Vector2i(1920, 850)],
	"Otw2" : ["s2", Vector2i(1665, 972)],
	"Otw3" : ["s3", Vector2i(1264, 1035)],
	"Otw?" : ["sb", Vector2i(1920, 1080)],
	"Hubworld" : ["hub", Vector2i(934, 977)],
	"Tutorial" : ["well", Vector2i(1655, 249)]
}

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
					if !levelData.children[regionIndex].has("children"):
						levelData.children[regionIndex].children = []
					var accessRules : PackedStringArray = allLocations[eachLocation].methods[regionName]
					var newInfo : Dictionary
					var visRules : Array = []
					match allLocations[eachLocation].checkInfo.checkType:
						CheckInfo.CheckType.REGION:
							newInfo = build_location(eachLocation, accessRules)
						CheckInfo.CheckType.LOADING_ZONE:
							newInfo = build_location(eachLocation, accessRules)
						CheckInfo.CheckType.ENEMY:
							visRules = ["enemy_checks"]
						CheckInfo.CheckType.CHECKPOINT:
							visRules = ["checkpoint_checks"]
						CheckInfo.CheckType.SWITCH:
							visRules = ["switch_checks"]
						CheckInfo.CheckType.BUG:
							visRules = ["insect_checks"]
						CheckInfo.CheckType.TIP:
							visRules = ["tip_checks"]
						_:
							newInfo = build_location(eachLocation, accessRules, allLocations[eachLocation].checkInfo)
							if MAP_TABLE.has(levelData.name):
								var mapInfo = MAP_TABLE[levelData.name]
								if !newInfo.has("map_locations"):
									newInfo.map_locations = []
								newInfo.map_locations.append({
									"map" : mapInfo[0],
									"x" : int(allLocations[eachLocation].checkInfo.checkSpot.x * mapInfo[1].x),
									"y" : int(allLocations[eachLocation].checkInfo.checkSpot.y * mapInfo[1].y),
								})
								if visRules.size() > 0:
									if !newInfo.has("visibility_rules"):
										newInfo.visibility_rules = []
									newInfo.visibility_rules.append_array(visRules)
								if !newInfo.has("sections"):
									newInfo.sections = []
								if allLocations[eachLocation].checkInfo.checkType != CheckInfo.CheckType.GARIB:
									if allLocations[eachLocation].checkInfo.totalSubchecks > 1:
										for eachSection in allLocations[eachLocation].checkInfo.apIds.size():
											newInfo.sections.append({"name" : eachLocation + " " + str(eachSection + 1)})
									else:
										newInfo.sections.append({"name" : eachLocation})
								else:
									#Garib Groups VS Garibsanity
									for eachSection in allLocations[eachLocation].checkInfo.apIds.size():
										newInfo.sections.append({"name" : eachLocation + " " + str(eachSection + 1),
										"visibility_rules" : ["garibsanity"]})
									newInfo.sections.append({"name" : eachLocation,
										"visibility_rules" : ["garib_groups"]})
					levelData.children[regionIndex].children.append(newInfo)
			
			#If it's not a numbered level, get the checkpoint for free
			var level_prefix = levelData.name.to_lower().replace(" ", "_")
			if !eachLevel.levelSuffix.is_valid_int():
				levelData["hosted_item"] = level_prefix + "_cp_1"
			
			#Level randomization
			if eachLevel.levelSuffix != "Hubworld":
				levelData["access_rules"] = [level_prefix]
			
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
static func build_location(inName : String, accessRules : PackedStringArray, checkInfo : CheckInfo = null) -> Dictionary:
	var output = {
		"name" : inName
	}
	if checkInfo != null:
		output["item_count"] = checkInfo.apIds.size()
		var imageFilepath = "images/items/" + checkInfo.checkImage.resource_path.get_file().trim_suffix(".png").to_snake_case()
		output["chest_unopened_img"] = imageFilepath + ".png"
		output["chest_opened_img"] = imageFilepath + "_gray.png"
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
