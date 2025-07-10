extends Button
class_name LevelCheckButton

var checkInfo : CheckInfo
var main : Main
@export var totalSubchecks : int = 1

func build_from(newCheckInfo : CheckInfo, newMain : Main) -> void:
	main = newMain
	checkInfo = newCheckInfo
	totalSubchecks = checkInfo.totalSubchecks
	tooltip_text = checkInfo.checkName
	if totalSubchecks > 1:
		tooltip_text += " (" + str(totalSubchecks) + ")"
	icon = checkInfo.checkImage
	anchor_left = checkInfo.checkSpot.x
	anchor_right = checkInfo.checkSpot.x
	anchor_top = checkInfo.checkSpot.y
	anchor_bottom = checkInfo.checkSpot.y

func pressed():
	main.select_check(checkInfo)
