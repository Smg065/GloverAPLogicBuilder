extends Resource
class_name RegionInfo

@export var regionName : String
@export var regionImage : Texture2D

var defaultCheck : CheckInfo
var ballCheck : CheckInfo

func generate_checks() -> void:
	defaultCheck = build_check_info(regionName, regionImage)
	ballCheck = build_check_info(regionName, regionImage, true)

static func build_check_info(newName : String, newImage : Texture2D, isBallCheck : bool = false) -> CheckInfo:
	var newCheck : CheckInfo = CheckInfo.new()
	newCheck.checkName = newName
	if isBallCheck:
		newCheck.checkName += " W/Ball"
	newCheck.checkImage = newImage
	newCheck.checkType = CheckInfo.CheckType.REGION
	return newCheck

func to_save() -> Dictionary:
	var regionData : Dictionary
	regionData["D"] = defaultCheck.to_save()
	regionData["B"] = ballCheck.to_save()
	return regionData

func to_load(regionData : Dictionary) -> void:
	defaultCheck.to_load(regionData["D"])
	ballCheck.to_load(regionData["B"])
