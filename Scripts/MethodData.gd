extends Resource
class_name MethodData

enum TrickDifficulty {INTENDED, EASY, HARD}

enum CompareInfo {KEEP_A, KEEP_B, KEEP_BOTH}

var trickDifficulty : TrickDifficulty
var requiredMoves : Array[int]
var requiredChecks : Array[String]
var regionIndex : int
var ballRequirement : bool

func hasMove(moveIndex : int):
	return requiredMoves.has(moveIndex)

func setMove(moveIndex : int, isAdd : bool):
	if isAdd:
		requiredMoves.append(moveIndex)
	else:
		requiredMoves.erase(moveIndex)

func setPrereq(checkName : String, isAdd : bool):
	if isAdd:
		requiredChecks.append(checkName)
	else:
		requiredChecks.erase(checkName)

func setDifficulty(newDifficulty : int):
	match newDifficulty:
		0:
			trickDifficulty = TrickDifficulty.INTENDED
		1:
			trickDifficulty = TrickDifficulty.EASY
		2:
			trickDifficulty = TrickDifficulty.HARD

func to_save() -> Dictionary:
	var methodData : Dictionary = {
		"trickDifficulty" : trickDifficulty,
		"regionIndex" : regionIndex,
		"ballRequirement" : ballRequirement
	}
	for eachMove in requiredMoves.size():
		methodData["mv" + str(eachMove)] = requiredMoves[eachMove]
	for eachCheck in requiredChecks.size():
		methodData["ck" + str(eachCheck)] = requiredChecks[eachCheck]
	return methodData

func to_load(methodData : Dictionary) -> void:
	trickDifficulty = methodData["trickDifficulty"]
	regionIndex = methodData["regionIndex"]
	ballRequirement = methodData["ballRequirement"]
	requiredMoves.clear()
	requiredChecks.clear()
	requiredMoves.append_array(required_to_array(methodData, "mv"))
	requiredChecks.append_array(required_to_array(methodData, "ck"))

static func required_to_array(methodData : Dictionary, prefix : String) -> Array:
	var outArray : Array
	for eachKey in methodData.keys():
		if eachKey.begins_with(prefix):
			outArray.append(int(methodData[eachKey]))
	return outArray

static func compare_from_dictionary(methodA : Dictionary, methodB : Dictionary) -> CompareInfo:
	#If the two are the exact same, A wins
	if methodA.recursive_equal(methodB, 1):
		return CompareInfo.KEEP_A
	
	#Which method's trick priority is higher?
	#Easier strats should be kept in logic over harder ones
	var methodTrickPriority : int
	methodTrickPriority = offset_compare(methodA["trickDifficulty"], methodB["trickDifficulty"])
	
	#Simpler strats should be kept in logic over more complicated ones
	var aMoves : Array[int] = required_to_array(methodA, "mv")
	var bMoves : Array[int] = required_to_array(methodB, "mv")
	var aChecks : Array[String] = required_to_array(methodA, "ck")
	var bChecks : Array[String] = required_to_array(methodB, "ck")
	aMoves.sort()
	bMoves.sort()
	aChecks.sort()
	bChecks.sort()
	#Figure out which moves/checks list is longer or shorter
	var countPriority : int = offset_compare(aMoves.size() + aChecks.size(), bMoves.size() + bChecks.size())
	
	#If the moves are the same size
	if countPriority == 0:
		#And they're not 100% equal
		if aMoves != bMoves || aChecks != bChecks:
			return CompareInfo.KEEP_BOTH
		#If they are equal, return the one with the trick priority
		elif methodTrickPriority <= 0:
			return CompareInfo.KEEP_A
		else:
			return CompareInfo.KEEP_B
	
	#Whichever move list is shorter decides if it can be compressed
	var compressable : bool
	if countPriority < 0:
		#A is smaller than B
		compressable = can_compress(aMoves, aChecks, bMoves, bChecks)
	else:
		#B is smaller than A
		compressable = can_compress(bMoves, bChecks, aMoves, aChecks)
	
	#Uncompressable and unequal means keep both
	if !compressable:
		return CompareInfo.KEEP_BOTH
	
	#If it can be compressed, this is where shit gets wild
	
	#If A has less steps than B
	if countPriority < 0:
		#If A is an equal or easier trick, keep it
		if methodTrickPriority <= 0:
			return CompareInfo.KEEP_A
		#Otherwise, keep both
		return CompareInfo.KEEP_BOTH
	#If B has less steps than A
	else:
		#If B is an equal or easier trick, keep it
		if methodTrickPriority >= 0:
			return CompareInfo.KEEP_B
		#Otherwise, keep both
		return CompareInfo.KEEP_BOTH

#Check if every element in the smaller list is in the bigger one
static func can_compress(smallerMoves : Array[int], smallerChecks : Array[String], biggerMoves : Array[int], biggerChecks : Array[String]) -> bool:
	for eachMove in smallerMoves:
		if !biggerMoves.has(eachMove):
			return false
	for eachCheck in smallerChecks:
		if !biggerChecks.has(eachCheck):
			return false
	return true

static func offset_compare(valA : int, valB : int):
	if valA == valB:
		return 0
	elif valA > valB:
		return 1
	else:
		return -1
