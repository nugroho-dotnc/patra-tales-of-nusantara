class_name PlayerState
extends RefCounted
## Penyimpanan kondisi pemain. Mutasi zona nantinya menjadi tugas RulesEngine.

const HAND_LIMIT: int = 6
const BENCH_LIMIT: int = 6

var player_id: int
var arca_sukma: int = 20
var max_arca_sukma: int = 20
var gem_cap: int = 0
var cakra: int = 0
var spell_mana: int = 0
var location_id: String = ""
var cards_by_id: Dictionary[String, CardInstance] = {}
var deck_ids: Array[String] = []
var hand_ids: Array[String] = []
var bench_slots: Array[String] = ["", "", "", "", "", ""]
var discard_ids: Array[String] = []


func _init(id: int = 0) -> void:
	player_id = id


func get_card(instance_id: String) -> CardInstance:
	return cards_by_id.get(instance_id)


func get_hand_count() -> int:
	return hand_ids.size()


func get_bench_count() -> int:
	var occupied: int = 0
	for instance_id in bench_slots:
		if not instance_id.is_empty():
			occupied += 1
	return occupied


func has_hand_space() -> bool:
	return get_hand_count() < HAND_LIMIT


func has_bench_space() -> bool:
	return get_bench_count() < BENCH_LIMIT
