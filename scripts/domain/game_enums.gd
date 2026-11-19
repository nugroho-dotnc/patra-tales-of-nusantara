class_name GameEnums
extends RefCounted
## Pilihan nilai bersama untuk model permainan.

enum CardType { JAWARA, JANA, MANTRA }
enum SpellSpeed { NONE, BURST, FAST, SLOW }
enum CardZone { DECK, HAND, BENCH, DISCARD }
enum MatchPhase {
	SETUP,
	ROUND_START,
	OVERTIME_AND_RESOURCE,
	DRAW,
	ACTION_PRIORITY,
	RESPONSE_STACK,
	BLOCK_WINDOW,
	COMBAT_RESPONSE,
	COMBAT_RESOLUTION,
	ROUND_END,
	GAME_OVER,
}
enum MatchResult { NONE, PLAYER_0_WIN, PLAYER_1_WIN, DRAW }
