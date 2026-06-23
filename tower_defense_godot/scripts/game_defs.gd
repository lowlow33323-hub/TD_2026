extends RefCounted

const GRID_W := 45
const GRID_H := 25
const TOWER_SIZE := 2
const START_ROW := 12
const START := Vector2i(0, START_ROW)
const GOAL := Vector2i(GRID_W - 1, START_ROW)
const MAX_TOWER_LEVEL := 5
const FINAL_WAVE := 50

const TYPE_CANNON := "cannon"
const TYPE_ARROW := "arrow"
const TYPE_ICE := "ice"
const ENEMY_BASIC := "basic"
const ENEMY_TANK := "tank"
const ENEMY_FAST := "fast"
const ENEMY_REVIVER := "reviver"
const ENEMY_FLYING := "flying"
const ENEMY_AUDITOR := "auditor"
const DIFFICULTY_EASY := "easy"
const DIFFICULTY_NORMAL := "normal"
const DIFFICULTY_HARD := "hard"
const SCREEN_MENU := "menu"
const SCREEN_RULES := "rules"
const SCREEN_RANKING := "ranking"
const SCREEN_DIFFICULTY := "difficulty"
const SCREEN_GAME := "game"
const GAME_VERSION := "Beta 0.6.8"
