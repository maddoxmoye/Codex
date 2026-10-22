extends RefCounted
## Shared campaign schedule; difficulty formulas live here rather than in actor AI.
const WAVES := 20
const REQUIRE_FINAL_KILL := true
const BOSSES := {5:"briar-king",10:"frost-oracle",15:"hollow-monarch",20:"gilded-colossus"}
static func is_boss(id: String) -> bool:return id in BOSSES.values()
static func duration(wave: int) -> float:return 75.0 if BOSSES.has(wave) else 45.0
static func health_scale(wave: int) -> float:return 1+.22*(wave-1)
static func damage_scale(wave: int) -> float:return 1+.18*(wave-1)
static func pressure(wave: int) -> Dictionary:
	return {"cap":8+wave,"interval":maxf(1.0,3.0-wave*.1),"batch":1,"elite":0.0,"special":.3}
static func composition(wave: int) -> Array:
	return ["briarling","briarling","sporecaller","thornback"] if wave<8 else ["briarling","sporecaller","thornback","thornback"]
