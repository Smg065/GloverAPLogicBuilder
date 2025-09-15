@tool
extends EditorScript
class_name RecompileApIds

@export var allAndHub : Array[WorldInfo]
var apId : int = 0

func _run():
	apId = 0
	allAndHub = [
		load("res://Resources/Atlantis.tres"),
		load("res://Resources/Carnival.tres"),
		load("res://Resources/Pirates.tres"),
		load("res://Resources/Prehistoric.tres"),
		load("res://Resources/Fortress.tres"),
		load("res://Resources/Space.tres"),
		load("res://Resources/Hubworld.tres")
	]
	for eachWorld in allAndHub:
		for eachLevel in eachWorld.levels:
			#Catagory Lookup
			var catagoryLookup : Dictionary = {
				CheckInfo.CheckType.GARIB : [],
				CheckInfo.CheckType.ENEMY : [],
				CheckInfo.CheckType.LIFE : [],
				CheckInfo.CheckType.TIP : [],
				CheckInfo.CheckType.CHECKPOINT : [],
				CheckInfo.CheckType.SWITCH : [],
				CheckInfo.CheckType.GOAL : [],
				CheckInfo.CheckType.POTION : [],
				CheckInfo.CheckType.MISC : [],
				CheckInfo.CheckType.LOADING_ZONE : []
			}
			
			#Put level check info in there
			for eachCheck in eachLevel.levelChecks:
				var toLookup : CheckInfo.CheckType = eachCheck.checkType
				if toLookup == CheckInfo.CheckType.BUG:
					toLookup = CheckInfo.CheckType.ENEMY
				catagoryLookup[toLookup].append(eachCheck)
			
			#Sort catagories
			for eachCatagory in catagoryLookup.keys():
				catagoryLookup[eachCatagory].sort_custom(sort_catagory)
			
			#For each catagory
			for eachCatagory in catagoryLookup.keys():
				#Loading Zones don't have APID's
				if eachCatagory == CheckInfo.CheckType.LOADING_ZONE:
					continue
				#Most use the default catagory sorting method
				if eachCatagory != CheckInfo.CheckType.ENEMY:
					update_catagory(catagoryLookup[eachCatagory])
				#Special case enemy handler
				else:
					update_enemy_catagory(catagoryLookup[eachCatagory])
			
			#Reorginize checks in the level holder
			var reorderedChecks : Array[CheckInfo] = []
			for eachCatagory in catagoryLookup.keys():
				reorderedChecks.append_array(catagoryLookup[eachCatagory])
			eachLevel.levelChecks = reorderedChecks
			ResourceSaver.save(eachLevel)

func sort_catagory(a : CheckInfo, b : CheckInfo) -> bool:
	return a.checkName.naturalcasecmp_to(b.checkName) < 0

func update_catagory(catagoryChecks : Array):
	#For each check in that catagory
	for eachCheck in catagoryChecks:
		eachCheck.apIds.clear()
		update_check_info(eachCheck, apId)
		apId += eachCheck.totalSubchecks

func update_enemy_catagory(catagoryChecks : Array):
	#Start with just the enemy garibs pass
	for eachCheck in catagoryChecks:
		eachCheck.apIds.clear()
		if eachCheck.enemyGaribs:
			update_check_info(eachCheck, apId)
			apId += eachCheck.totalSubchecks
	
	#For each check in that catagory
	for eachCheck in catagoryChecks:
		update_check_info(eachCheck, apId)
		apId += eachCheck.totalSubchecks

func update_check_info(checkInfo : CheckInfo, apIdOffset : int):
	#Get the new AP ID's to add
	var newApIds : PackedStringArray = PackedStringArray()
	for subchecks in checkInfo.totalSubchecks:
		newApIds.append(id_to_hex(apIdOffset + subchecks))
	#Put the old AP ID's at the back of the array [for Enemies]
	newApIds.append_array(checkInfo.apIds)
	#Assign it
	checkInfo.apIds = newApIds
	ResourceSaver.save(checkInfo)

func id_to_hex(checkNumber : int):
	return "0x" + ("%03X" % [checkNumber])
