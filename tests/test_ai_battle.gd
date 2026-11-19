extends SceneTree
## Integration tests use the real BattleTest scene and button/card signals.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_used_blocker()
	var scene: PackedScene = load("res://scene/tests/battle_test.tscn")
	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	_check(battle.player.get_bench_count() == 0
		and battle.match_state.get_player(1).get_bench_count() == 0,
		"Both benches start empty without free enemy units")
	var own_jana: CardInstance = battle.player.get_card("p0_jana_1")
	battle.hand_view.card_selected.emit(own_jana)
	battle.add_unit_button.pressed.emit()
	var enemy: PlayerState = battle.match_state.get_player(1)
	_check(enemy.get_bench_count() == 1 and enemy.cakra == 0,
		"AI deploys and pays for a Jana after the human plays")
	_check(battle.match_state.priority_player_id == 0
		and not battle.pass_button.disabled,
		"The human regains priority and can Pass")
	if failures > 0:
		battle.queue_free()
		await process_frame
		_finish()
		return

	battle.attack_button.pressed.emit()
	_check(battle.match_state.phase == GameEnums.MatchPhase.COMBAT_RESPONSE
		and battle.match_state.combat_pairs[0]["blocker_id"] == "p1_jana_1",
		"AI automatically confirms its own blocker")
	battle.pass_button.pressed.emit()
	var enemy_jana: CardInstance = enemy.get_card("p1_jana_1")
	_check(own_jana.current_sukma == 1 and enemy_jana.current_sukma == 1,
		"Blocked combat deals simultaneous damage to both units")
	_check(battle.player.arca_sukma == 20 and enemy.arca_sukma == 20,
		"Blocked combat does not damage either Arca")

	battle.pass_button.pressed.emit()
	_check(battle.match_state.round_number == 2
		and battle.match_state.phase == GameEnums.MatchPhase.BLOCK_WINDOW
		and battle.match_state.priority_player_id == 0,
		"AI attacks on its Panji round and waits for the human blocker")
	_check(not battle.no_block_button.disabled
		and battle.confirm_block_button.disabled,
		"The human can decline blocking or select a blocker")
	battle.bench_view.card_selected.emit(own_jana)
	_check(not battle.confirm_block_button.disabled,
		"Clicking an own Bench unit enables block confirmation")
	battle.confirm_block_button.pressed.emit()
	_check(battle.match_state.phase == GameEnums.MatchPhase.COMBAT_RESPONSE
		and battle.match_state.priority_player_id == 0,
		"After human block, AI passes combat response to human")
	battle.pass_button.pressed.emit()
	_check(own_jana.zone == GameEnums.CardZone.DISCARD
		and enemy_jana.zone == GameEnums.CardZone.DISCARD,
		"Both lethal units enter their own discard piles")
	_check(battle.player.bench_slots[0] == "" and enemy.bench_slots[0] == "",
		"Both dead units release their Bench slots")
	_check(battle.selected_card == null,
		"A dead selected card is no longer selected")

	# A separate path exercises an AI attack that the human does not block.
	battle.reset_button.pressed.emit()
	own_jana = battle.player.get_card("p0_jana_1")
	battle.hand_view.card_selected.emit(own_jana)
	battle.add_unit_button.pressed.emit()
	battle.pass_button.pressed.emit() # AI passes, round 2 starts, AI attacks.
	battle.no_block_button.pressed.emit()
	battle.pass_button.pressed.emit()
	_check(battle.player.arca_sukma == 18,
		"An unblocked AI attack damages the human Arca")
	_check(not battle.match_state.is_finished()
		and battle.match_state.phase == GameEnums.MatchPhase.ACTION_PRIORITY,
		"Combat returns to the normal action phase")

	# Low Arca health is a test fixture, not a change to normal match setup.
	battle.reset_button.pressed.emit()
	battle.match_state.get_player(1).arca_sukma = 2
	own_jana = battle.player.get_card("p0_jana_1")
	battle.hand_view.card_selected.emit(own_jana)
	battle.add_unit_button.pressed.emit()
	var defender: CardInstance = battle.match_state.get_player(1).get_card("p1_jana_1")
	defender.take_damage(3)
	battle.combat_resolver.remove_dead_unit(battle.match_state, defender)
	battle.attack_button.pressed.emit()
	battle.pass_button.pressed.emit()
	_check(battle.match_state.result == GameEnums.MatchResult.PLAYER_0_WIN
		and battle.pass_button.disabled and battle.attack_button.disabled
		and battle.add_unit_button.disabled,
		"A lethal human attack wins and disables game actions")
	var late_action: Dictionary = battle.simple_ai.take_action(battle.match_state)
	_check(not late_action["ok"], "AI cannot act after game over")

	battle.reset_button.pressed.emit()
	battle.player.arca_sukma = 2
	own_jana = battle.player.get_card("p0_jana_1")
	battle.hand_view.card_selected.emit(own_jana)
	battle.add_unit_button.pressed.emit()
	battle.pass_button.pressed.emit()
	battle.no_block_button.pressed.emit()
	battle.pass_button.pressed.emit()
	_check(battle.match_state.result == GameEnums.MatchResult.PLAYER_1_WIN
		and battle.pass_button.disabled and battle.no_block_button.disabled,
		"A lethal AI attack wins and stops further decisions")
	# Setup and phase flags must be fresh after a reset.
	battle.reset_button.pressed.emit()
	_check(battle.match_state.round_number == 1
		and battle.match_state.panji_owner_id == 0
		and battle.selected_blocker == null
		and battle.player.arca_sukma == 20,
		"Reset restores first-round state and clears the blocker")
	battle.queue_free()
	await process_frame
	_finish()


func _test_used_blocker() -> void:
	var jawara := CardDefinition.new()
	jawara.card_type = GameEnums.CardType.JAWARA
	jawara.cost = 3
	jawara.max_sukma = 5
	var jana := CardDefinition.new()
	jana.cost = 1
	jana.base_daya = 2
	jana.max_sukma = 3
	var setup := MatchSetup.new()
	var state: MatchState = setup.create_match(jawara, jana)
	setup.prepare_training_enemy_bench(state)
	RoundSystem.new().start_match(state)
	var rules := RulesEngine.new()
	rules.play_unit(state, 0, "p0_jana_1")
	rules.pass_priority(state, 1)
	var attackers: Array[String] = ["p0_jana_1"]
	rules.declare_attack(state, 0, attackers)
	state.get_player(1).get_card("p1_jana_1").blocked_this_round = true
	var result: Dictionary = SimpleAI.new().take_action(state)
	_check(result["ok"], "AI skips a blocker already used this round")
	if result["ok"]:
		_check(state.combat_pairs[0]["blocker_id"] == "p1_jana_2",
			"AI chooses the next available blocker")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _finish() -> void:
	print("AI battle: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
