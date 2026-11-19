class_name MatchSetup extends RefCounted

func create_player(
	jawara_definition: CardDefinition,
	jana_definition: CardDefinition,
	player_id: int = 0
)-> PlayerState:
	var player := PlayerState.new(player_id)
	_add_to_deck(
		player,
		jawara_definition,
		"p%d_anoman" % player_id
	)
	
	for index in range(9):
		_add_to_deck(
			player,
			jana_definition,
			"p%d_jana_%d" % [player_id, index + 1]
		)
	
	var rules := RulesEngine.new()
	
	for index in range(4):
		rules.draw_card(player)
	
	return player

func _add_to_deck(
	player: PlayerState,
	definition: CardDefinition,
	instance_id: String
)-> void:
	var card := CardInstance.new(
		definition,
		instance_id,
		player.player_id
	)
	
	player.cards_by_id[instance_id] = card
	player.deck_ids.append(instance_id)
	card.zone = GameEnums.CardZone.DECK

func create_match(
	jawara_definition: CardDefinition,
	jana_definition: CardDefinition
)-> MatchState:
	var state:= MatchState.new()
	
	for player_id in range(2):
		state.players[player_id] = create_player(
			jawara_definition,
			jana_definition,
			player_id
		)
	return state
	

func prepare_training_enemy_bench(state: MatchState) -> void:
	var enemy: PlayerState = state.get_player(1)
	
	var starting_hand: Array[String] = enemy.hand_ids.duplicate()
	
	for instance_id in starting_hand:
		if enemy.get_bench_count() >= 2:
			break
		var card: CardInstance = enemy.get_card(instance_id)
		
		if card.definition.card_type != GameEnums.CardType.JANA:
			continue
		
		var empty_slot: int = enemy.bench_slots.find("")
		
		if empty_slot == -1:
			break
		
		enemy.hand_ids.erase(instance_id)
		enemy.bench_slots[empty_slot] = instance_id
		
		card.zone = GameEnums.CardZone.BENCH
		card.slot_index = empty_slot
		
