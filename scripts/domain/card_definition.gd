class_name CardDefinition
extends Resource
## Data dasar bersama. Jangan mengubah definisi ketika match berlangsung.

@export var id: String = ""
@export var display_name: String = ""
@export var card_type: GameEnums.CardType = GameEnums.CardType.JANA
@export_range(0, 10) var cost: int = 0
@export var base_daya: int = 0
@export var max_sukma: int = 1
@export var spell_speed: GameEnums.SpellSpeed = GameEnums.SpellSpeed.NONE
@export var tags: Array[String] = []


func is_unit() -> bool:
	return card_type == GameEnums.CardType.JAWARA or card_type == GameEnums.CardType.JANA
