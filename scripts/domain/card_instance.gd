class_name CardInstance
extends RefCounted
## Kondisi satu kartu fisik; tidak menyimpan node atau data tampilan.
## Damage/heal adalah operasi dasar untuk resolver mendatang, bukan combat lengkap.

var instance_id: String
var definition: CardDefinition
var owner_id: int
var zone: GameEnums.CardZone = GameEnums.CardZone.DECK
var slot_index: int = -1
var current_sukma: int = 0
var attacked_this_round: bool = false
var blocked_this_round: bool = false


func _init(card_definition: CardDefinition, unique_id: String, player_id: int) -> void:
	assert(card_definition != null, "CardInstance membutuhkan CardDefinition.")
	assert(not unique_id.is_empty(), "ID instance kartu tidak boleh kosong.")
	definition = card_definition
	instance_id = unique_id
	owner_id = player_id
	if definition.is_unit():
		current_sukma = maxi(definition.max_sukma, 0)


func get_daya() -> int:
	return maxi(definition.base_daya, 0) if definition.is_unit() else 0


func take_damage(amount: int) -> void:
	if definition.is_unit():
		current_sukma = maxi(current_sukma - maxi(amount, 0), 0)


func heal(amount: int) -> void:
	if definition.is_unit() and current_sukma > 0:
		current_sukma = mini(current_sukma + maxi(amount, 0), definition.max_sukma)


func is_dead() -> bool:
	return definition.is_unit() and current_sukma <= 0


func reset_round_flags() -> void:
	attacked_this_round = false
	blocked_this_round = false
