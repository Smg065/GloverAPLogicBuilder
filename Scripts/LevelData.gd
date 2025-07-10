extends Resource
class_name LevelData

@export var mapImage : Texture2D
@export var levelChecks : Array[CheckInfo]
@export var levelPrerequisiteChecks : Array[PrerequisiteCheckInfo]

func to_save() -> Dictionary:
	var levelData : Dictionary
	for eachCheck in levelChecks.size():
		levelData[levelChecks[eachCheck].checkName] = levelChecks[eachCheck].to_save()
	return levelData

func to_load(levelData : Dictionary) -> void:
	var checkNames = levelData.keys()
	for eachCheck in levelChecks.size():
		var checkName : String = levelChecks[eachCheck].checkName
		if checkNames.has(checkName):
			levelChecks[eachCheck].to_load(levelData[checkName])
