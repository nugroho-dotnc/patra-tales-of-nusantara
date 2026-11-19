# Base Classes Implementation Plan

**Goal:** Implement the four base classes approved in chat in the existing project.
**Architecture:** Resource definitions, RefCounted match state, shared GameEnums.
**Tech Stack:** Godot 4, GDScript; dependency-free headless tests.
**Spec:** ../../base-class-design.md
**Execution:** Direct implementation in this chat, as requested by the user.

## Constraints
- Existing menu scene and project settings remain intact.
- No Git repository exists; no worktree or commits are available.
- No gameplay rules beyond base state primitives in this increment.

## Tasks
- [x] Add a headless test runner that first fails for missing domain scripts.
- [x] Add scripts/domain/game_enums.gd, card_definition.gd, card_instance.gd,
  player_state.gd, match_state.gd matching the approved diagram.
- [x] Verify instance independence, damage/heal boundaries, spell HP exclusion,
  round flag resets, empty/full zones, independent matches and invalid lookups.
- [x] Import the project headlessly, run all tests, and document usage.

## Verification record
- Godot 4.7.2 stable (local user-provided archive).
- RED: runner exited 1, five missing domain scripts reported.
- GREEN: 26 checks, zero failures, exit 0.
- Sandbox runtime uses a workspace-local APPDATA directory; local portable
  engine uses `_sc_`. No project setting changes were required.
- Manual review: only base data/primitives added; UI and future rules excluded.

## Review focus
Shared definition mutation; negative damage/heal; unintended resurrection;
Mantra interpreted as dead unit; shared collections between players/matches.
