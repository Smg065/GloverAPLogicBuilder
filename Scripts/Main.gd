extends Control
class_name Main

@export_category("Game Data")
@export var hubworld : WorldInfo
@export var allWorlds : Array[WorldInfo]

@export_category("Render Info")
@export var mapRender : TextureRect
@export var worldSelector : OptionButton
@export var levelsButtons : HBoxContainer
@export var overworldButtons : HBoxContainer
@export var checkPrereqToggles : HBoxContainer
@export var checkName : Label

@export_category("Spawnables")
@export var checkButtonPrefab : PackedScene
@export var checkPrerequisiteButtonPrefab : PackedScene
@export var allCheckButtons : Array[LevelCheckButton]
@export var allCheckPrerequisiteButtons : Array[PrerequisiteCheckButton]

@export_category("Method Selector")
@export var methodSelector : MethodSelector

@export_category("File Info")
@export var saveFile : FileDialog
@export var openFiles : FileDialog

var isMainWorld : bool
var debugLevelData : LevelData

func _ready() -> void:
	change_level(0)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Coord"):
		copy_mouse_info()
	if Input.is_action_just_pressed("Level Info"):
		print_level_data(debugLevelData)
	if Input.is_action_just_pressed("World Info"):
		for eachLevel in hubworld.levels:
			print_level_data(eachLevel)
	if Input.is_action_just_pressed("Garib Info"):
		print_garib_data(debugLevelData)
	if Input.is_action_just_pressed("Total Info"):
		print_total_data()

func copy_mouse_info() -> void:
	var newCoord : String = str(mouse_pos_to_map_spot())
	newCoord = newCoord.trim_prefix("(").trim_suffix(")")
	var eachPos = newCoord.split(',')
	newCoord = eachPos[0] + eachPos[1]
	DisplayServer.clipboard_set(str(newCoord))
	#var newCheck : CheckInfo = CheckInfo.new()
	#newCheck.checkSpot = Vector2(float(eachPos[0]), float(eachPos[1]))
	#debugLevelData.levelChecks.append(newCheck)
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
			CheckInfo.CheckType.REGION:
				totalRegions += eachCheck.totalSubchecks
			CheckInfo.CheckType.MISC:
				totalMisc += eachCheck.totalSubchecks
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
	print_if_not_0(totalMisc, "Misc")
	if totalGoals > 0:
		if totalGoals > 1:
			print(str(totalGoals) + " Goals")
		else:
			print("Has Goal")
	else:
		print("No Goal")
	print("")

func print_garib_data(levelData : LevelData):
	for eachCheck in levelData.levelChecks:
		if eachCheck.checkType != CheckInfo.CheckType.GARIB:
			continue
		

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
					CheckInfo.CheckType.REGION:
						totalRegions += eachCheck.totalSubchecks
					CheckInfo.CheckType.MISC:
						totalMisc += eachCheck.totalSubchecks
		
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
	print_if_not_0(totalRegions, "Regions")
	print_if_not_0(totalGoals, "Goals")
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
		var nextButton = checkPrerequisiteButtonPrefab.instantiate()
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
		var nextButton = checkButtonPrefab.instantiate()
		allCheckButtons.append(nextButton)
		mapRender.add_child(nextButton)
		nextButton.build_from(eachCheck, self)

func set_level(levelData : LevelData):
	debugLevelData = levelData
	clear_check_buttons()
	clear_prereq_check_buttons()
	mapRender.texture = levelData.mapImage
	build_check_buttons(levelData)
	build_prereq_check_buttons(levelData)
	methodSelector.clear()

func select_check(newCheck : CheckInfo):
	if newCheck != null:
		checkName.text = newCheck.checkName
	else:
		checkName.text = "Select Check"
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
	saveFile.show()

func save_from_path(savePath : String) -> void:
	var gameData : Array[Dictionary]
	for eachWorld in allWorlds:
		gameData.append(eachWorld.to_save())
	gameData.append(hubworld.to_save())
	var path = FileAccess.open(savePath,FileAccess.WRITE)
	path.store_var(gameData, false)
	path.close()

func load_press() -> void:
	openFiles.show()

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

func load_from_path(loadPath : String) -> Array[Dictionary]:
	var path = FileAccess.open(loadPath, FileAccess.READ)
	var gameData : Array[Dictionary] = path.get_var(false)
	path.close()
	return gameData

func apply_glapl(gameData : Array[Dictionary]):
	for eachWorld in allWorlds.size():
		allWorlds[eachWorld].to_load(gameData[eachWorld])
	hubworld.to_load(gameData[allWorlds.size()])
