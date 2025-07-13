extends Resource
class_name CheckInfo

enum CheckType { SWITCH, GARIB, LIFE, CHECKPOINT, POTION, GOAL, TIP, LOADING_ZONE, REGION, MISC}

@export_category("Information")
@export var checkName : String
@export var checkSpot : Vector2
@export var checkImage : Texture2D
@export var checkType : CheckType
@export var totalSubchecks : int = 1

@export_category("Defaults")
@export var checkRegionIndex : int
@export var checkBallRequirement : bool

var allMethods : Array[MethodData]

func to_save() -> Array[Dictionary]:
	var checkData : Array[Dictionary]
	for eachMethod in allMethods.size():
		checkData.append(allMethods[eachMethod].to_save())
	return checkData

func to_load(checkData : Array[Dictionary]) -> void:
	allMethods.clear()
	for eachMethod in checkData.size():
		var newMethod : MethodData = MethodData.new()
		newMethod.to_load(checkData[eachMethod])
		allMethods.append(newMethod)
