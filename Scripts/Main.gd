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
@export var openFiles : FileDialog

var isMainWorld : bool
var debugLevelData : LevelData
var web_data_callback : JavaScriptObject = null

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
	allAndHub.append(hubworld)
	allAndHub.append_array(allWorlds)
	for worldIndex in allAndHub.size():
		var eachWorld : WorldInfo = allAndHub[worldIndex]
		for eachLevel in eachWorld.levels:
			print("\n" + eachWorld.worldName + eachLevel.levelSuffix)
			for eachPrereq in eachLevel.levelPrerequisiteChecks:
				print(eachPrereq.checkName + ", Level Event")
		#	for eachCheck in eachLevel.levelChecks:
		#		if eachCheck.checkType == CheckInfo.CheckType.LOADING_ZONE:
		#			continue
		#		if eachCheck.totalSubchecks == 1:
		#			print(eachCheck.checkName + ", " + CheckInfo.CheckType.keys()[eachCheck.checkType].capitalize())
		#		else:
		#			for eachSubcheck in eachCheck.totalSubchecks:
		#				print(eachCheck.checkName.trim_suffix('s') + " " + str(eachSubcheck + 1) + ", " + CheckInfo.CheckType.keys()[eachCheck.checkType].capitalize())

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

func combine_glapls(glaplA : Array[Dictionary], glaplB : Array[Dictionary]) -> Array[Dictionary]:
	var outGlapl : Array[Dictionary]
	for eachWorld in glaplA.size():
		var worldDictionary : Dictionary
		for eachLevel in glaplA[eachWorld].keys():
			var combinedChecks : Dictionary
			var aChecks : Dictionary = glaplA[eachWorld][eachLevel]
			var bChecks : Dictionary = glaplB[eachWorld][eachLevel]
			for eachA in aChecks.keys():
				if bChecks.keys().has(eachA):
					combinedChecks[eachA] = combine_methods(aChecks[eachA], bChecks[eachA])
				else:
					combinedChecks[eachA] = aChecks[eachA]
			for eachB in bChecks.keys():
				if !aChecks.keys().has(eachB):
					combinedChecks[eachB] = bChecks[eachB]
			worldDictionary[eachLevel] = combinedChecks
		outGlapl.append(worldDictionary)
	return outGlapl

func combine_methods(aMethods : Array[Dictionary], bMethods : Array[Dictionary]) -> Array[Dictionary]:
	var combinedMethods : Array[Dictionary]
	var invalidAMethods : Array[bool]
	var invalidBMethods : Array[bool]
	#Figure out which checks become invalid
	invalidAMethods.resize(aMethods.size())
	invalidBMethods.resize(bMethods.size())
	for eachB in bMethods.size():
		for eachA in aMethods.size():
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
		if !invalidAMethods[eachMethod]:
			combinedMethods.append(aMethods[eachMethod])
	#Add all valid B methods
	for eachMethod in bMethods.size():
		if !invalidBMethods[eachMethod]:
			combinedMethods.append(bMethods[eachMethod])
	
	return combinedMethods

func load_from_paths(loadPaths : PackedStringArray) -> void:
	#Load all the paths into an array
	var gameData : Array[Dictionary] = load_from_path(loadPaths[0])
	for eachPath in range(1, loadPaths.size()):
		gameData = combine_glapls(gameData, load_from_path(loadPaths[eachPath]))
	apply_glapl(gameData)

func web_data_loaded(gameData : Array) -> void:
	var jsonOutput : Array = JSON.parse_string(gameData[0])
	var glaplData : Array[Dictionary]
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

func apply_glapl(gameData : Array[Dictionary]):
	for eachWorld in allWorlds.size():
		allWorlds[eachWorld].to_load(gameData[eachWorld])
	hubworld.to_load(gameData[allWorlds.size()])

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

func to_python_enum(inString : String) -> String:
	#inString = inString.to_upper().replace(' ', '_')
	return inString
