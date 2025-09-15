extends Resource
class_name LandscapeXML

const LINE_ERROR = MemoryHexLine.LINE_TYPE.ERROR
const LINE_POWERUP = MemoryHexLine.LINE_TYPE.POWERUP
const LINE_MR_TIP = MemoryHexLine.LINE_TYPE.MR_TIP
const LINE_GARIB = MemoryHexLine.LINE_TYPE.GARIB
const LINE_CHECKPOINT = MemoryHexLine.LINE_TYPE.CHECKPOINT
const LINE_PUZZLECOND = MemoryHexLine.LINE_TYPE.PUZZLECOND
const LINE_PLATFORM = MemoryHexLine.LINE_TYPE.PLATFORM
const LINE_ENEMY = MemoryHexLine.LINE_TYPE.ENEMY

class MemoryHexLine:
	enum LINE_TYPE {ERROR, POWERUP, MR_TIP, GARIB, CHECKPOINT, PUZZLECOND, PLATFORM, ENEMY}
	var address : String = "??????"
	var type : LINE_TYPE = LINE_TYPE.ERROR
	var id : String = "0xXXXX"
	static func from_string(incomingLine : String) -> MemoryHexLine:
		var output : MemoryHexLine = MemoryHexLine.new()
		output.address = incomingLine.substr(2, 6)
		match incomingLine.substr(8, 4):
			"0100":
				output.type = LINE_TYPE.POWERUP
			"00C0":
				output.type = LINE_TYPE.MR_TIP
			"00B0":
				output.type = LINE_TYPE.GARIB
			"1221":
				output.type = LINE_TYPE.CHECKPOINT
			"0010":
				output.type = LINE_TYPE.PUZZLECOND
			"0180":
				output.type = LINE_TYPE.PLATFORM
			_:
				output.type = LINE_TYPE.ENEMY
		output.id = "0x" + incomingLine.substr(12, 4).lstrip("0")
		return output

static func landscape_memdump_combiner(xmlPath : String, memdumpPath : String) -> String:
	var parser : XMLParser = XMLParser.new()
	parser.open(xmlPath)
	var memdumpFile = FileAccess.open(memdumpPath, FileAccess.READ)
	var hexLines : Array[MemoryHexLine] = memdump_parser(memdumpFile.get_as_text())
	var loadedOrder : Array[String] = []
	#Grab the start construction IDs
	loadedOrder.append("Start Instruction 1: " + next_hex(hexLines, loadedOrder, LINE_PUZZLECOND).address)
	loadedOrder.append("Start Instruction 2: " + next_hex(hexLines, loadedOrder, LINE_PUZZLECOND).address)
	var lastCheckpointCoord : String = "ERROR; NO PREFIXED PORTAL GRAPHIC"
	#The XML data goes here
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var nodeName : String = parser.get_node_name()
			match nodeName:
				"Garib":
					var coord : Vector3 = xml_coord(parser)
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_GARIB)
					match parser.get_named_attribute_value("type"):
						"garib":
							loadedOrder.append("Garib " + nextLine.id + " at " + str(coord))
						"extra_life":
							loadedOrder.append("Life " + nextLine.id + " at " + str(coord))
				"Enemy":
					var enemyName : String = parser.get_named_attribute_value("type")
					var nextLine : MemoryHexLine
					if enemyName == "swish":
						nextLine = next_hex(hexLines, loadedOrder, LINE_PUZZLECOND)
					else:
						nextLine = next_hex(hexLines, loadedOrder, LINE_ENEMY)
					var coord : Vector3 = xml_coord(parser)
					var outputString = "Enemy " + nextLine.id + " named " + enemyName + " at " + str(coord) + " address "
					outputString += nextLine.address + " (%X" % (nextLine.address.hex_to_int() + 56) + " Dropoff)"
					loadedOrder.append(outputString)
				"MrTip":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_MR_TIP)
					var coord : Vector3 = xml_coord(parser)
					loadedOrder.append("Mr Tip " + nextLine.id + " at " + str(coord))
				"Platform":
					var modelName : String = parser.get_named_attribute_value("name")
					var nextLine : MemoryHexLine
					match modelName:
						"hoop.nd":
							#Checkpoints
							next_valid_node(parser, "PlatSetInitialPos")
							lastCheckpointCoord = " at " + str(xml_coord(parser))
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							loadedOrder.append("Portal Graphic " + nextLine.id)
						"glovebu":
							#Glover Switches
							next_valid_node_array(parser, ["PlatPathPoint", "PlatSetInitialPos"])
							var coord : Vector3  = xml_coord(parser)
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							loadedOrder.append("Switch (Glover) " + nextLine.id + " at " + str(coord))
						"ballbut":
							#Ball Buttons
							next_valid_node_array(parser, ["PlatPathPoint", "PlatSetInitialPos"])
							var coord : Vector3  = xml_coord(parser)
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							loadedOrder.append("Switch (Ball) " + nextLine.id + " at " + str(coord))
						"target.":
							#Ball Buttons
							next_valid_node_array(parser, ["PlatPathPoint", "PlatSetInitialPos"])
							var coord : Vector3  = xml_coord(parser)
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							loadedOrder.append("Target " + nextLine.id + " at " + str(coord))
						"plasma.":
							#The Monolith Buttons
							next_valid_node(parser, "PlatSetInitialPos")
							var coord : Vector3  = xml_coord(parser)
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							next_valid_node(parser, "PlatSetTag")
							var monolithTag : String  = parser.get_named_attribute_value("tag")
							loadedOrder.append("Monolith " + nextLine.id + " at " + str(coord) + " has tag " + monolithTag)
						"swtchgl":
							#Red switches in OoTW3
							next_valid_node_array(parser, ["PlatPathPoint", "PlatSetInitialPos"])
							var coord : Vector3  = xml_coord(parser)
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							loadedOrder.append("Red Glover Switch " + nextLine.id + " at " + str(coord))
						_:
							nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							loadedOrder.append("Platform " + nextLine.id + " is " + modelName)
				"PlatCheckpoint":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_CHECKPOINT)
					loadedOrder.append("Checkpoint " + nextLine.id + lastCheckpointCoord)
				#The flag to see when a ball stops touching
				"PuzzleCondBallChangedTouchingPlatform":
					loadedOrder[loadedOrder.size() - 1] += " seeking ball interaction with " + parser.get_named_attribute_value("plat_tag")
				"NullPlatform":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
					loadedOrder.append("Null Platform " + nextLine.id)
				"Powerup":
					var nextLine : MemoryHexLine
					var coord : Vector3  = xml_coord(parser)
					var powerupName : String = parser.get_named_attribute_value("type")
					match powerupName:
						"2":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Frog"
						"3":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Sticky Fingers"
						"4":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Hercules"
						"5":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Speed"
						"6":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Helicopter"
						"7":
							#Skip the unknown behavior
							continue
							#nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							#powerupName = "Unknown 7"
						"9":
							#Skip the unknown behavior
							continue
							#nextLine = next_hex(hexLines, loadedOrder, LINE_PLATFORM)
							#powerupName = "Unknown 9"
						"10":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Beachball"
						"13":
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "Boomerang"
						_:
							nextLine = next_hex(hexLines, loadedOrder, LINE_POWERUP)
							powerupName = "New Powerup! Number " + str(powerupName)
					loadedOrder.append("Powerup " + nextLine.id + " is " + powerupName + " at " + str(coord))
				"PuzzleCond":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_PUZZLECOND)
					loadedOrder.append("Puzzle Condition " + nextLine.id + " is " + parser.get_named_attribute_value("cond_type") + " at address " + nextLine.address)
				"PlatDestructible":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_PUZZLECOND)
					loadedOrder.append("Destructable Flag " + nextLine.id + " has address " + nextLine.address)
				"PlatPush0x5b":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_PUZZLECOND)
					loadedOrder.append("Pushable Flag " + nextLine.id + " has address " + nextLine.address)
				"PlatSpike":
					var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_PUZZLECOND)
					loadedOrder.append("Spikes Flag " + nextLine.id)
				#"PlatMagnet0x8b":
				#	var nextLine : MemoryHexLine = next_hex(hexLines, loadedOrder, LINE_PUZZLECOND)
				#	loadedOrder.append("Magnet Flag " + nextLine.id)
	#Lost hexlines
	for eachRemaining in hexLines:
		loadedOrder.append(MemoryHexLine.LINE_TYPE.keys()[eachRemaining.type] + " " + eachRemaining.id + " Leftover")
	#Output it
	var outputMerge : String = ""
	for eachEntry in loadedOrder:
		outputMerge += eachEntry + "\n"
	memdumpFile.close()
	outputMerge = outputMerge.trim_suffix("\n")
	return outputMerge

static func next_hex(hexLines : Array[MemoryHexLine], outputLine : Array[String], expectedType : MemoryHexLine.LINE_TYPE = LINE_ERROR, fromFront : bool = true):
	#Pop the next line
	var toOutput : MemoryHexLine
	if fromFront:
		toOutput = hexLines.pop_front()
	else:
		toOutput = hexLines.pop_back()
	#If nothing is given as a required type, output this
	if expectedType == LINE_ERROR:
		return toOutput
	#If it's empty, spit out a broken one
	if toOutput == null:
		return MemoryHexLine.new()
	#If it's working correctly, the next line should match
	var currentType : MemoryHexLine.LINE_TYPE = toOutput.type
	if expectedType == currentType:
		return toOutput
	#Desync handler
	while expectedType != currentType and hexLines.size() > 0:
		outputLine.append("!!!UNCAUGHT " + MemoryHexLine.LINE_TYPE.keys()[currentType].capitalize() + " " + toOutput.id + "!!!")
		if fromFront:
			toOutput = hexLines.pop_front()
		else:
			toOutput = hexLines.pop_back()
		currentType = toOutput.type
	return toOutput

static func memdump_parser(inText : String) -> Array[MemoryHexLine]:
	var output : Array[MemoryHexLine] = []
	#Go over the text of the memory dump
	for textPos in range(0, inText.length(), 32):
		var curLine : String = inText.substr(textPos, 32)
		output.append(MemoryHexLine.from_string(curLine))
	return output

static func next_valid_node(parser : XMLParser, keyword : String):
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == keyword:
				return parser

static func next_valid_node_array(parser : XMLParser, keywords : Array[String]):
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if keywords.has(parser.get_node_name()):
				return parser


static func xml_coord(parser : XMLParser) -> Vector3:
	return Vector3(float(parser.get_named_attribute_value("x")), float(parser.get_named_attribute_value("y")), float(parser.get_named_attribute_value("z")))
