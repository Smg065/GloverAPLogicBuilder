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

const HUBWORLD_GATES_TABLE = {
	"Hubworld Atlantis Gate" : "@Ball Turn-In 1",
	"Hubworld Carnival Gate" : "@Ball Turn-In 2",
	"Hubworld Pirate's Cove Gate" : "@Ball Turn-In 2",
	"Hubworld Prehistoric Gate" : "@Ball Turn-In 4",
	"Hubworld Fortress of Fear Gate" : "@Ball Turn-In 4",
	"Hubworld Out of This World Gate" : "@Ball Turn-In 6",
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
			var prefix := eachWorld.worldShorthand + eachLevel.levelSuffix
			#First pass to discover all regions
			for eachRegion in eachLevel.levelRegions:
				var regionName : String = levelData.name.to_lower().replace(" ", "_") + "_" + eachRegion.regionName.to_snake_case()
				var ballRegionMethod := methods_to_access_rules(prefix, eachLevel.levelRegions, eachRegion.ballCheck.allMethods)
				var noBallRegionMethod := methods_to_access_rules(prefix, eachLevel.levelRegions, eachRegion.defaultCheck.allMethods)
				#You spawn from these, make sure the poptracker can handle that
				var fromSpawnBallAccess : Array[String] = []
				var fromSpawnNoBallAccess : Array[String] = []
				#Default for most
				if eachLevel.checkpointRegions.size() > 1:
					for checkpointNumber in eachLevel.checkpointRegions.size():
						if eachLevel.checkpointRegions[checkpointNumber] != eachRegion.regionIndex:
							continue
						var checkpointName = levelData.name + " Checkpoint " + str(checkpointNumber + 1)
						if spawnWithBall:
							#Levels that spawn with the ball don't need ball contact spawn logic
							fromSpawnBallAccess.append(checkpointName)
						else:
							#Levels that spawn without the ball will put you in the ballless region
							fromSpawnNoBallAccess.append(checkpointName)
							#AND they'll require you to get to any region with the ball once to access the ball checkpoints
							fromSpawnBallAccess.append("%s, %s" % [checkpointName, "@%s_ball" % levelData.name.to_lower()])
				#Now create a child that represents the region
				var validRegions := []
				var noballRegion := build_region("reg_" + regionName, fromSpawnNoBallAccess, noBallRegionMethod)
				var ballRegion := build_region("reg_" + regionName + "_ball", fromSpawnBallAccess, ballRegionMethod, true)
				if "access_rules" in ballRegion:
					validRegions.append(ballRegion)
				validRegions.append(noballRegion)
				levelData.children.append_array(validRegions)
			
			#Where you get the ball from in no ball start levels
			if !spawnWithBall:
				var formatedLevelName = levelData.name.to_lower().replace(" ", "_")
				var ballRegionName : String = formatedLevelName + "_" + eachLevel.levelRegions[eachLevel.ballOrigin].regionName.to_snake_case()
				levelData.children.append({
					"name" : formatedLevelName + "_ball",
					"access_rules" : ballRegionName
				})
			
			#Second pass to put locations in the collection
			for eachCheck in eachLevel.levelChecks:
				var accessRules := methods_to_access_rules(prefix, eachLevel.levelRegions, eachCheck.allMethods)
				var visRules = []
				var locationName : String = eachCheck.checkName
				if eachCheck.allMethods.size() == 0 and eachWorld.worldName != "Hubworld":
					continue
				match eachCheck.checkType:
					CheckInfo.CheckType.LOADING_ZONE:
						var loadingLocation = build_location(locationName, accessRules)
						if eachWorld.worldName != "Hubworld":
							loadingLocation["name"] =  " ".join([eachWorld.worldName, loadingLocation["name"]])
							loadingLocation["access_rules"].append("Open Levels")
						levelData.children.append(loadingLocation)
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
				if eachCheck.checkType != CheckInfo.CheckType.LOADING_ZONE:
					var newInfo = build_sectioned_locations(locationName, eachCheck, accessRules, visRules)
					levelData.children.append(newInfo)
			#Level randomization
			var level_prefix = levelData.name.to_lower().replace(" ", "_")
			if eachWorld.worldName != "Hubworld":
				if eachLevel.levelSuffix != "H":
					levelData["access_rules"] = [level_prefix]
				else:
					var loadingZoneName : String = eachWorld.worldName
					match loadingZoneName:
						"Fortress":
							loadingZoneName = "Fear"
						"Out of This World":
							loadingZoneName = "OotW"
					levelData["access_rules"] = ["@%s Hub Entry"%loadingZoneName]
			
			worldData.children.append(levelData)
		output.append(worldData)
	#Ball turn-in logic
	for eachEntry in range(1, 7):
		output[0].children[1].children[2].sections[eachEntry].access_rules = ["$hub%s"%(eachEntry)]
	#Hubworld loading zones
	for eachEntry in output[0].children[0].children.size():
		if not "access_rules" in output[0].children[0].children[eachEntry]:
			continue
		var extraRules := PackedStringArray()
		for eachRule in output[0].children[0].children[eachEntry].access_rules.size():
			for eachReplace in HUBWORLD_GATES_TABLE:
				var originalRule : String = output[0].children[0].children[eachEntry].access_rules[eachRule]
				if originalRule.contains(eachReplace):
					extraRules.append(originalRule.replace(eachReplace, "Open Worlds"))
					output[0].children[0].children[eachEntry].access_rules[eachRule] = originalRule.replace(eachReplace, HUBWORLD_GATES_TABLE[eachReplace])
		output[0].children[0].children[eachEntry].access_rules.append_array(extraRules)
	return output

##Build out the new info to append to the location
static func build_sectioned_locations(locationName : String, checkInfo : CheckInfo, accessRules : Array[String], visRules : Array) -> Dictionary:
	var baseInfo := build_location(locationName, accessRules, checkInfo)
	baseInfo.sections = []
	#Create sections and subchecks
	if checkInfo.checkType != CheckInfo.CheckType.GARIB:
		if checkInfo.totalSubchecks > 1:
			for eachSection in checkInfo.totalSubchecks:
				var newSection = {"name" : locationName + " " + str(eachSection + 1)}
				if visRules.size() > 0:
					newSection["visibility_rules"] = visRules
				baseInfo.sections.append(newSection)
		else:
			var newSection = {"name" : ""}
			if visRules.size() > 0:
				newSection["visibility_rules"] = visRules
			baseInfo.sections.append(newSection)
	#Create garib info
	if checkInfo.checkType == CheckInfo.CheckType.GARIB or (checkInfo.checkType == CheckInfo.CheckType.ENEMY and checkInfo.totalSubchecks < checkInfo.apIds.size()):
		var garibName = locationName
		if checkInfo.checkType == CheckInfo.CheckType.ENEMY:
			garibName += " Garib"
		else:
			garibName = garibName.trim_suffix("s")
		var singleFallback : String = ""
		if checkInfo.checkType == CheckInfo.CheckType.ENEMY and checkInfo.totalSubchecks == 1:
			singleFallback = "Garib"
		baseInfo.sections.append_array(create_garib_sections(garibName, checkInfo.totalSubchecks, singleFallback))
	return baseInfo

##Garibsanity under group node
static func create_garib_sections(garibName : String, garibCount : int, singleFallback : String = ""):
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
		var garibEntry = {"name" : singleFallback,
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
static func build_region(inName : String, accessRules : Array[String], regionTravels : PackedStringArray, ballRegion : bool = false) -> Dictionary:
	var output = {
		"name" : inName
	}
	if !ballRegion:
		accessRules.append("@%s_ball"%inName)
	
	#Remove self-ref rules
	for eachTravel in regionTravels.size():
		regionTravels[eachTravel] = regionTravels[eachTravel].replace("@" + inName, "")
		regionTravels[eachTravel] = regionTravels[eachTravel].replace(",,", ",")
	while regionTravels.erase(""):
		continue
	
	accessRules.append_array(regionTravels)
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
		if imageName.to_lower().ends_with("target"):
			imageName = "target"
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
static func build_location_with_map_info(inName : String, checkInfo : CheckInfo, levelName : String, accessRules : PackedStringArray = PackedStringArray()) -> Dictionary:
	var output := build_location(inName, accessRules, checkInfo)
	output.map_locations = [create_map_placement(levelName, checkInfo)]
	output.sections = []
	return output

##Constructs an dictionary of regions that lead to access rules
static func methods_to_access_rules(prefix : String, regions : Array[RegionInfo], inMethods : Array[MethodData]) -> PackedStringArray:
	var output : PackedStringArray = PackedStringArray()
	for eachMethod in inMethods:
		var methodEntries : PackedStringArray
		#Easy and hard rules
		match eachMethod.trickDifficulty:
			MethodData.TrickDifficulty.EASY:
				methodEntries.append("[easy]")
			MethodData.TrickDifficulty.HARD:
				methodEntries.append("[hard]")
		for eachCheck in eachMethod.requiredChecks:
			methodEntries.append("%s %s" % [prefix, eachCheck])
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
		var ballSuffix := ""
		if eachMethod.ballRequirement:
			ballSuffix = "_ball"
		var accessRegion := "@reg_%s_%s%s" % [prefix.to_lower(), regions[eachMethod.regionIndex].regionName.to_snake_case(), ballSuffix]
		methodEntries.append(accessRegion)
		var accessMethod := ",".join(methodEntries)
		output.append(accessMethod)
	return output


##
static func get_all_map_locations(main : Main) -> Dictionary:
	var output = {"children" : []}
	for eachWorld in main.allWorlds:
		var worldInfo = {"name" : eachWorld.worldName,
		"children" : []}
		for eachLevel in eachWorld.levels:
			var mapName := eachWorld.worldShorthand + eachLevel.levelSuffix
			if !mapName in MAP_TABLE:
				continue
			var levelInfo = {"name" : eachWorld.worldName + " " + eachLevel.levelSuffix,
			"children" : []}
			for eachCheck in eachLevel.levelChecks:
				var mapCheck := {"name":eachCheck.checkName,
					"sections" : {
						"ref" : "/".join([eachWorld.worldName, mapName, eachCheck.checkName])},
					"map_locations":create_map_placement(mapName, eachCheck)}
				levelInfo.children.append(mapCheck)
			worldInfo["children"].append(levelInfo)
		output["children"].append(worldInfo)
	return output
