extends Resource
class_name LevelData

@export var levelSuffix : String
@export var mapImage : Texture2D
@export var levelChecks : Array[CheckInfo]
@export var levelPrerequisiteChecks : Array[PrerequisiteCheckInfo]
@export var levelRegions : Array[RegionInfo]
@export var checkpointRegions : Array[int]
@export var ballOrigin : int

func setup() -> void:
	for eachRegion in levelRegions:
		eachRegion.generate_checks()

func to_save() -> Dictionary:
	var levelData : Dictionary
	for eachCheck in levelChecks.size():
		levelData[levelChecks[eachCheck].checkName] = levelChecks[eachCheck].to_save()
	for eachRegion in levelRegions.size():
		levelData[levelRegions[eachRegion].regionName] = levelRegions[eachRegion].to_save()
	return levelData

func to_load(levelData : Dictionary) -> void:
	var dataNames = levelData.keys()
	for eachCheck in levelChecks.size():
		var checkName : String = levelChecks[eachCheck].checkName
		if dataNames.has(checkName):
			levelChecks[eachCheck].to_load(levelData[checkName])
	for eachRegion in levelRegions.size():
		var regionName : String = levelRegions[eachRegion].regionName
		if dataNames.has(regionName):
			levelRegions[eachRegion].to_load(levelData[regionName])
