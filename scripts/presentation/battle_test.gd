extends Control

@onready var add_unit_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/AddUnitButton
)

@onready var resource_label: Label = (
	$CenterContainer/Layout/ResourceLabel
)

@onready var bench_view: BenchView = (
	$CenterContainer/Layout/BenchView
)
@onready var damage_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/DamageButton
)
@onready var heal_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/HealButton
)
@onready var reset_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/ResetButton
)

@onready var hand_view: HandView = (
	$CenterContainer/Layout/HandView
)

@onready var draw_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/DrawButton
)

@onready var pass_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/PassButton
)

@onready var attack_button: Button = (
	$CenterContainer/Layout/AllButtons/Buttons/AttackButton
)

@onready var enemy_bench_view: BenchView = (
	$CenterContainer/Layout/EnemyBenchView
)

@onready var confirm_block_button: Button = (
	$CenterContainer/Layout/AllButtons/CombatButtons/ConfirmBlockButton
)

@onready var no_block_button: Button = (
	$CenterContainer/Layout/AllButtons/CombatButtons/NoBlockButton
)

var definition: CardDefinition
var player: PlayerState
var anoman: CardInstance
var jana_definition: CardDefinition
var selected_card: CardInstance
var rules_engine: RulesEngine = RulesEngine.new()
var match_setup: MatchSetup = MatchSetup.new()
var match_state: MatchState
var round_system: RoundSystem = RoundSystem.new()
var selected_blocker: CardInstance
var combat_resolver: CombatResolver = CombatResolver.new()
var simple_ai: SimpleAI = SimpleAI.new()

func _ready() -> void:
	confirm_block_button.pressed.connect(_on_confirm_block_pressed)
	no_block_button.pressed.connect(_on_no_block_pressed)
	add_unit_button.pressed.connect(_on_add_unit_pressed)
	damage_button.pressed.connect(_on_damage_pressed)
	heal_button.pressed.connect(_on_heal_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	bench_view.card_selected.connect(_on_card_selected)
	hand_view.card_selected.connect(_on_card_selected)
	draw_button.pressed.connect(_on_draw_pressed)
	pass_button.pressed.connect(_on_pass_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	_create_definition()
	_reset_bench()


func _create_definition() -> void:
	definition = CardDefinition.new()
	definition.id = "jawara_anoman"
	definition.display_name = "Anoman"
	definition.card_type = GameEnums.CardType.JAWARA
	definition.cost = 3
	definition.base_daya = 3
	definition.max_sukma = 5
	
	jana_definition = CardDefinition.new()
	jana_definition.id = "jana_latihan"
	jana_definition.display_name = "Jana Latihan"
	jana_definition.card_type = GameEnums.CardType.JANA
	jana_definition.cost = 1
	jana_definition.base_daya = 2
	jana_definition.max_sukma = 3

func _reset_bench() -> void:
	selected_card = null
	selected_blocker = null
	match_state = match_setup.create_match(
		definition, jana_definition
	)
		
	var result: Dictionary = round_system.start_match(match_state)
	print(result['message'])
	
	player = match_state.get_player(0)
	anoman = player.get_card("p0_anoman")
	
	bench_view.bind_player(player)
	hand_view.bind_player(player)

	enemy_bench_view.bind_player(
		match_state.get_player(1)
	)
	
	_on_card_selected(anoman)
	_update_resources()
	_resolve_flow()

func _update_resources() -> void:
	resource_label.text = (
		"Ronde %d | Panji: Pemain %d | Cakra: %d/%d | Mantra: %d/3\n"
		+ "Deck: %d | Tangan: %d | Discard: %d"
	) % [
		match_state.round_number,
		match_state.panji_owner_id,
		player.cakra,
		player.gem_cap,
		player.spell_mana,
		player.deck_ids.size(),
		player.get_hand_count(),
		player.discard_ids.size()
	]

	if match_state.is_finished():
		resource_label.text += "\nPertandingan selesai."
	
	var priority_text: String = "Transisi"
	
	if match_state.phase in [
			GameEnums.MatchPhase.ACTION_PRIORITY,
			GameEnums.MatchPhase.COMBAT_RESPONSE
		]:
			
		if match_state.priority_player_id == player.player_id:
			priority_text = "Kamu"
		else:
			priority_text = "Lawan"
	
	resource_label.text += "\nPrioritas: %s | Pass beruntun: %d" % [
		priority_text,
		match_state.consecutive_passes
	]
	
	if match_state.phase == GameEnums.MatchPhase.BLOCK_WINDOW:
		resource_label.text += (
			"\nSerangan: %d unit. Menunggu pemilihan blocker."
			% match_state.attacker_ids.size()
		)
	
	var enemy: PlayerState = match_state.get_player(1)

	resource_label.text += "\nBench atas: Musuh (%d/6) | Bench bawah: Kamu (%d/6)" % [
		enemy.get_bench_count(),
		player.get_bench_count()
	]
	
	if match_state.phase == GameEnums.MatchPhase.COMBAT_RESPONSE:
		resource_label.text += "\nBlock selesai. Menunggu respons combat."
	if _is_human_block_window():
		resource_label.text += "\nMusuh menyerang! Pilih unit Bench bawah untuk block, atau pilih Tanpa Block."
	
	resource_label.text += "\nArca Kamu: %d | Arca Musuh: %d" % [
		player.arca_sukma,
		enemy.arca_sukma
	]

	if match_state.is_finished():
		match match_state.result:
			GameEnums.MatchResult.PLAYER_0_WIN:
				resource_label.text += "\nKamu menang!"
			GameEnums.MatchResult.PLAYER_1_WIN:
				resource_label.text += "\nKamu kalah."
			GameEnums.MatchResult.DRAW:
				resource_label.text += "\nHasil seri."
	
func _remove_dead_unit(unit: CardInstance) -> void:
	if combat_resolver.remove_dead_unit(match_state, unit):
		print("%s masuk discard."%unit.instance_id)

	_update_resources()
	
func _on_add_unit_pressed() -> void:
	
	if selected_card == null:
		return
	
	var unit: CardInstance = selected_card
	
	var result: Dictionary = rules_engine.play_unit(
		match_state,
		player.player_id,
		unit.instance_id
	)
	
	print(result['message'])
	
	if not result['ok']:
		return

	# Kartu yang dimainkan langsung dipilih di Bench.
	_on_card_selected(unit)
	_resolve_flow()

func _on_damage_pressed() -> void:
	if not _can_test_selected():
		return

	selected_card.take_damage(1)

	if selected_card.is_dead():
		_remove_dead_unit(selected_card)
		selected_card = null
		bench_view.set_selected_card("")

	bench_view.refresh()
	_update_buttons()


func _on_heal_pressed() -> void:
	if not _can_test_selected():
		return

	selected_card.heal(1)
	bench_view.refresh()
	_update_buttons()


func _update_buttons() -> void:
	var can_act: bool = _human_has_priority()
	var can_test: bool = _can_test_selected()

	damage_button.disabled = not can_test
	heal_button.disabled = not can_test

	var hand_unit_selected: bool = (
		selected_card != null
		and selected_card.zone == GameEnums.CardZone.HAND
		and selected_card.definition.is_unit()
	)

	add_unit_button.disabled = not (can_act and hand_unit_selected)
	pass_button.disabled = not _human_can_pass()
	draw_button.disabled = true
	
	var can_attack: bool = (
		_human_has_priority()
		and match_state.panji_owner_id == player.player_id
		and not match_state.attack_used
		and selected_card != null
		and selected_card.zone  == GameEnums.CardZone.BENCH
		and selected_card.definition.is_unit()
		and not selected_card.is_dead()
		and not selected_card.attacked_this_round
	)
	
	attack_button.disabled = not can_attack
	
	var choosing_blocker: bool = _is_human_block_window()
	
	confirm_block_button.disabled = not (
		choosing_blocker and selected_blocker != null
	)
	
	no_block_button.disabled = not choosing_blocker
	
func _on_card_selected(unit: CardInstance) -> void:
	if unit.owner_id != player.player_id:
		return
	if _is_human_block_window():
		if (
			unit.zone != GameEnums.CardZone.BENCH
			or unit.is_dead()
			or unit.blocked_this_round
		):
			return
		selected_blocker = unit
		bench_view.set_selected_card(unit.instance_id)
		_update_buttons()
		print("Blocker kamu: %s" % unit.instance_id)
		return

	if unit.is_dead():
		return

	var in_hand: bool = unit.zone == GameEnums.CardZone.HAND
	var on_bench: bool = unit.zone == GameEnums.CardZone.BENCH

	if not in_hand and not on_bench:
		return

	selected_card = unit

	if in_hand:
		hand_view.set_selected_card(unit.instance_id)
		bench_view.set_selected_card("")
	else:
		hand_view.set_selected_card("")
		bench_view.set_selected_card(unit.instance_id)

	_update_buttons()

	print(
		"Dipilih: %s, biaya %d Cakra." % [
			unit.definition.display_name,
			unit.definition.cost
		]
	)

func _on_draw_pressed() -> void:
	var result: Dictionary = rules_engine.draw_card(player)
	
	print(result["message"])
	
	if not result["ok"]:
		return
	
	hand_view.refresh()
	_update_resources()

func _can_test_selected() -> bool:
	return (
		_human_has_priority()
		and selected_card != null
		and selected_card.zone == GameEnums.CardZone.BENCH
		and not selected_card.is_dead()
	)

func _on_reset_pressed() -> void:
	_reset_bench()

func _on_pass_pressed() -> void:
	var result: Dictionary = rules_engine.pass_priority(
		match_state,
		player.player_id
	)
	
	print(result["message"])
	
	if result["ok"]:
		_resolve_flow()

func _on_attack_pressed() -> void:
	if selected_card == null:
		return
	
	var attackers: Array[String] = [
		selected_card.instance_id
	]
	
	var result:  Dictionary = rules_engine.declare_attack(
		match_state,
		player.player_id,
		attackers
	)
	print(result["message"])
	
	if result["ok"]:
		_resolve_flow()

func _resolve_flow() -> void:
	while not match_state.is_finished():
		if match_state.phase == GameEnums.MatchPhase.COMBAT_RESOLUTION:
			var combat_result: Dictionary = combat_resolver.resolve(
				match_state
			)
			print(combat_result["message"])

			if not combat_result["ok"]:
				break

			for message in combat_result["logs"]:
				print(message)

		elif match_state.phase == GameEnums.MatchPhase.ROUND_END:
			var round_result: Dictionary = round_system.advance_round(
				match_state
			)

			print(round_result["message"])

			if not round_result["ok"]:
				break

		elif match_state.priority_player_id == 1:
			var ai_result: Dictionary = simple_ai.take_action(
				match_state
			)
			print("AI: %s" % ai_result["message"])

			if not ai_result["ok"]:
				break

		else:
			break

	_refresh_battle()

func _human_has_priority() -> bool:
	return (
		not match_state.is_finished()
		and match_state.phase == GameEnums.MatchPhase.ACTION_PRIORITY
		and match_state.priority_player_id == player.player_id
	)

func _refresh_battle() -> void:
	if selected_card != null and selected_card.zone == GameEnums.CardZone.DISCARD:
		selected_card = null
		bench_view.set_selected_card("")
	enemy_bench_view.refresh()
	bench_view.refresh()
	hand_view.refresh()
	_update_resources()
	_update_buttons()

func _is_human_block_window() -> bool:
	return (
		not match_state.is_finished()
		and match_state.phase == GameEnums.MatchPhase.BLOCK_WINDOW
		and match_state.priority_player_id == player.player_id
		and match_state.panji_owner_id != player.player_id
	)

func _on_confirm_block_pressed() -> void:
	if selected_blocker == null:
		return
	
	_confirm_human_block(selected_blocker.instance_id)
	
func _on_no_block_pressed() -> void:
	_confirm_human_block("")

func _confirm_human_block(blocker_id: String) -> void:
	if not _is_human_block_window():
		return
	
	var result: Dictionary = rules_engine.confirm_block(
		match_state,
		player.player_id,
		blocker_id
	)
	
	print(result["message"])
	
	if result["ok"]:
		print(match_state.combat_pairs)
		selected_blocker = null
		bench_view.set_selected_card("")
		_resolve_flow()
	
func _human_can_pass() -> bool:
	return (
		not match_state.is_finished()
		and match_state.phase in [
			GameEnums.MatchPhase.ACTION_PRIORITY,
			GameEnums.MatchPhase.COMBAT_RESPONSE
		]
		and match_state.priority_player_id == player.player_id
	)
