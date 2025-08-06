extends TextureButton
class_name RegionButton

@export var regionInfo : RegionInfo
var color : Color = Color.WHITE
var main : Main

const FOCUSED_COLOR : Color = Color(1,1,1,.5)
const UNFOCUSED_COLOR : Color = Color(.75,.75,.75,.3)

func build_from(newInfo : RegionInfo, newMain : Main, hue : float):
	regionInfo = newInfo
	main = newMain
	main.regionBallToggle.toggled.connect(ball_toggled)
	#Basic setup
	ball_toggled(main.regionBallToggle.button_pressed)
	color = Color.from_hsv(hue,1,1,1)
	#Setup texture shape
	texture_normal = regionInfo.regionImage
	texture_pressed = regionInfo.regionImage
	texture_hover = regionInfo.regionImage
	texture_disabled = regionInfo.regionImage
	texture_focused = regionInfo.regionImage
	texture_click_mask = BitMap.new()
	texture_click_mask.create_from_image_alpha(regionInfo.regionImage.get_image())
	modulate_fade(UNFOCUSED_COLOR)

func pressed():
	if main.regionBallToggle.button_pressed:
		main.select_check(regionInfo.ballCheck, regionInfo)
	else:
		main.select_check(regionInfo.defaultCheck, regionInfo)

func mouse_entered() -> void:
	modulate_fade(FOCUSED_COLOR)

func mouse_exited() -> void:
	modulate_fade(UNFOCUSED_COLOR)

func modulate_fade(fadeTo : Color) -> void:
	modulate = fadeTo.lerp(color, 0.5)

func ball_toggled(ballOn : bool):
	var suffix : String = " (" + str(regionInfo.regionIndex) + ")"
	if ballOn:
		tooltip_text = regionInfo.regionName + " W/Ball" + suffix
	else:
		tooltip_text = regionInfo.regionName + suffix
