class_name MatchState
extends RefCounted
## State dua pemain; belum mengatur giliran, kemenangan, atau resolusi efek.

var match_id: String = ""
var seed: int = 0
var round_number: int = 0
var phase: GameEnums.MatchPhase = GameEnums.MatchPhase.SETUP
var priority_player_id: int = -1
var panji_owner_id: int = -1
var attack_used: bool = false
var consecutive_passes: int = 0
var result: GameEnums.MatchResult = GameEnums.MatchResult.NONE
var players: Array[PlayerState] = []
var attacker_ids: Array[String] = []
var combat_pairs: Array[Dictionary] = []



func _init() -> void:
	players = [PlayerState.new(0), PlayerState.new(1)]


func get_player(player_id: int) -> PlayerState:
	for player in players:
		if player.player_id == player_id:
			return player
	return null


func get_opponent(player_id: int) -> PlayerState:
	if get_player(player_id) == null:
		return null
	for player in players:
		if player.player_id != player_id:
			return player
	return null


func is_finished() -> bool:
	return result != GameEnums.MatchResult.NONE
