extends RefCounted
## Production definitions reuse the approved motion studies. Unlock policy is deliberately
## permissive for this test build; future progression must change only this boundary.
const IDS := ["rowan","ash","briar","nyx","pip"]
static var definitions: Dictionary = {}
static func get_archer(id: String) -> Dictionary:
	if definitions.is_empty():definitions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/archers.json"))
	return definitions.get(id,definitions.rowan)
static func unlocked(id: String) -> bool:
	return id in IDS and bool(get_archer(id).unlocked)
