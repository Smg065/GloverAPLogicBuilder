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
    "$not CorB"
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
							fromSpawnBallAccess.append("%s, %s" % [checkpointName, levelData.name.to_lower() + "_ball"])
				#Now create a child that represents the region
				levelData.children.append_array(
					[build_region(regionName, fromSpawnNoBallAccess, noBallRegionMethod),
					build_region(regionName + "_ball", fromSpawnBallAccess, ballRegionMethod, true)]
				)
			
			#Where you get the ball from in no ball start levels
			if !spawnWithBall:
				var formatedLevelName = levelData.name.to_lower().replace(" ", "_")
				var ballRegionName : String = formatedLevelName + "_" + eachLevel.levelRegions[eachLevel.ballOrigin].regionName.to_snake_case()
				levelData.children.append({
					"name" : formatedLevelName + "_ball",
					"access_rules" : ballRegionName
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
					var checkInfo : CheckInfo = allLocations[eachLocation].checkInfo
					var accessRules : PackedStringArray = allLocations[eachLocation].methods[regionName]
					var visRules : Array = []
					match checkInfo.checkType:
						CheckInfo.CheckType.LOADING_ZONE:
							var newInfo : Array = []
							var loadingLocation = build_location(eachWorld.worldName + " " + eachLocation, accessRules)
							loadingLocation["visibility_rules"] = ["entrance_randomization"]
							newInfo.append(loadingLocation)
							levelData.children[regionIndex].children.append(newInfo)
						CheckInfo.CheckType.ENEMY:
							visRules = ["enemy_checks", "enemy_checks_on"]
						CheckInfo.CheckType.CHECKPOINT:
							visRules = ["checkpoint_checks", "checkpoint_checks_on"]
						CheckInfo.CheckType.SWITCH:
							visRules = ["switch_checks", "switch_checks_on"]
						CheckInfo.CheckType.BUG:
							visRules = ["insect_checks", "insect_checks_on"]
						CheckInfo.CheckType.TIP:
							visRules = ["tip_checks", "tip_checks_on"]
					#Loading zones don't use the same mapping build logic
					if checkInfo.checkType != CheckInfo.CheckType.LOADING_ZONE:
						var newInfo = build_visual_locations(levelData.name, eachLocation, checkInfo, accessRules, visRules)
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

##Build out the new info to append to the location
static func build_visual_locations(levelName : String, locationName : String, checkInfo : CheckInfo, accessRules : Array[String], visRules : Array) -> Dictionary:
	if MAP_TABLE.has(levelName):
		var mapInfo := [accessRules, checkInfo, levelName]
		var baseInfo := build_location_with_map_info(locationName, mapInfo)
		#Create sections and subchecks
		if checkInfo.checkType != CheckInfo.CheckType.GARIB:
			if checkInfo.totalSubchecks > 1:
				for eachSection in checkInfo.totalSubchecks:
					baseInfo.sections.append(
						{"name" : locationName + " " + str(eachSection + 1),
						"visibility_rules" : visRules})
			else:
				baseInfo.sections.append({"name" : "",
					"visibility_rules" : visRules})
		#Create garib info
		if checkInfo.checkType == CheckInfo.CheckType.GARIB or (checkInfo.checkType == CheckInfo.CheckType.ENEMY and checkInfo.totalSubchecks < checkInfo.apIds.size()):
			var garibName = locationName
			if checkInfo.checkType == CheckInfo.CheckType.ENEMY:
				garibName += " Garib"
			else:
				garibName = garibName.trim_suffix("s")
			baseInfo.sections.append_array(create_garib_sections(garibName, checkInfo.totalSubchecks))
		return baseInfo
	else:
		return build_location(locationName, accessRules, checkInfo)

##Garibsanity under group node
static func create_garib_sections(garibName : String, garibCount : int):
	var sections : Array = []
	#Garib Groups VS Garibsanity
	if garibCount > 1:
		for eachSection in garibCount:
			var eachEntry = {"name" : garibName + " " + str(eachSection + 1),
			"visibility_rules" : ["garib_logic_garibsanity", "garib_logic"]}
			eachEntry.merge(section_icons("garib", CheckInfo.CheckType.GARIB))
			sections.append(eachEntry)
		var groupEntry = {"name" : "",
			"visibility_rules" : ["garib_logic_garib_groups"]}
		groupEntry.merge(section_icons("group", CheckInfo.CheckType.GARIB))
		sections.append(groupEntry)
	else:
		var garibEntry = {"name" : "",
		"visibility_rules" : ["garib_logic_garibsanity", "garib_logic_garib_groups", "garib_logic"]}
		garibEntry.merge(section_icons("garib", CheckInfo.CheckType.GARIB))
		sections.append(garibEntry)
	return sections

##Create a map placement
static func create_map_placement(mapName : String, inCheck : CheckInfo, shape : String = "") -> Dictionary:
	var mapInfo = MAP_TABLE[mapName]
	var popSpot = inCheck.get_pop_spot(mapInfo[1])
	var output = {
			"map" : mapInfo[0],
			"x" : popSpot.x,
			"y" : popSpot.y,
		}
	if shape != "":
		output["shape"] = shape
	return output

##Creates a region
static func build_region(inName : String, accessRules : Array[String], regionTravels : Dictionary[String, PackedStringArray], ballRegion : bool = false) -> Dictionary:
	var output = {
		"name" : inName
	}
	
	if !ballRegion:
		accessRules.append("@%s_ball"%inName)
	for eachOrigin in regionTravels:
		if eachOrigin == inName:
			continue
		for eachMethod in regionTravels[eachOrigin]:
			var newRule = "@%s"%",".join([eachOrigin, eachMethod]).trim_suffix(",")
			accessRules.append(newRule)
	if accessRules.size() > 0:
		output["access_rules"] = accessRules
	return output

##Creates a location
static func build_location(inName : String, accessRules : PackedStringArray, checkInfo : CheckInfo = null) -> Dictionary:
	var output = {
		"name" : inName
	}
	if checkInfo != null:
		var imageName = checkInfo.checkImage.resource_path.get_file().trim_suffix(".png")
		output.merge(section_icons(imageName, checkInfo.checkType))
	accessRules.erase("")
	if accessRules.size() > 0:
		output["access_rules"] = accessRules
	return output

##Create icons for
static func section_icons(sectionName : String, checkType : CheckInfo.CheckType = CheckInfo.CheckType.MISC) -> Dictionary:
	var subfolder := "items/"
	match checkType:
		CheckInfo.CheckType.ENEMY:
			subfolder = "enemies/"
		CheckInfo.CheckType.BUG:
			subfolder = "enemies/"
	var imageFilepath = "images/" + subfolder + sectionName
	return {
		"chest_unopened_img" : imageFilepath + ".png",
		"chest_opened_img" : imageFilepath + "_gray.png"
	}

##Setup map info for a location
static func build_location_with_map_info(inName : String, mapInfo : Array) -> Dictionary:
	var accessRules : PackedStringArray = mapInfo[0]
	var checkInfo : CheckInfo = mapInfo[1]
	var levelName : String = mapInfo[2]
	var output := build_location(inName, accessRules, checkInfo)
	output.map_locations = [create_map_placement(levelName, checkInfo)]
	output.sections = []
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
