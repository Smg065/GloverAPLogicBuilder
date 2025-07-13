extends OptionButton
class_name MethodSelector

@export var checkInfo : CheckInfo
var allAbilityButtons : Array[AbilityButton]
@export var addMethodButton : Button
@export var removeMethodButton : Button
@export var trickDifficultyButton : OptionButton
@export var regionSelector : OptionButton
@export var regionBallToggle : CheckBox
@export var main : Main

func _ready() -> void:
	var allAbilityButtonsFound = get_tree().get_nodes_in_group("AbilityButton")
	for eachButton in allAbilityButtonsFound:
		allAbilityButtons.append(eachButton)
	construct_dropdowns_from_check()

func change_check(newCheck : CheckInfo):
	checkInfo = newCheck
	construct_dropdowns_from_check()
	if checkInfo != null:
		regionBallToggle.button_pressed = checkInfo.checkBallRequirement
		regionSelector.select(checkInfo.checkRegionIndex)
	method_selected(get_selected_id())

func construct_dropdowns_from_check():
	if !check_info_exists():
		return
	clear()
	for eachMethod in checkInfo.allMethods.size():
		add_item("Method " + str(eachMethod + 1))

func update_method_move(moveIndex : int, isAdd : bool):
	if !check_info_exists():
		return
	var selId : int = get_selected_id()
	if selId == -1:
		return
	checkInfo.allMethods[selId].setMove(moveIndex, isAdd)

func update_method_prereq(checkButton : PrerequisiteCheckButton, isAdd : bool):
	print(isAdd)
	if !check_info_exists():
		checkButton.button_pressed = false
		return
	var selId : int = get_selected_id()
	if selId == -1:
		checkButton.button_pressed = false
		return
	checkInfo.allMethods[selId].setPrereq(checkButton.prereqName, isAdd)

func region_selected(index : int):
	#Make sure there's a check and method
	if !check_info_exists():
		return
	var selId : int = get_selected_id()
	if selId == -1:
		return
	#Get the method
	var selectedMethod : MethodData = checkInfo.allMethods[selId]
	#Set region index
	selectedMethod.regionIndex = index

func ball_toggled(toggle_on : bool):
	#Make sure there's a check and method
	if !check_info_exists():
		return
	var selId : int = get_selected_id()
	if selId == -1:
		return
	#Get the method
	var selectedMethod : MethodData = checkInfo.allMethods[selId]
	#Set ball toggled state
	selectedMethod.ballRequirement = toggle_on

func add_method():
	#Make sure there's a check to add the method to
	if !check_info_exists():
		return
	#Add a new method to the chain
	var newMethod : MethodData = MethodData.new()
	checkInfo.allMethods.append(newMethod)
	#Setup the region and ball in region data
	var regionIndex : int = checkInfo.checkRegionIndex
	var ballRequirement : bool = checkInfo.checkBallRequirement
	newMethod.regionIndex = regionIndex
	regionSelector.select(regionIndex)
	newMethod.ballRequirement = ballRequirement
	regionBallToggle.button_pressed = ballRequirement
	#Construct data
	construct_dropdowns_from_check()
	_select_int(checkInfo.allMethods.size() - 1)
	method_selected(get_selected_id())
	can_remove_methods()

func remove_method():
	if !check_info_exists():
		return
	var selId : int = get_selected_id()
	if selId == -1:
		return
	checkInfo.allMethods.remove_at(selId)
	construct_dropdowns_from_check()
	selId = min(selId, item_count - 1)
	_select_int(selId)
	method_selected(selId)
	can_remove_methods()

func can_remove_methods():
	removeMethodButton.disabled = checkInfo.allMethods.size() == 0

func method_selected(index: int) -> void:
	if checkInfo == null:
		index = -1
	for eachMove in allAbilityButtons:
		if index == -1:
			eachMove._toggled(false)
		else:
			eachMove._toggled(checkInfo.allMethods[index].hasMove(eachMove.moveIndex))
	if index == -1:
		main.check_prereqs_from_method(null)
		regionSelector.disabled = true
		regionBallToggle.disabled = true
		trickDifficultyButton.disabled = true
		return
	regionSelector.disabled = false
	regionBallToggle.disabled = false
	trickDifficultyButton.disabled = false
	match checkInfo.allMethods[index].trickDifficulty:
		MethodData.TrickDifficulty.INTENDED:
			trickDifficultyButton.selected = 0
		MethodData.TrickDifficulty.EASY:
			trickDifficultyButton.selected = 1
		MethodData.TrickDifficulty.HARD:
			trickDifficultyButton.selected = 2
	main.check_prereqs_from_method(checkInfo.allMethods[index])
	regionSelector.select(checkInfo.allMethods[index].regionIndex)
	regionBallToggle.button_pressed = checkInfo.allMethods[index].ballRequirement

func trick_difficulty_selected(index: int) -> void:
	var selId : int = get_selected_id()
	if selId == -1:
		return
	checkInfo.allMethods[selId].setDifficulty(index)

func check_info_exists() -> bool:
	var checkInfoExists : bool = checkInfo != null
	addMethodButton.visible = checkInfoExists
	removeMethodButton.visible = checkInfoExists
	return checkInfoExists

func check_prereq(prereqName : String) -> bool:
	if !check_info_exists():
		return false
	var selId : int = get_selected_id()
	if selId == -1:
		return false
	return checkInfo.allMethods[selId].requiredChecks.has(prereqName)
