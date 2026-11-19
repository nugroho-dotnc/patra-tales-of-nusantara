extends SceneTree
## Run: Godot --headless --path . --script res://tests/test_base_classes.gd

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	# Runtime loading lets missing implementations fail explicitly before import.
	var paths := [
		"res://scripts/domain/game_enums.gd",
		"res://scripts/domain/card_definition.gd",
		"res://scripts/domain/card_instance.gd",
		"res://scripts/domain/player_state.gd",
		"res://scripts/domain/match_state.gd",
	]
	for path in paths:
		_check(FileAccess.file_exists(path), "Domain script exists: " + path)
	if failures > 0:
		_finish()
		return
	_test_cards()
	_test_players_and_matches()
	_finish()


func _test_cards() -> void:
	var enums = load("res://scripts/domain/game_enums.gd")
	var definition_script = load("res://scripts/domain/card_definition.gd")
	var instance_script = load("res://scripts/domain/card_instance.gd")
	var definition = definition_script.new()
	definition.id = "test_jana"
	definition.base_daya = 3
	definition.max_sukma = 5
	var first = instance_script.new(definition, "card_1", 0)
	var second = instance_script.new(definition, "card_2", 0)
	first.take_damage(2)
	_check(first.current_sukma == 3, "Damage changes the targeted instance")
	_check(second.current_sukma == 5 and definition.max_sukma == 5,
		"Damage does not change another instance or the definition")
	first.take_damage(-3)
	_check(first.current_sukma == 3, "Negative damage cannot heal")
	first.heal(-2)
	_check(first.current_sukma == 3, "Negative heal cannot damage")
	first.heal(100)
	_check(first.current_sukma == 5, "Healing caps at maximum Sukma")
	_check(first.get_daya() == 3, "Effective base Daya is available")
	first.take_damage(100)
	_check(first.current_sukma == 0 and first.is_dead(), "Lethal damage clamps to zero")
	first.heal(2)
	_check(first.current_sukma == 0, "Healing cannot resurrect")
	first.attacked_this_round = true
	first.blocked_this_round = true
	first.reset_round_flags()
	_check(not first.attacked_this_round and not first.blocked_this_round,
		"Both round action flags reset")
	var spell_definition = definition_script.new()
	spell_definition.card_type = enums.CardType.MANTRA
	var spell = instance_script.new(spell_definition, "spell_1", 0)
	spell.take_damage(2)
	spell.heal(3)
	_check(not spell_definition.is_unit() and not spell.is_dead()
		and spell.current_sukma == 0 and spell.get_daya() == 0,
		"Mantra never behaves as a damaged or dead unit")
	definition.card_type = enums.CardType.JAWARA
	_check(definition.is_unit(), "Jawara is a unit")


func _test_players_and_matches() -> void:
	var match_script = load("res://scripts/domain/match_state.gd")
	var enums = load("res://scripts/domain/game_enums.gd")
	var definition_script = load("res://scripts/domain/card_definition.gd")
	var instance_script = load("res://scripts/domain/card_instance.gd")
	var state = match_script.new()
	var other = match_script.new()
	var player = state.get_player(0)
	_check(state.players.size() == 2 and state.get_opponent(0).player_id == 1
		and state.get_opponent(1).player_id == 0, "A match has two distinct opponents")
	_check(state.get_player(-1) == null and state.get_player(2) == null
		and state.get_opponent(9) == null, "Unknown player IDs return null")
	_check(not state.is_finished() and state.phase == enums.MatchPhase.SETUP,
		"A new match is in setup and unfinished")
	_check(player.has_hand_space() and player.has_bench_space()
		and player.get_hand_count() == 0 and player.get_bench_count() == 0,
		"New player has empty hand and bench")
	var definition = definition_script.new()
	var card = instance_script.new(definition, "fixture_1", 0)
	player.cards_by_id[card.instance_id] = card
	player.hand_ids.append(card.instance_id)
	_check(player.get_card("fixture_1") == card and player.get_card("missing") == null,
		"Card lookup returns the instance or null")
	player.hand_ids.clear()
	for index in range(6):
		player.hand_ids.append("card_%d" % index)
		player.bench_slots[index] = "unit_%d" % index
	_check(not player.has_hand_space() and player.get_hand_count() == 6,
		"A full hand has no space")
	_check(not player.has_bench_space() and player.get_bench_count() == 6,
		"All six occupied bench slots mean full")
	player.bench_slots[2] = ""
	_check(player.has_bench_space() and player.get_bench_count() == 5,
		"An empty middle slot counts as available space")
	_check(state.get_player(1).get_hand_count() == 0
		and state.get_player(1).get_bench_count() == 0
		and other.get_player(0).get_hand_count() == 0
		and other.get_player(0).cards_by_id.is_empty(),
		"Players and matches do not share mutable collections")
	state.result = enums.MatchResult.DRAW
	_check(state.is_finished(), "A draw finishes the match")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _finish() -> void:
	print("Base classes: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
