extends Resource
class_name WorldInfo

@export var worldName : String
@export var levels : Array[LevelData]

func to_save() -> Dictionary:
	var worldData : Dictionary
	for eachLevel in levels.size():
		worldData["l" + str(eachLevel)] = levels[eachLevel].to_save()
	return worldData

func to_load(worldData : Dictionary) -> void:
	for eachLevel in levels.size():
		levels[eachLevel].to_load(worldData["l" + str(eachLevel)])
