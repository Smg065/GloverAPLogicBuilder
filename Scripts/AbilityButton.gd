extends Button
class_name AbilityButton

@export var moveIndex : int
@export var movePath : MethodSelector

func _ready() -> void:
	modulate = Color(1,1,1,0.5)
	tooltip_text = name

func _toggled(toggled_on: bool) -> void:
	button_pressed = toggled_on
	if toggled_on:
		modulate = Color(1,1,1,1)
	else:
		modulate = Color(1,1,1,0.5)

func pressed() -> void:
	if movePath.item_count <= 0:
		_toggled(false)
	movePath.update_method_move(moveIndex, button_pressed)
