extends SceneTree
## Regression: match setup must initialize Panji before any round alternation.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	var jawara := CardDefinition.new()
	jawara.id = "test_jawara"
	jawara.card_type = GameEnums.CardType.JAWARA
	jawara.max_sukma = 5
	var jana := CardDefinition.new()
	jana.id = "test_jana"
	jana.max_sukma = 3
	var setup := MatchSetup.new()
	var rounds := RoundSystem.new()
	var rules := RulesEngine.new()
	var state: MatchState = setup.create_match(jawara, jana)

	var premature: Dictionary = rounds.advance_round(state)
	_check(not premature["ok"] and state.round_number == 0,
		"Advance before start is rejected without changing the round")

	var result: Dictionary = rounds.start_match(state)
	_check(result["ok"], "Start succeeds")
	_check(state.round_number == 1, "Start initializes round 1")
	_check(state.panji_owner_id == 0, "Start gives Panji to player 0")
	_check(state.priority_player_id == 0, "Start gives priority to player 0")
	_check(state.get_player(0).hand_ids.size() == 4
		and state.get_player(0).deck_ids.size() == 6,
		"Round 1 does not draw beyond the opening hand")

	# Avoid propagating an invalid Panji into draw lookups after a failing start.
	if failures > 0:
		_finish()
		return

	var repeated: Dictionary = rounds.start_match(state)
	_check(not repeated["ok"] and state.round_number == 1
		and state.get_player(0).gem_cap == 1,
		"Starting twice is rejected without giving extra resources")

	var expected_owners: Array[int] = [0, 1, 0, 1, 0, 1]
	for round_number in range(1, 7):
		if round_number > 1:
			_pass_both(state, rules)
			result = rounds.advance_round(state)
			_check(result["ok"], "Advance to round %d succeeds" % round_number)
		_check(state.round_number == round_number
			and state.panji_owner_id == expected_owners[round_number - 1]
			and state.priority_player_id == expected_owners[round_number - 1],
			"Round %d has the expected round, Panji, and priority" % round_number)
		for player in state.players:
			_check(player.cakra == round_number and player.gem_cap == round_number,
				"Player %d resources refill in round %d" % [player.player_id, round_number])

	_check(state.get_player(0).hand_ids.size() == 6
		and state.get_player(0).deck_ids.size() == 4,
		"Full-hand draws keep cards in the deck")
	_pass_both(state, rules)
	var limit: Dictionary = rounds.advance_round(state)
	_check(not limit["ok"] and state.round_number == 6 and state.panji_owner_id == 1,
		"The round 6 test limit does not change Panji")

	var restarted: MatchState = setup.create_match(jawara, jana)
	rounds.start_match(restarted)
	_check(restarted.round_number == 1 and restarted.panji_owner_id == 0,
		"A fresh match resets round and Panji")
	_finish()


func _pass_both(state: MatchState, rules: RulesEngine) -> void:
	rules.pass_priority(state, state.priority_player_id)
	rules.pass_priority(state, state.priority_player_id)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _finish() -> void:
	print("Round system: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
