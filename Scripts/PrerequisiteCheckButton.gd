extends Button
class_name PrerequisiteCheckButton

var prereqName : String
var main : Main

func build_from(prereqInfo : PrerequisiteCheckInfo, newMain : Main):
	main = newMain
	prereqName = prereqInfo.checkName
	tooltip_text = prereqName
	icon = prereqInfo.checkImage
	set_press_state(main.check_prereq(prereqName))

func pressed():
	main.toggle_check_prerequisite(self)
	set_press_state()

func set_press_state(newState : bool = button_pressed) -> void:
	button_pressed = newState
	if button_pressed:
		modulate = Color(1,1,1,1)
	else:
		modulate = Color(1,1,1,.5)
