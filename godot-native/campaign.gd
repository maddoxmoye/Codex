extends RefCounted
## Shared campaign schedule; difficulty formulas live here rather than in actor AI.
const WAVES := 20
const REQUIRE_FINAL_KILL := true
const BOSSES := {5:"briar-king",10:"frost-oracle",15:"hollow-monarch",20:"gilded-colossus"}
static func is_boss(id: String) -> bool:return id in BOSSES.values()
static func duration(wave: int) -> float:return 75.0 if BOSSES.has(wave) else 45.0
static func health_scale(wave: int) -> float:return 1+.10*(wave-1)+.012*pow(wave-1,2)
static func damage_scale(wave: int) -> float:return 1+.06*(wave-1)+.015*pow(wave-1,2)
static func pressure(wave: int) -> Dictionary:
	return {"cap":mini(60,8+wave*2),"interval":maxf(.6,2.8-wave*.11),"batch":1+wave/5,"elite":clampf((wave-3)*.015,0,.30),"special":minf(.65,.15+wave*.025)}
static func composition(wave: int) -> Array:
	return ["briarling","briarling","sporecaller","thornback"] if wave<8 else ["briarling","sporecaller","thornback","thornback"]
