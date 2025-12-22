extends Resource
class_name CheckInfo

enum CheckType { SWITCH, GARIB, LIFE, CHECKPOINT, POTION, GOAL, TIP, LOADING_ZONE, REGION, MISC, ENEMY, BUG}

@export_category("Information")
@export var checkName : String
@export var checkSpot : Vector2
@export var checkImage : Texture2D
@export var checkType : CheckType
@export var totalSubchecks : int = 1
@export var enemyGaribs : bool

@export_category("Export Info")
@export var ids : Array[String]
@export var apIds : PackedStringArray

@export_category("Defaults")
@export var checkRegionIndex : int
@export var checkBallRequirement : bool
@export var lockButton : bool

@export_category("Poptracker")
@export var poptrackerSpot : Vector2i

var allMethods : Array[MethodData]

func to_save() -> Array[Dictionary]:
	var checkData : Array[Dictionary]
	var infoDict : Dictionary = {
		"IDS":ids,
		"AP_IDS":apIds,
		"TYPE":checkType,
		"REGION":checkRegionIndex,
		"NEEDS_BALL":checkBallRequirement}
	if checkType == CheckType.ENEMY:
		infoDict["COUNT"] = totalSubchecks
	checkData.append(infoDict)
	for eachMethod in allMethods.size():
		checkData.append(allMethods[eachMethod].to_save())
	return checkData

func to_load(checkData : Array) -> void:
	allMethods.clear()
	for eachMethod in checkData.size() - 1:
		var newMethod : MethodData = MethodData.new()
		newMethod.to_load(checkData[eachMethod + 1])
		allMethods.append(newMethod)

func get_pop_spot(mapScale : Vector2i) -> Vector2i:
	if poptrackerSpot != Vector2i.ZERO:
		return poptrackerSpot
	var output : Vector2i = Vector2i.ZERO
	output.x = int(checkSpot.x * mapScale.x)
	output.y = int(checkSpot.y * mapScale.y)
	return output
