class_name CombatResolver
extends RefCounted

func resolve(state: MatchState) -> Dictionary:
	if (
		state.is_finished()
		or state.phase != GameEnums.MatchPhase.COMBAT_RESOLUTION
	):
		return {
			"ok": false,
			"message": "Combat belum dapat diselesaikan"
		}
	
	var attacking_player: PlayerState = state.get_player(
		state.panji_owner_id
	)
	
	var defending_player: PlayerState = state.get_opponent(
		state.panji_owner_id
	)
	
	if attacking_player == null or defending_player == null:
		return {
			"ok": false,
			"message": "Data pemain combat tidak valid"
		}
	
	if state.combat_pairs.is_empty():
		return {
			"ok": false,
			"message": "Pasangan combat  belumm tersedia."
		}
	
	var logs: Array[String] = []
	
	for pair in state.combat_pairs:
		var attacker: CardInstance = attacking_player.get_card(
			pair["attacker_id"]
		)

		if not _is_alive_on_bench(attacker):
			continue

		if pair["was_blocked"]:
			var blocker: CardInstance = defending_player.get_card(
				pair["blocker_id"]
			)

			if _is_alive_on_bench(blocker):
				var attack_damage: int = attacker.get_daya()
				var block_damage: int = blocker.get_daya()

				attacker.take_damage(block_damage)
				blocker.take_damage(attack_damage)

				logs.append(
					"%s menerima %d; %s menerima %d damage." % [
						attacker.instance_id,
						block_damage,
						blocker.instance_id,
						attack_damage
					]
				)
		else:
			var damage: int = attacker.get_daya()

			defending_player.arca_sukma = maxi(
				defending_player.arca_sukma - damage,
				0
			)

			logs.append(
				"Arca pemain %d menerima %d damage." % [
					defending_player.player_id,
					damage
				]
			)

		_remove_dead_units(state)
			
	_check_result(state)
	
	state.attacker_ids.clear()
	state.combat_pairs.clear()
	state.consecutive_passes = 0
	
	if not state.is_finished():
		state.phase = GameEnums.MatchPhase.ACTION_PRIORITY
		state.priority_player_id = defending_player.player_id
	
	return {
		"ok": true,
		"message": "Combat selesai.",
		"logs": logs
	}
	
func _is_alive_on_bench(unit: CardInstance) -> bool:
	return (
		unit != null
		and unit.zone == GameEnums.CardZone.BENCH
		and not unit.is_dead()
	)

func _remove_dead_units(state: MatchState) -> void:
	for player in state.players:
		var occupied_slots: Array[String] = player.bench_slots.duplicate()
		
		for instance_id in occupied_slots:
			if instance_id.is_empty():
				continue
			
			var unit: CardInstance = player.get_card(instance_id)
			remove_dead_unit(state, unit)

func remove_dead_unit(
	state: MatchState,
	unit: CardInstance
) -> bool:
	if state.is_finished() or unit == null:
		return false
	
	if not unit.is_dead() or unit.zone != GameEnums.CardZone.BENCH:
		return false
	
	var owner: PlayerState = state.get_player(unit.owner_id)
	
	if owner == null:
		return false
	
	if unit.slot_index < 0 or unit.slot_index >= PlayerState.BENCH_LIMIT:
		return false
	
	if owner.bench_slots[unit.slot_index] != unit.instance_id:
		return false
	
	owner.bench_slots[unit.slot_index] = ""
	owner.discard_ids.append(unit.instance_id)
	
	unit.zone = GameEnums.CardZone.DISCARD
	unit.slot_index =  -1
	
	return true

func _check_result(state: MatchState) -> void:
	var player_zero_dead: bool = state.get_player(0).arca_sukma <= 0
	var player_one_dead: bool = state.get_player(1).arca_sukma <= 0
	
	if not player_zero_dead and not player_one_dead:
		return
	
	if player_zero_dead and player_one_dead:
		state.result =  GameEnums.MatchResult.DRAW
	elif player_zero_dead:
		state.result = GameEnums.MatchResult.PLAYER_1_WIN
	else:
		state.result = GameEnums.MatchResult.PLAYER_0_WIN
	
	state.phase = GameEnums.MatchPhase.GAME_OVER
	state.priority_player_id = -1
				
