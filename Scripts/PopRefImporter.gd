@tool
extends EditorScript

@export var allWorlds : Array[WorldInfo] = [
	load("res://Resources/Atlantis.tres"),
	load("res://Resources/Carnival.tres"),
	load("res://Resources/Pirates.tres"),
	load("res://Resources/Prehistoric.tres"),
	load("res://Resources/Fortress.tres"),
	load("res://Resources/Space.tres")
]
@export var importFile : JSON = load("res://Resources/popreferences.json")

# Called when the node enters the scene tree for the first time.
func _run() -> void:
	var refData = importFile.data
	var worldRefArray = refData[0].children
	for eachWorld in allWorlds:
		for eachWorldEntry in worldRefArray:
			if eachWorld.worldName != eachWorldEntry.name:
				continue
			for eachLevel in eachWorld.levels:
				var levelName := eachWorld.worldName + " " + eachLevel.levelSuffix
				for eachLevelEntry in eachWorldEntry.children:
					if levelName != eachLevelEntry.name:
						continue
					for eachCheck in eachLevel.levelChecks:
						var pairingFound : bool = false
						for eachGrouping in eachLevelEntry.children:
							if not "name" in eachGrouping:
								continue
							if eachCheck.checkName != eachGrouping.name and eachCheck.poptrackerGroupName != eachGrouping.name:
								continue
							pairingFound = true
							eachCheck.poptrackerSpot.x = eachGrouping.map_locations[0].x
							eachCheck.poptrackerSpot.y = eachGrouping.map_locations[0].y
							break
						if !pairingFound and eachCheck.poptrackerSpot == -Vector2i.ONE and !eachCheck.lockButton:
							for otherChecks in eachLevel.levelChecks:
								if otherChecks.poptrackerGroupName != eachCheck.poptrackerGroupName or otherChecks.poptrackerSpot == -Vector2i.ONE:
									continue
								pairingFound = true
								eachCheck.poptrackerSpot = otherChecks.poptrackerSpot
							if !pairingFound:
								print(levelName + " " + eachCheck.checkName + " / " + eachCheck.poptrackerGroupName)
					break
			break
