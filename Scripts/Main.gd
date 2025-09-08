extends Control
class_name Main

@export_category("Game Data")
@export var hubworld : WorldInfo
@export var allWorlds : Array[WorldInfo]

@export_category("Render Info")
@export var mapRender : TextureRect
@export var checkRegionToggle : Button
@export var checkContainer : Control
@export var regionContainer : Control
@export var worldSelector : OptionButton
@export var levelsButtons : HBoxContainer
@export var overworldButtons : HBoxContainer
@export var checkPrereqToggles : HBoxContainer
@export var checkName : Label

@export_category("Spawnables")
@export var checkButtonPrefab : PackedScene
@export var checkPrerequisiteButtonPrefab : PackedScene
@export var regionButtonPrefab : PackedScene
@export var allCheckButtons : Array[LevelCheckButton]
@export var allCheckPrerequisiteButtons : Array[PrerequisiteCheckButton]
@export var allRegionButtons : Array[RegionButton]

@export_category("Method Selector")
@export var methodSelector : MethodSelector

@export_category("Region Info")
@export var regionBallToggle : CheckBox
@export var regionBallToggleMethod : CheckBox
@export var regionMethodSelector : OptionButton
var lastRegion : RegionInfo

@export_category("File Info")
@export var saveFile : FileDialog
@export var saveLookupMerge : FileDialog
@export var openFiles : FileDialog
@export var openLandscape : FileDialog
@export var openMemdump : FileDialog

var isMainWorld : bool
var debugLevelData : LevelData
var web_data_callback : JavaScriptObject = null
var xmlLoadPaths : PackedStringArray
var hexMemLoadPaths : PackedStringArray

func _ready() -> void:
	web_setup()
	for eachWorld in allWorlds:
		eachWorld.setup()
	hubworld.setup()
	change_level(0)

func web_setup():
	if is_not_web():
		return
	web_data_callback = JavaScriptBridge.create_callback(web_data_loaded)
	var gdcallbacks: JavaScriptObject = JavaScriptBridge.get_interface("gd_callbacks")
	gdcallbacks.dataLoaded = web_data_callback

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Coord"):
		copy_mouse_info()
	if Input.is_action_just_pressed("Level Info"):
		print_level_data(debugLevelData)
	if Input.is_action_just_pressed("World Info"):
		for eachLevel in hubworld.levels:
			print_level_data(eachLevel)
	if Input.is_action_just_pressed("Check Info"):
		print_check_data()
	if Input.is_action_just_pressed("Total Info"):
		print_total_data()
	if Input.is_action_just_pressed("Item Pools"):
		export_item_pools()
	if Input.is_action_just_pressed("Lua Table"):
		generate_lua_table(debugLevelData)
	if Input.is_action_just_pressed("Lua Garib Groups"):
		generate_lua_garib_groups(debugLevelData)
	if Input.is_action_just_pressed("Level C Switch Case"):
		generate_rom_id_pairings(debugLevelData)
	if Input.is_action_just_pressed("ReadXML"):
		landscape_load_window()
		#generate_level_event_methods()

func copy_mouse_info() -> void:
	var newCoord : String = str(mouse_pos_to_map_spot())
	newCoord = newCoord.trim_prefix("(").trim_suffix(")")
	var eachPos = newCoord.split(',')
	newCoord = eachPos[0] + eachPos[1]
	DisplayServer.clipboard_set(str(newCoord))
	print(newCoord)

func print_level_data(levelData : LevelData) -> void:
	var totalGaribs : int = 0
	var totalGaribGroups : int = 0
	var garibGroupTypes : Dictionary
	var totalLives : int = 0
	var totalCheckpoints : int = 0
	var totalPotions : int = 0
	var totalTips : int = 0
	var totalSwitches : int = 0
	var totalGoals : int = 0
	var totalLoadingZones : int = 0
	var totalRegions : int = 0
	var totalLevelEvents : int = 0
	var totalMisc : int = 0
	var totalEnemies : int = 0
	for eachCheck in levelData.levelChecks:
		match eachCheck.checkType:
			CheckInfo.CheckType.GARIB:
				totalGaribGroups += 1
				totalGaribs += eachCheck.totalSubchecks
				var groupsKey : int = eachCheck.totalSubchecks
				if !garibGroupTypes.has(groupsKey):
					garibGroupTypes[groupsKey] = 0
				garibGroupTypes[groupsKey] += 1
			CheckInfo.CheckType.LIFE:
				totalLives += eachCheck.totalSubchecks
			CheckInfo.CheckType.CHECKPOINT:
				totalCheckpoints += eachCheck.totalSubchecks
			CheckInfo.CheckType.POTION:
				totalPotions += eachCheck.totalSubchecks
			CheckInfo.CheckType.TIP:
				totalTips += eachCheck.totalSubchecks
			CheckInfo.CheckType.SWITCH:
				totalSwitches += eachCheck.totalSubchecks
			CheckInfo.CheckType.GOAL:
				totalGoals += eachCheck.totalSubchecks
			CheckInfo.CheckType.LOADING_ZONE:
				totalLoadingZones += eachCheck.totalSubchecks
			CheckInfo.CheckType.MISC:
				totalMisc += eachCheck.totalSubchecks
			CheckInfo.CheckType.ENEMY:
				totalEnemies += eachCheck.totalSubchecks
				var hasGaribs : bool = eachCheck.totalSubchecks > eachCheck.apIds.size()
				hasGaribs = true
				if hasGaribs:
					totalGaribGroups += 1
					totalGaribs += eachCheck.totalSubchecks
					var groupsKey : int = eachCheck.totalSubchecks
					if !garibGroupTypes.has(groupsKey):
						garibGroupTypes[groupsKey] = 0
					garibGroupTypes[groupsKey] += 1
	for eachRegion in levelData.levelRegions:
		totalRegions += 1
	for eachPrereq in levelData.levelPrerequisiteChecks:
		totalLevelEvents += 1
	var levelName : String = levelData.resource_path.trim_prefix("res://Resources/Maps/").trim_suffix(".tres").capitalize()
	print(levelName + " Info:")
	print_if_not_0(totalGaribs, "Garibs")
	var garibGroupKeys : Array = garibGroupTypes.keys()
	garibGroupKeys.sort()
	for eachGroup in garibGroupKeys:
		print_if_not_0(garibGroupTypes[eachGroup], str(eachGroup) + " Groups")
	print_if_not_0(totalGaribGroups, "Garib Groups")
	print_if_not_0(totalLives, "Lives")
	print_if_not_0(totalCheckpoints, "Checkpoints")
	print_if_not_0(totalTips, "Tips")
	print_if_not_0(totalSwitches, "Switches")
	print_if_not_0(totalPotions, "Potions")
	print_if_not_0(totalEnemies, "Enemies")
	print_if_not_0(totalLoadingZones, "Loading Zones")
	print_if_not_0(totalRegions, "Regions")
	print_if_not_0(totalLevelEvents, "Level Events")
	print_if_not_0(totalMisc, "Misc")
	if totalGoals > 0:
		if totalGoals > 1:
			print(str(totalGoals) + " Goals")
		else:
			print("Has Goal")
	else:
		print("No Goal")
	print("")

func print_check_data():
	var allAndHub : Array[WorldInfo]
	allAndHub.append_array(allWorlds)
	allAndHub.append(hubworld)
	var output : String = ""
	for eachWorld in allAndHub:
		for eachLevel in eachWorld.levels:
			#Get the level name
			var levelName : String = eachWorld.worldName + " " + eachLevel.levelSuffix
			output += "\n\n" + levelName + "\n"
			
			#Catagory Lookup
			var catagoryLookup : Dictionary = {
				"Garib" : [],
				"Enemy" : [],
				"Life" : [],
				"Tip" : [],
				"Checkpoint" : [],
				"Switch" : [],
				"Goal" : [],
				"Potion" : [],
				"Misc" : []
			}
			var apIds  : Dictionary = {}
			var ids  : Dictionary = {}
			
			var enemyGaribs : Array[String] = []
			
			#Put level check info in there
			for eachCheck in eachLevel.levelChecks:
				if eachCheck.checkType == CheckInfo.CheckType.LOADING_ZONE:
					continue
				var checkType : String = CheckInfo.CheckType.keys()[eachCheck.checkType].capitalize()
				if checkType == "Bug":
					checkType = "Enemy"
				var enemyHasGaribs : bool = eachCheck.enemyGaribs
				if eachCheck.totalSubchecks == 1:
					catagoryLookup[checkType].append(eachCheck.checkName)
					apIds[eachCheck.checkName] = eachCheck.apIds[0]
					if eachCheck.ids.size() > 0:
						ids[eachCheck.checkName] = eachCheck.ids[0]
					if enemyHasGaribs:
						enemyGaribs.append(eachCheck.checkName + " Garib")
						apIds[eachCheck.checkName + " Garib"] = eachCheck.apIds[1]
						if eachCheck.ids.size() > 1:
							ids[eachCheck.checkName + " Garib"] = eachCheck.ids[1]
				else:
					for eachSubcheck in eachCheck.totalSubchecks:
						var subcheckName : String = eachCheck.checkName.trim_suffix('s') + " " + str(eachSubcheck + 1)
						catagoryLookup[checkType].append(subcheckName)
						apIds[subcheckName] = eachCheck.apIds[eachSubcheck]
						if eachCheck.ids.size() > eachSubcheck:
							ids[subcheckName] = eachCheck.ids[eachSubcheck]
						if enemyHasGaribs:
							var enemyGaribSubcheckName : String = eachCheck.checkName.trim_suffix('s') + " Garib " + str(eachSubcheck + 1)
							enemyGaribs.append(enemyGaribSubcheckName)
							apIds[enemyGaribSubcheckName] = eachCheck.apIds[eachSubcheck + eachCheck.totalSubchecks]
							if eachCheck.ids.size() > eachSubcheck + eachCheck.totalSubchecks:
								ids[enemyGaribSubcheckName] = eachCheck.ids[eachSubcheck + eachCheck.totalSubchecks]
			
			#Sort catagories alphabetically
			for eachCatagory in catagoryLookup.keys():
				catagoryLookup[eachCatagory].sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
			enemyGaribs.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
			catagoryLookup["Garib"].append_array(enemyGaribs)
			
			#For each catagory
			for eachCatagory in catagoryLookup.keys():
				var entries : Array[String] = []
				entries.append_array(catagoryLookup[eachCatagory])
				output += id_table_catagory(entries, eachCatagory, ids, apIds)
	DisplayServer.clipboard_set(output)

func id_table_catagory(tableEntries : Array[String], tableCatagory : String, ids : Dictionary, apIds : Dictionary) -> String:
	var output : String = ""
	for luaOffset in tableEntries.size():
		var eachEntry : String = tableEntries[luaOffset]
		var eachApId : String = apIds[eachEntry]
		var eachId : String = ""
		if ids.has(eachEntry):
			eachId = ids[eachEntry]
		output += id_table_entry(eachEntry, tableCatagory, eachId, eachApId)
	return output

func id_table_entry(thisCheckName : String, checkType : String, id : String, apId : String) -> String:
	return thisCheckName + ", " + checkType + ", " + id + ", " + apId + "\n"

func print_total_data():
	var totalGaribs : int = 0
	var totalGaribGroups : int = 0
	var garibGroupTypes : Dictionary
	var totalLives : int = 0
	var totalCheckpoints : int = 0
	var totalPotions : int = 0
	var totalTips : int = 0
	var totalSwitches : int = 0
	var totalGoals : int = 0
	var totalLoadingZones : int = 0
	var totalRegions : int = 0
	var totalLevelEvents : int = 0
	var totalMisc : int = 0
	var totalEnemies : int = 0
	var allWorldsAndHub : Array[WorldInfo] = allWorlds.duplicate()
	allWorldsAndHub.append(hubworld)
	for eachWorld in allWorldsAndHub:
		for eachLevel in eachWorld.levels:
			for eachCheck in eachLevel.levelChecks:
				match eachCheck.checkType:
					CheckInfo.CheckType.GARIB:
						totalGaribGroups += 1
						totalGaribs += eachCheck.totalSubchecks
						var groupsKey : int = eachCheck.totalSubchecks
						if !garibGroupTypes.has(groupsKey):
							garibGroupTypes[groupsKey] = 0
						garibGroupTypes[groupsKey] += 1
					CheckInfo.CheckType.LIFE:
						totalLives += eachCheck.totalSubchecks
					CheckInfo.CheckType.CHECKPOINT:
						totalCheckpoints += eachCheck.totalSubchecks
					CheckInfo.CheckType.POTION:
						totalPotions += eachCheck.totalSubchecks
					CheckInfo.CheckType.TIP:
						totalTips += eachCheck.totalSubchecks
					CheckInfo.CheckType.SWITCH:
						totalSwitches += eachCheck.totalSubchecks
					CheckInfo.CheckType.GOAL:
						totalGoals += eachCheck.totalSubchecks
					CheckInfo.CheckType.LOADING_ZONE:
						totalLoadingZones += eachCheck.totalSubchecks
					CheckInfo.CheckType.MISC:
						totalMisc += eachCheck.totalSubchecks
					CheckInfo.CheckType.ENEMY:
						totalEnemies += eachCheck.totalSubchecks
						if eachCheck.enemyGaribs:
							totalGaribGroups += 1
							totalGaribs += eachCheck.totalSubchecks
							var groupsKey : int = eachCheck.totalSubchecks
							if !garibGroupTypes.has(groupsKey):
								garibGroupTypes[groupsKey] = 0
							garibGroupTypes[groupsKey] += 1
			for eachRegion in eachLevel.levelRegions:
				totalRegions += 1
			for eachPrereq in eachLevel.levelPrerequisiteChecks:
				totalLevelEvents += 1
	print("Totals: ")
	print_if_not_0(totalGaribs, "Garibs")
	print_if_not_0(totalGaribGroups, "Garib Groups")
	var garibGroupKeys : Array = garibGroupTypes.keys()
	garibGroupKeys.sort()
	for eachGroup in garibGroupKeys:
		print_if_not_0(garibGroupTypes[eachGroup], str(eachGroup) + " Groups")
	print_if_not_0(totalLives, "Lives")
	print_if_not_0(totalCheckpoints, "Checkpoints")
	print_if_not_0(totalTips, "Tips")
	print_if_not_0(totalSwitches, "Switches")
	print_if_not_0(totalPotions, "Potions")
	print_if_not_0(totalEnemies, "Enemies")
	print_if_not_0(totalLoadingZones, "Loading Zones")
	print_if_not_0(totalGoals, "Goals")
	print_if_not_0(totalRegions, "Regions")
	print_if_not_0(totalLevelEvents, "Level Events")
	print_if_not_0(totalMisc, "Misc")
	print("")

func print_if_not_0(numberOfItems : int, typeName : String):
	if numberOfItems == 0:
		return
	print(str(numberOfItems) + " " + typeName)

func mouse_pos_to_map_spot() -> Vector2:
	return mapRender.get_local_mouse_position() / mapRender.size

func change_world(world : int):
	isMainWorld = world - 1 <= allWorlds.size()
	levelsButtons.visible = isMainWorld
	overworldButtons.visible = !isMainWorld
	if isMainWorld:
		set_level(allWorlds[world - 1].levels[1])
	else:
		set_level(hubworld.levels[0])

func change_level(level : int):
	if isMainWorld:
		var world : int = worldSelector.selected - 1
		set_level(allWorlds[world].levels[level])
	else:
		set_level(hubworld.levels[level])

func clear_prereq_check_buttons():
	for eachButton in allCheckPrerequisiteButtons:
		eachButton.queue_free()
	allCheckPrerequisiteButtons.clear()

func build_prereq_check_buttons(levelData : LevelData):
	for eachCheck in levelData.levelPrerequisiteChecks:
		var nextButton : PrerequisiteCheckButton = checkPrerequisiteButtonPrefab.instantiate()
		allCheckPrerequisiteButtons.append(nextButton)
		checkPrereqToggles.add_child(nextButton)
		nextButton.build_from(eachCheck, self)

func clear_check_buttons():
	for eachCheckButton in  allCheckButtons:
		eachCheckButton.queue_free()
	allCheckButtons.clear()
	select_check(null)

func build_check_buttons(levelData : LevelData):
	for eachCheck in levelData.levelChecks:
		var nextButton : LevelCheckButton = checkButtonPrefab.instantiate()
		allCheckButtons.append(nextButton)
		checkContainer.add_child(nextButton)
		nextButton.build_from(eachCheck, self)

func clear_region_buttons() -> void:
	for eachRegionButton in  allRegionButtons:
		eachRegionButton.queue_free()
	allRegionButtons.clear()
	select_check(null)

func build_region_buttons(levelData : LevelData) -> void:
	for regionIndex in levelData.levelRegions.size():
		var hue : float = float(regionIndex) / float(levelData.levelRegions.size())
		var nextButton : RegionButton = regionButtonPrefab.instantiate()
		allRegionButtons.append(nextButton)
		regionContainer.add_child(nextButton)
		var eachRegion : RegionInfo = levelData.levelRegions[regionIndex]
		nextButton.build_from(eachRegion, self, hue)

func set_level(levelData : LevelData):
	debugLevelData = levelData
	clear_check_buttons()
	clear_prereq_check_buttons()
	clear_region_buttons()
	regionMethodSelector.clear()
	mapRender.texture = levelData.mapImage
	build_check_buttons(levelData)
	build_prereq_check_buttons(levelData)
	build_region_buttons(levelData)
	methodSelector.clear()
	for eachRegion in levelData.levelRegions:
		regionMethodSelector.add_item(eachRegion.regionName)

func select_check(newCheck : CheckInfo, regionInfo : RegionInfo = null):
	#Change the last region
	lastRegion = regionInfo
	#Setup the check name
	if newCheck != null:
		checkName.text = newCheck.checkName
	else:
		checkName.text = "Select Check"
	#Make the method selector recognize the new check
	methodSelector.change_check(newCheck)

func toggle_check_prerequisite(checkButton : PrerequisiteCheckButton):
	methodSelector.update_method_prereq(checkButton, checkButton.button_pressed)

func check_prereqs_from_method(fromMethod : MethodData):
	for eachPrereq in allCheckPrerequisiteButtons:
		if fromMethod == null:
			eachPrereq.set_press_state(false)
		else:
			eachPrereq.set_press_state(fromMethod.requiredChecks.has(eachPrereq.prereqName))

func check_prereq(prereqName : String) -> bool:
	return methodSelector.check_prereq(prereqName)

func save_press() -> void:
	if is_not_web():
		saveFile.show()
	else:
		web_save()

func web_save() -> void:
	var jsonString : String = JSON.stringify(save_data(), "\t")
	var jsonBytes : PackedByteArray = jsonString.to_ascii_buffer()
	#Thank you to Kehom's Forge for making this work
	JavaScriptBridge.download_buffer(jsonBytes, "logic.json","text/plain")

func landscape_load_window() -> void:
	if is_not_web():
		openLandscape.show()
	#else:
	#	JavaScriptBridge.eval("loadData()")

func load_press() -> void:
	if is_not_web():
		openFiles.show()
	else:
		JavaScriptBridge.eval("loadData()")

func is_not_web() -> bool:
	return OS.get_name() != "Web"

func save_data() -> Array[Dictionary]:
	var saveData : Array[Dictionary]
	for eachWorld in allWorlds:
		saveData.append(eachWorld.to_save())
	saveData.append(hubworld.to_save())
	return saveData

func save_from_path(savePath : String) -> void:
	var gameData : Array[Dictionary] = save_data()
	var path = FileAccess.open(savePath,FileAccess.WRITE)
	path.store_string(JSON.stringify(gameData, "\t"))
	path.close()

func load_from_paths(loadPaths : PackedStringArray) -> void:
	#Load all the paths into an array
	var gameData
	if loadPaths.size() > 0:
		gameData = LogicJsonCombiner.combine_jsons(self, loadPaths)
	else:
		gameData = load_from_path(loadPaths[0])
	apply_glapl(gameData)

func web_data_loaded(gameData : Array) -> void:
	var jsonOutput : Array = JSON.parse_string(gameData[0])
	var glaplData : Array
	for eachDictionary in jsonOutput:
		glaplData.append(eachDictionary)
	apply_glapl(glaplData)

func load_from_path(loadPath : String) -> Array[Dictionary]:
	var path = FileAccess.open(loadPath, FileAccess.READ)
	var importArray : Array = JSON.parse_string(path.get_as_text())
	var gameData : Array[Dictionary]
	for eachDictionary in importArray:
		gameData.append(eachDictionary)
	path.close()
	return gameData

func apply_glapl(gameData : Array):
	for eachWorld in allWorlds.size():
		allWorlds[eachWorld].to_load(gameData[eachWorld])
	hubworld.to_load(gameData[allWorlds.size()])

func open_landscape_xml(loadPaths : PackedStringArray):
	xmlLoadPaths = loadPaths
	openMemdump.show()

func open_memdump(loadPaths : PackedStringArray):
	hexMemLoadPaths = loadPaths
	saveLookupMerge.show()

func save_xml_memdump_merge(saveFolder : String):
	for mergeIndex in xmlLoadPaths.size():
		var xmlLoadPath : String = xmlLoadPaths[mergeIndex]
		var hexLoadPath : String = hexMemLoadPaths[mergeIndex]
		var mergeData : String = LandscapeXML.landscape_memdump_combiner(xmlLoadPath, hexLoadPath)
		var savePath : String = saveFolder + "\\"
		var splitXmlPath = xmlLoadPath.rsplit('\\', false, 1)
		var splitHexPath = hexLoadPath.rsplit('\\', false, 1)
		var xmlFilename = splitXmlPath[1].trim_suffix(".xml")
		var hexFilename = splitHexPath[1].trim_suffix(".txt")
		print(xmlFilename + " combinding with " + hexFilename)
		savePath += xmlFilename + ".glhexml"
		var path = FileAccess.open(savePath, FileAccess.WRITE)
		path.store_string(mergeData)
		path.close()

func checks_to_regions_toggled(toggled_on: bool) -> void:
	checkContainer.visible = !toggled_on
	regionContainer.visible = toggled_on
	var buttonText : String
	if toggled_on:
		buttonText = "Regions"
	else:
		buttonText = "Checks"
	checkRegionToggle.text = buttonText

func region_ball_toggled(toggledOn: bool) -> void:
	if lastRegion != null:
		if toggledOn:
			select_check(lastRegion.ballCheck, lastRegion)
		else:
			select_check(lastRegion.defaultCheck, lastRegion)

func export_item_pools():
	var fillerItems = 0
	var allWorldsPlusHub = allWorlds.duplicate()
	var pythonLevelEventPrinout : String = ""
	var pythonCheckpointPrinout : String = ""
	var pythonGaribPrinout : String = ""
	var pythonAbilityPrinout : String = ""
	var pyPre : String = "[\""
	var pySuffix : String = "\"],\n"
	allWorldsPlusHub.append(hubworld)
	for eachWorld in allWorldsPlusHub:
		for eachLevel in eachWorld.levels:
			var worldPrefix : String = eachWorld.worldShorthand + eachLevel.levelSuffix + " "
			var garibGroupDict : Dictionary
			for eachPrereq in eachLevel.levelPrerequisiteChecks:
				pythonLevelEventPrinout += pyPre + to_python_enum(worldPrefix + eachPrereq.checkName + "\", \"1") + pySuffix
			for eachCheck in eachLevel.levelChecks:
				var checkHasItem : bool = false
				var checkIsGarib : bool = false
				match eachCheck.checkType:
					CheckInfo.CheckType.CHECKPOINT:
						checkHasItem = true
					CheckInfo.CheckType.GARIB:
						checkIsGarib = true
					CheckInfo.CheckType.ENEMY:
						checkIsGarib = true
				if checkHasItem:
					var checkString = worldPrefix + eachCheck.checkName + "\", \"1"
					pythonCheckpointPrinout += pyPre + to_python_enum(checkString) + pySuffix
				elif checkIsGarib:
					if garibGroupDict.has(eachCheck.totalSubchecks):
						garibGroupDict[eachCheck.totalSubchecks] += 1
					else:
						garibGroupDict[eachCheck.totalSubchecks] = 1
				else:
					fillerItems += 1
			var garibGroupKeys : Array = garibGroupDict.keys()
			garibGroupKeys.sort()
			for eachKey in garibGroupKeys:
				var numberOfBundles : int = garibGroupDict[eachKey]
				pythonGaribPrinout += pyPre + to_python_enum(worldPrefix + str(eachKey) + " Garibs\", \"") + str(numberOfBundles) + pySuffix
	
	var moveList : Array[String] = [
		"Jump",
		"Cartwheel",
		"Crawl",
		"Double Jump",
		"Fist Slam",
		"Ledge Grab",
		"Push",
		"Locate Garibs",
		"Locate Ball",
		"Dribble",
		"L Piston",
		"Slap",
		"Throw",
		"Ball Toss",
		"Beachball",
		"Death Potion",
		"Helicopter Potion",
		"Frog Potion",
		"Boomerang Ball",
		"Speed Potion",
		"Sticky Potion",
		"Hercules Potion",
		"Grab",
		"Rubber Ball",
		"Bowling Ball",
		"Ball Bearing",
		"Crystal",
		"Power Ball"]
	
	for eachMove in moveList:
		pythonAbilityPrinout += pyPre + to_python_enum(eachMove) + "\", \"1" + pySuffix
	print("level_event_table = [\n" + pythonLevelEventPrinout + "]")
	print("checkpoint_table = [\n" + pythonCheckpointPrinout + "]")
	print("garib_table = [\n" + pythonGaribPrinout + "]")
	print("ability_table = [\n" + pythonAbilityPrinout + "]")
	print("Filler, " + str(fillerItems - moveList.size()))

func generate_lua_garib_groups(inputLevel : LevelData):
	var garibGroups : Dictionary
	for eachCheck in inputLevel.levelChecks:
		match eachCheck.checkType:
			CheckInfo.CheckType.GARIB:
				garibGroups[eachCheck.checkName] = lua_garib_groups(eachCheck.apIds)
			CheckInfo.CheckType.ENEMY:
				if eachCheck.totalSubchecks < eachCheck.apIds.size():
					var idsForUse : Array[String] = []
					var key : String = eachCheck.checkName.trim_suffix("s") + " Garibs"
					for eachApId in eachCheck.apIds.size():
						#Ignore the enemies themselves
						if eachApId < eachCheck.totalSubchecks:
							continue
						#Get the garibs the enemies have
						idsForUse.append(eachCheck.apIds[eachApId])
					garibGroups[key] = lua_garib_groups(idsForUse)
	
	var outputString : String = lua_level_name(inputLevel)
	for groupKeys in garibGroups.keys():
		var groupEntry : Dictionary = garibGroups[groupKeys]
		outputString += "\t\t[\"" + groupKeys + "\"] = {\n"
		outputString += "\t\t\t[\"id\"] = " + groupEntry["id"] + ",\n"
		outputString += "\t\t\t[\"garibs\"] = " + "{\n"
		for eachEntryGaribIndex in groupEntry["garibs"].size():
			var suffix = "\"\n"
			if eachEntryGaribIndex != groupEntry["garibs"].size() - 1:
				suffix = "\",\n"
			var apIdHex : String = groupEntry["garibs"][eachEntryGaribIndex]
			outputString += "\t\t\t\t\"" + str(apIdHex.hex_to_int()) + suffix
		outputString += "\t\t\t}\n"
		outputString += "\t\t},\n"
	outputString += "\t}"
	print(outputString)
	DisplayServer.clipboard_set(outputString)

func lua_level_name(inputLevel : LevelData, padding : bool = true) -> String:
	var levelName : String
	levelName = inputLevel.resource_path.split("/")[inputLevel.resource_path.split("/").size() - 1]
	levelName = levelName.trim_suffix(".tres")
	levelName = levelName.trim_suffix("onus")
	levelName = levelName.trim_suffix("oss")
	levelName = levelName.left(-1)
	levelName = levelName.to_upper()
	var prefixString = ""
	var sufixString = ""
	if padding:
		prefixString = "\t[\""
		sufixString = "\"] = {\n"
	var levelIndicator = "L" + inputLevel.levelSuffix
	if inputLevel.levelSuffix == "!":
		levelIndicator = "BOSS"
	elif inputLevel.levelSuffix == "?":
		levelIndicator = "BONUS"
	return prefixString + "AP_" + levelName + "_" + levelIndicator + sufixString

func lua_garib_groups(apIds : PackedStringArray) -> Dictionary:
	var id : String = "\"" + str(apIds[0].hex_to_int() + 10000) + "\""
	return {
		"id":id,
		"garibs":apIds
	}
	

func generate_lua_table(inputLevel : LevelData):
	var outString : String = lua_level_name(inputLevel)
	var outputDict : Dictionary = {
		"GARIBS" : PackedStringArray(),
		"ENEMY_GARIBS" : PackedStringArray(),
		"ENEMIES" : PackedStringArray(),
		"LIFE" : PackedStringArray(),
		"TIP" : PackedStringArray(),
		"CHECKPOINT" : PackedStringArray(),
		"SWITCH" : PackedStringArray(),
		"POTIONS" : PackedStringArray()
	}
	@warning_ignore("unused_variable")
	var goal_ap_id : String = ""
	var enemyGaribOrigin : Dictionary = {}
	for eachCheck in inputLevel.levelChecks:
		match eachCheck.checkType:
			#Garibs
			CheckInfo.CheckType.GARIB:
				for eachId in eachCheck.apIds:
					outputDict["GARIBS"].append(eachId)
			#Enemy garibs act seperate
			CheckInfo.CheckType.ENEMY:
				for eachIdIndex in eachCheck.apIds.size():
					#The first half of APIDs are always enemies
					if eachIdIndex < eachCheck.totalSubchecks:
						#If there's a fronthalf, it's the enemies themselves
						outputDict["ENEMIES"].append(eachCheck.apIds[eachIdIndex])
					else:
						#If there's a backhalf, it's the garibs
						outputDict["ENEMY_GARIBS"].append(eachCheck.apIds[eachIdIndex])
						enemyGaribOrigin[eachCheck.apIds[eachIdIndex]] = eachCheck.apIds[eachIdIndex - eachCheck.totalSubchecks]
			#Bugs are just enemies that never have garibs
			CheckInfo.CheckType.BUG:
				for eachId in eachCheck.apIds:
					outputDict["ENEMIES"].append(eachId)
			#Lives
			CheckInfo.CheckType.LIFE:
				for eachId in eachCheck.apIds:
					outputDict["LIFE"].append(eachId)
			#Tips
			CheckInfo.CheckType.TIP:
				for eachId in eachCheck.apIds:
					outputDict["TIP"].append(eachId)
			#Checkpoints
			CheckInfo.CheckType.CHECKPOINT:
				for eachId in eachCheck.apIds:
					outputDict["CHECKPOINT"].append(eachId)
			#Switches
			CheckInfo.CheckType.SWITCH:
				for eachId in eachCheck.apIds:
					outputDict["SWITCH"].append(eachId)
			#Potions
			CheckInfo.CheckType.POTION:
				for eachId in eachCheck.apIds:
					outputDict["POTIONS"].append(eachId)
			#Goal
			CheckInfo.CheckType.GOAL:
				goal_ap_id = eachCheck.apIds[0]
	
	#Sort them
	for eachKey in outputDict.keys():
		var sorted : Array[String]
		sorted.assign(outputDict[eachKey])
		sorted.sort_custom(func(a, b): return a.hex_to_int() < b.hex_to_int())
		outputDict[eachKey] = PackedStringArray(sorted)
	
	#Create a pre-table entry for the Goal APID
	if goal_ap_id != "":
		outString += "\t\t[\"" + "GOAL" + "\"] = \"" + str(goal_ap_id.hex_to_int()) + "\",\n"
	#Create the table
	for eachKey in outputDict.keys():
		var idsForUse : PackedStringArray = outputDict[eachKey]
		if idsForUse.size() == 0:
			continue
		if eachKey != "ENEMY_GARIBS":
			outString += lua_table_subsection("\"" + eachKey + "\"", idsForUse)
		else:
			outString += lua_table_subsection("\"" + eachKey + "\"", idsForUse, enemyGaribOrigin, outputDict["GARIBS"].size())
	
	outString += "\t}"
	print(outString)
	DisplayServer.clipboard_set(outString)

func lua_table_subsection(sectionName : String, ids : PackedStringArray, objectIds : Dictionary = {}, garibOffset : int = 0, finalEntry : bool = false) -> String:
	var outString : String = "\t\t[" + sectionName + "] = {\n"
	ids.sort()
	for eachIdIndex in ids.size():
		outString += "\t\t\t[\"" + str(ids[eachIdIndex].hex_to_int())
		outString += "\"] = {\n\t\t\t\t['id'] = " + ids[eachIdIndex]
		var offset : int = eachIdIndex + garibOffset
		outString += ",\n\t\t\t\t['offset'] = " + str(offset)
		if objectIds.size() > 0:
			outString += ",\n\t\t\t\t['object_id'] = " + objectIds[ids[eachIdIndex]]
		outString += ",\n\t\t\t}"
		if finalEntry && ids.size() - 1 == eachIdIndex:
			outString += "\n"
		else:
			outString += ",\n"
	outString += "\t\t}"
	if finalEntry:
		outString += "\n"
	else:
		outString += ",\n"
	return outString

func generate_rom_id_pairings(inputLevel : LevelData):
	var output : String = ""
	var lastMatchingType : CheckInfo.CheckType = CheckInfo.CheckType.MISC
	var luaOffset = 0
	var worldName : String = "WORLD_NAME" #lua_level_name(inputLevel, false)
	var worldAddress = "\t\t\tap_memory.pc.worlds[" + worldName + "]."
	for eachCheck in inputLevel.levelChecks:
		output += "\t\t//" + eachCheck.checkName + "\n"
		var checkType : String = "CHECKTYPE"
		var checkTypeEnum = eachCheck.checkType
		if checkTypeEnum == CheckInfo.CheckType.BUG:
			checkTypeEnum = CheckInfo.CheckType.ENEMY
		if lastMatchingType != checkTypeEnum:
			luaOffset = 0
			lastMatchingType = checkTypeEnum
		match checkTypeEnum:
			CheckInfo.CheckType.GARIB:
				checkType = "garibs"
			CheckInfo.CheckType.LIFE:
				checkType = "life_checks"
			CheckInfo.CheckType.TIP:
				checkType = "tip_checks"
			CheckInfo.CheckType.CHECKPOINT:
				checkType = "checkpoint_checks"
			CheckInfo.CheckType.SWITCH:
				checkType = "switch_checks"
			CheckInfo.CheckType.ENEMY:
				checkType = "enemy_checks"
			CheckInfo.CheckType.POTION:
				checkType = "potion_checks"
			CheckInfo.CheckType.GOAL:
				continue
			CheckInfo.CheckType.LOADING_ZONE:
				continue
		var checkTypeOutput = checkType + "["
		for eachSubcheck in eachCheck.totalSubchecks:
			var eachId
			if eachCheck.ids.size() <= eachSubcheck:
				eachId = "!!ID MISSING!!"
			else:
				eachId = eachCheck.ids[eachSubcheck]
			var memoryAddress : String = worldAddress + checkTypeOutput
			output += "\t\tcase " + eachId + ":\n"
			output += memoryAddress + str(luaOffset) + "].ptr = ptr;\n"
			if eachCheck.checkType == CheckInfo.CheckType.GARIB:
				output += memoryAddress + str(luaOffset) + "].object_id = item_id;\n"
			luaOffset += 1
			output += "\t\t\treturn;\n"
	print(output)
	DisplayServer.clipboard_set(output)

func generate_level_event_methods():
	var worldsAndHub : Array[WorldInfo]
	worldsAndHub.append_array(allWorlds)
	worldsAndHub.append(hubworld)
	var rulesOutput : String = ""
	var lookupOutput : String = ""
	for eachWorld in worldsAndHub:
		for eachLevel in eachWorld.levels:
			for eachEventItem in eachLevel.levelPrerequisiteChecks:
				var prefix : String = eachWorld.worldShorthand + eachLevel.levelSuffix
				var itemName : String = "\"" + prefix + " " + eachEventItem.checkName + "\""
				var ruleName : String = "rule_event_" + prefix.to_lower() + "_" + (eachEventItem.checkName).to_snake_case().replace("'", "")
				var newRule : String = "def "
				newRule += ruleName
				newRule += "(self, state : CollectionState) -> bool:\n\treturn state.has("
				newRule += itemName
				newRule += ", self.player)\n"
				rulesOutput += newRule
				lookupOutput += "\t" + itemName + " : \t\t\t\t\t\t" + ruleName + ",\n"
	var output : String = rulesOutput + "\n\n"
	output += "event_lookup = {\n" + lookupOutput + "}"
	print(output)
	DisplayServer.clipboard_set(str(output))

func to_python_enum(inString : String) -> String:
	#inString = inString.to_upper().replace(' ', '_')
	return inString
