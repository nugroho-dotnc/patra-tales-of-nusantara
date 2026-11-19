class_name RoundSystem extends RefCounted

const LAST_TEST_ROUND: int = 6

var rules: RulesEngine = RulesEngine.new()

func start_match(state: MatchState)-> Dictionary:
	if state.phase != GameEnums.MatchPhase.SETUP:
		return {
			"ok": false,
			"message": "Pertandingan sudah dimulai"
		}
		
	state.round_number = 1
	state.panji_owner_id = 0
		
	return _begin_round(state)

func advance_round(state: MatchState) -> Dictionary:
	if state.is_finished():
		return {
			"ok": false,
			"message":"Pertandingan sudah selesai."
		}
	
	if (
		state.phase != GameEnums.MatchPhase.ROUND_END 
		or state.consecutive_passes < 2
	):
		return {
			"ok": false,
			"message": "Ronde belum dapat diakhiri"
		}
		
	if state.round_number >= LAST_TEST_ROUND:
		return {
			"ok": false,
			"message": "Latihan berhenti di ronde 6. overtime menyusul"
		}
	
	state.phase = GameEnums.MatchPhase.ROUND_END
	for player in state.players:
		var transfer: int = mini(
			3 - player.spell_mana,
			player.cakra
		)
		
		player.spell_mana += transfer
		player.cakra = 0
		
	state.round_number += 1
	state.panji_owner_id = 1 - state.panji_owner_id
	
	return _begin_round(state)
	

func _begin_round(state: MatchState) -> Dictionary:
	state.phase = GameEnums.MatchPhase.ROUND_START
	state.combat_pairs.clear()
	state.attacker_ids.clear()
	state.attack_used = false
	state.consecutive_passes = 0
	
	for player in state.players:
		for card in player.cards_by_id.values():
			card.reset_round_flags()
	
	state.phase = GameEnums.MatchPhase.OVERTIME_AND_RESOURCE
	
	for player in state.players:
		player.gem_cap = mini(player.gem_cap + 1, 10)
		player.cakra = player.gem_cap
	
#	opening hand sudah diberikan saat setup.
	if state.round_number > 1:
		state.phase = GameEnums.MatchPhase.DRAW
		
		var draw_order: Array[int] = [
			state.panji_owner_id,
			1 - state.panji_owner_id
		]
		
		for player_id in draw_order:
			var player: PlayerState = state.get_player(player_id)
			var result: Dictionary = rules.draw_card(player)
			
			if result["code"] == "DECK_EMPTY":
				state.phase = GameEnums.MatchPhase.GAME_OVER
				
				if player_id == 0:
					state.result = GameEnums.MatchResult.PLAYER_1_WIN
				else:
					state.result = GameEnums.MatchResult.PLAYER_0_WIN
				
				return {
					"ok": true,
					"message": "Pemain %d kalah karena wajib draw dari deck kosong." % player_id
				}
	state.priority_player_id = state.panji_owner_id
	state.phase = GameEnums.MatchPhase.ACTION_PRIORITY
	
	return {
		"ok": true,
		"message": "Ronde %d dimulai." % state.round_number
	}
