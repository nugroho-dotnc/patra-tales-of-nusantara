# Base class design

Scope approved in chat: CardDefinition, CardInstance, PlayerState, MatchState,
and supporting enums. Implement directly inside the existing Godot project.

- CardDefinition extends Resource; shared authored data, treated as read-only in a match.
- Runtime classes extend RefCounted and do not depend on scenes.
- PlayerState owns instances by unique instance ID. Ordered zones store IDs;
  bench_slots contains exactly six entries, with an empty string for empty slots.
- MatchState starts in SETUP, round 0, with player IDs 0 and 1. No active priority
  or Panji until a future setup system assigns them (sentinel -1).
- Damage ignores negative amounts and clamps at zero. Healing ignores negative
  amounts, caps at maximum Sukma, and cannot revive a dead unit. Mantra has no HP.
- Class methods are primitives for a future rules engine, not permission to bypass
  combat timing, lethal prevention, or Warisan. No gameplay resolver is implemented.
- No turn advancement, draw, movement, AI, modifier calculation, or location effects
  in this increment. location_id stores the future location reference.
- Definition defaults: Jana, cost 0, Daya 0, Sukma 1, speed NONE. Authored card
  validation will be a separate subsystem.

Relations: MatchState owns two PlayerState objects; each PlayerState owns up to
ten starting CardInstance objects; many instances may reference one CardDefinition.
Public collections are storage for a future rules engine, not self-validating
containers. That engine must preserve zone membership and deck-size invariants.
