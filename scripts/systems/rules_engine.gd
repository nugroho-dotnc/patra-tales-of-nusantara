class_name RulesEngine extends RefCounted

func play_unit(
	state: MatchState,
	player_id: int,
	instance_id: String
) -> Dictionary:
	var validation: Dictionary = _validate_priority(state, player_id)
	
	if not validation["ok"]:
		return validation

	var player: PlayerState = state.get_player(player_id)
	var unit: CardInstance = player.get_card(instance_id)
	
	if unit == null:
		return {
			"ok": false,
			"message": "Kartu tidak ditemukan."
		}
	
	if unit.owner_id != player.player_id:
		return {
			"ok": false,
			"message": "Kartu bukan milik pemain."
		}
	
	if(
		unit.zone != GameEnums.CardZone.HAND or not player.hand_ids.has(instance_id)
	):
		return {
			"ok": false,
			"message": "Kartu bukan unit hidup yang dapat dimainkan."
		}
	
	if not unit.definition.is_unit() or unit.is_dead():
		return {
			"ok": false,
			"message": "Kartu bukan unit hidup yang dapat dimainkan"
		}
		
	var empty_slot: int = _find_empty_bench_slot(player)
	
	if empty_slot == -1:
		return {
			"ok": false,
			"message": "Bench penuh!"
		}
	
	var cost: int = unit.definition.cost
	
	if cost < 0:
		return {
			"ok": false,
			"message": "Biaya kartu tidak valid."
		}
	
	if player.cakra < cost:
		return {
			"ok": false,
			"message": "Cakra tidak cukup!"
		}
	
	player.cakra -= cost
	player.hand_ids.erase(instance_id)
	player.bench_slots[empty_slot] = instance_id
	
	unit.zone = GameEnums.CardZone.BENCH
	unit.slot_index = empty_slot
	
	state.consecutive_passes = 0
	state.priority_player_id = 1 - player_id
	
	return {
		"ok": true,
		"message": "%s dimainkan ke slot %d" % [
			unit.definition.display_name,
			empty_slot + 1
		]
	}
	
func _find_empty_bench_slot(player: PlayerState) -> int:
	for index in range(PlayerState.BENCH_LIMIT):
		if player.bench_slots[index].is_empty():
			return index
	return -1

func draw_card(player: PlayerState) -> Dictionary:
	if player == null:
		return {
			"ok": false,
			"code": "INVALID_PLAYER",
			'message': "Data pemain belum tersedia."
		}
	
	if not player.has_hand_space():
		return {
			"ok": false,
			"code": "HAND_FULL",
			"message": "Tangan penuh. Kartu tetap di deck."
		}
	
	if player.deck_ids.is_empty():
		return {
			"ok": false,
			"code": "DECK_EMPTY",
			"message": "Deck Kosong."
		}
	
	var instance_id: String = player.deck_ids[0]
	var card: CardInstance = player.get_card(instance_id)
	
	if card == null or card.zone != GameEnums.CardZone.DECK:
		return {
			"ok": false,
			"code": "INVALID_CARD",
			"message": "Data kartu dalam deck tidak valid."
		}
	
	player.deck_ids.remove_at(0)
	player.hand_ids.append(instance_id)
	card.zone = GameEnums.CardZone.HAND
	card.slot_index = -1
	
	return {
		"ok": true,
		"code": "DRAWN",
		"message": "Menarik %s." % card.definition.display_name
	}

func _validate_priority(
	state: MatchState,
	player_id: int,
	allow_combat_response: bool = false
) -> Dictionary:
	
	if state.is_finished():
		return {
			"ok": false,
			"message": "Perbandingan sudah selesai"
		}
		
	var allowed_phase: bool = (
		state.phase == GameEnums.MatchPhase.ACTION_PRIORITY
		or (
			allow_combat_response
			and state.phase == GameEnums.MatchPhase.COMBAT_RESPONSE
		)
	)
	
	if not allowed_phase:
		return {
			"ok": false,
			"message": "Aksi tidak tersedia pada fase ini."
		}
	
	if state.get_player(player_id) == null:
		return {
			"ok": false,
			"message": "Pemain tidak ditemukan."		
			}
	
	if state.priority_player_id != player_id:
		return {
			"ok": false,
			"message": "Pemain belum mendapat prioritas."
		}
	
	return {"ok": true, "message": ""}

func pass_priority(
	state: MatchState,
	player_id: int
) -> Dictionary:
	var validation: Dictionary = _validate_priority(state, player_id, true)
	
	if not validation["ok"]:
		return validation
	
	state.consecutive_passes += 1
	
	if state.consecutive_passes >= 2:
		if state.phase == GameEnums.MatchPhase.COMBAT_RESPONSE:
			state.phase = GameEnums.MatchPhase.COMBAT_RESOLUTION
		else:
			state.phase =  GameEnums.MatchPhase.ROUND_END
			
		state.priority_player_id = -1
	else:
		state.priority_player_id = 1 - player_id
		
	return {
		"ok": true,
		"message": "Pemain %d Pass. Hitungan:  %d." % [
			player_id,
			state.consecutive_passes
		]
	}

func declare_attack(
	state: MatchState,
	player_id: int,
	unit_ids: Array[String]
) -> Dictionary:
	var validation: Dictionary = _validate_priority(state, player_id)
	
	if not validation["ok"]:
		return validation
	
	if state.panji_owner_id != player_id:
		return {
			"ok": false,
			"message": "Panji bukan milik pemain ini."
		}
	
	if state.attack_used:
		return {
			"ok": false,
			"message": "Pilih satu sampai enam penyerang"
		}
	
	if unit_ids.is_empty() or unit_ids.size() > PlayerState.BENCH_LIMIT:
		return {
			"ok": false,
			"message": "Pilih  satu  sampai enam penyerang."
		}
	
	var player: PlayerState = state.get_player(player_id)
	var checked_ids: Array[String] = []
	
	for instance_id in unit_ids:
		if checked_ids.has(instance_id):
			return {
				"ok": false,
				"message": "Unit yang sama dipilih lebih dari sekali."
			}
		var unit: CardInstance = player.get_card(instance_id)
		
		if unit == null:
			return {
				"ok": false,
				"message": "Penyerang tidak ditemukan."
			}
		
		if (
			unit.owner_id != player_id
			or unit.zone != GameEnums.CardZone.BENCH
			or not unit.definition.is_unit()
			or unit.is_dead()
			or unit.attacked_this_round
		):
			return {
				"ok": false,
				"message": "Unit tidak dapat menyerang"
			}
		
		if (
			unit.slot_index < 0
			or unit.slot_index >= PlayerState.BENCH_LIMIT
		):
			return {
				"ok": false,
				"message": "Posisi penyerang tidak valid."
			}
		
		if player.bench_slots[unit.slot_index] != instance_id:
			return {
				"ok": false,
				"message": "penyerang tidak berada pada slot bench-nya."
			}
		
		checked_ids.append(instance_id)
	
	state.attacker_ids.assign(checked_ids)
	
	for instance_id in checked_ids:
		player.get_card(instance_id).attacked_this_round = true
		
	state.attack_used = true
	state.consecutive_passes = 0
	state.priority_player_id = 1 - player_id
	state.phase = GameEnums.MatchPhase.BLOCK_WINDOW
	
	return {
		"ok": true,
		"message":  "Serangan di deklarasikan dengan %d unit." % checked_ids.size()
	}

func confirm_block(
	state: MatchState,
	defender_id: int,
	blocker_id: String = ""
)-> Dictionary:
	if (
		state.is_finished()
		or state.phase != GameEnums.MatchPhase.BLOCK_WINDOW
	):
		return {
			"ok": false,
			"message": "Sekarang bukan waktu memilih blocker."
		}
	
	var defender: PlayerState = state.get_player(defender_id)
	
	if (
		defender == null
		or defender_id == state.panji_owner_id
		or state.priority_player_id != defender_id
	):
		return {
			"ok": false,
			"message": "Pemain ini tidak sedang bertahan."
		}
	
	if state.attacker_ids.size() != 1:
		return {
			"ok": false,
			"message": "Latihan block ini membutuhkan satu penyerang."
		}
	
	var attacker_id: String =  state.attacker_ids[0]
	var attacker_player: PlayerState = state.get_player(
		state.panji_owner_id
	)
	
	var attacker: CardInstance = attacker_player.get_card(attacker_id)
	
	if attacker == null or attacker.is_dead():
		return {
			"ok": false,
			"message": "Penyerang sudah tidak tersedia."
		}
	
	var blocker: CardInstance = null
	
	if not blocker_id.is_empty():
		blocker = defender.get_card(blocker_id)
		
		if blocker == null:
			return {
				"ok": false,
				"message": "Blocker tidak ditemukan."
			}
		
		if (
			blocker.owner_id != defender_id
			or blocker.zone != GameEnums.CardZone.BENCH
			or not blocker.definition.is_unit()
			or blocker.is_dead()
			or blocker.blocked_this_round
		):
			return {
				"ok": false,
				"message": "Unit tidak dapat menghadang."
			}
		
		if (
			blocker.slot_index < 0
			or blocker.slot_index >= PlayerState.BENCH_LIMIT
		):
			return {
				"ok": false,
				"message": "Posisi blocker tidak valid."
			}
		
		if defender.bench_slots[blocker.slot_index] != blocker_id:
			return {
				"ok": false,
				"message": "Blocker tidak berada pada slot Bench-Nya"
			}
	state.combat_pairs.clear()
	state.combat_pairs.append(
		{
			"attacker_id": attacker_id,
			"blocker_id": blocker_id,
			"was_blocked": blocker != null
		}
	)
	
	if blocker != null:
		blocker.blocked_this_round =  true
	
	state.consecutive_passes = 0
	state.priority_player_id = state.panji_owner_id
	state.phase = GameEnums.MatchPhase.COMBAT_RESPONSE
	
	return {
		"ok": true,
		"message": "Block dikonfirmasi: %s menghadapi %s." %[attacker_id, blocker_id if blocker != null else "tanpa blocker"]
	}
