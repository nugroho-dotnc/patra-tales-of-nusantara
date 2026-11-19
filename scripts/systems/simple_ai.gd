class_name SimpleAI extends RefCounted

const PLAYER_ID: int = 1

var rules: RulesEngine = RulesEngine.new()

func take_action(state: MatchState) -> Dictionary:
	if state.is_finished() or state.priority_player_id != PLAYER_ID:
		return {
			"ok": false,
			"message": "AI tidak sedang mendapat prioritas."
		}
	
	var player: PlayerState = state.get_player(PLAYER_ID)
	
	match state.phase:
		GameEnums.MatchPhase.BLOCK_WINDOW:
			var blocker_id: String = _find_ready_unit(player, false)
			
			return rules.confirm_block(
				state,
				PLAYER_ID,
				blocker_id
			)
		GameEnums.MatchPhase.COMBAT_RESPONSE:
			return rules.pass_priority(state, PLAYER_ID)
		
		GameEnums.MatchPhase.ACTION_PRIORITY:
			return _choose_main_action(state, player)
	return {
		"ok": false,
		"message": "AI belum menangani fase ini."
	}

func _choose_main_action(
	state: MatchState,
	player: PlayerState
)-> Dictionary:
	if state.panji_owner_id == PLAYER_ID and not state.attack_used:
		var attacker_id: String = _find_ready_unit(player, true)
		
		if not attacker_id.is_empty():
			var attackers: Array[String] = [attacker_id]
			
			return rules.declare_attack(
				state,
				PLAYER_ID,
				attackers
			)
	
	if player.has_bench_space():
		for instance_id in player.hand_ids:
			var card: CardInstance = player.get_card(instance_id)
			
			if card == null:
				continue
			
			if (
				not card.definition.is_unit()
				or card.is_dead()
				or card.definition.cost < 0
				or card.definition.cost > player.cakra
			):
				continue
			
			return rules.play_unit(
				state,
				PLAYER_ID,
				instance_id
			)
	return rules.pass_priority(state, PLAYER_ID)

func _find_ready_unit(
	player: PlayerState,
	for_attack: bool
)-> String:
	for instance_id in player.bench_slots:
		if instance_id.is_empty():
			continue
		
		var card: CardInstance = player.get_card(instance_id)
		
		if card == null:
			continue
		
		if (
			card.zone != GameEnums.CardZone.BENCH
			or not card.definition.is_unit()
			or card.is_dead()
		):
			continue
		
		if for_attack and card.attacked_this_round:
			continue
		if not for_attack and card.blocked_this_round:
			continue
		
		return instance_id
	return ""
