extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")


static func difficulty_name(difficulty_id: String) -> String:
	match difficulty_id:
		Defs.DIFFICULTY_EASY:
			return "簡單"
		Defs.DIFFICULTY_HARD:
			return "困難"
	return "普通"


static func starting_gold(difficulty_id: String) -> int:
	match difficulty_id:
		Defs.DIFFICULTY_EASY:
			return 210
		Defs.DIFFICULTY_HARD:
			return 135
	return 150


static func starting_lives(difficulty_id: String) -> int:
	match difficulty_id:
		Defs.DIFFICULTY_EASY:
			return 18
		Defs.DIFFICULTY_HARD:
			return 8
	return 12


static func enemy_hp_multiplier(difficulty_id: String) -> float:
	match difficulty_id:
		Defs.DIFFICULTY_EASY:
			return 0.98
		Defs.DIFFICULTY_HARD:
			return 1.38
	return 1.18


static func enemy_speed_multiplier(difficulty_id: String) -> float:
	match difficulty_id:
		Defs.DIFFICULTY_EASY:
			return 0.98
		Defs.DIFFICULTY_HARD:
			return 1.18
	return 1.10


static func reward_multiplier(difficulty_id: String) -> float:
	match difficulty_id:
		Defs.DIFFICULTY_HARD:
			return 1.10
	return 1.0


static func reward_for_enemy(base_reward: int, difficulty_id: String) -> int:
	return max(1, int(round(float(base_reward) * reward_multiplier(difficulty_id))))


static func tower_refund_multiplier(difficulty_id: String) -> float:
	match difficulty_id:
		Defs.DIFFICULTY_EASY:
			return 1.0
		Defs.DIFFICULTY_HARD:
			return 0.5
	return 0.7


static func tower_refund(cost: int, difficulty_id: String) -> int:
	return max(0, int(round(float(cost) * tower_refund_multiplier(difficulty_id))))


static func start_wave(owner) -> void:
	if owner.is_wave_active():
		return
	if owner.wave >= Defs.FINAL_WAVE:
		owner.show_message("已完成第 %d 關，遊戲勝利！" % Defs.FINAL_WAVE)
		return
	owner.wave += 1
	owner.boss_to_spawn = is_boss_wave(owner.wave)
	if owner.boss_to_spawn:
		owner.enemies_to_spawn = 0
	else:
		owner.enemies_to_spawn = enemy_count_for_wave(owner.wave)
	owner.enemies_spawned_this_wave = 0
	owner.spawn_timer = 0.0
	owner.next_wave_wait = 1.0
	owner.waiting_next_wave = false
	owner.wave_button.disabled = true
	owner.spawn_flash_timer = 1.2
	owner.wave_banner_timer = 1.8
	owner.wave_audio.play()
	owner.show_message(start_message(owner.wave, owner.boss_to_spawn))


static func update_spawn(owner, delta: float) -> void:
	if owner.enemies_to_spawn <= 0 and not owner.boss_to_spawn:
		if owner.enemies.is_empty():
			if owner.wave >= Defs.FINAL_WAVE and not owner.game_won:
				owner.start_damage_audit()
				return
			if owner.wave > 0:
				if not owner.waiting_next_wave:
					owner.waiting_next_wave = true
					owner.wave_button.disabled = false
					if owner.auto_start_enabled:
						start_wave(owner)
						return
					owner.next_wave_wait = 180.0
				else:
					owner.next_wave_wait -= delta
					if owner.next_wave_wait <= 0.0:
						start_wave(owner)
						return
		return

	owner.spawn_timer -= delta
	if owner.spawn_timer > 0.0:
		return

	if owner.boss_to_spawn:
		owner.spawn_enemy(true, Defs.ENEMY_BASIC)
		owner.boss_to_spawn = false
		owner.spawn_timer = boss_spawn_delay()
	elif owner.enemies_to_spawn > 0:
		var batch_size: int = min(spawn_batch_size(owner.wave), owner.enemies_to_spawn)
		for i in range(batch_size):
			var enemy_type := enemy_type_for_spawn(owner.wave, owner.enemies_spawned_this_wave)
			owner.spawn_enemy(false, enemy_type)
			owner.enemies_to_spawn -= 1
			owner.enemies_spawned_this_wave += 1
			if enemy_type == Defs.ENEMY_FLYING:
				break
		owner.spawn_timer = spawn_interval(owner.wave)


static func is_boss_wave(wave: int) -> bool:
	return wave % 10 == 0


static func enemy_count_for_wave(wave: int) -> int:
	var count := 8 + wave * 3
	if wave > 40:
		count = int(ceil(float(count) * 2.4))
	elif wave > 30:
		count = int(ceil(float(count) * 1.5))
	elif wave > 20:
		count = int(ceil(float(count) * 1.2))
	return count


static func spawn_batch_size(wave: int) -> int:
	if wave > 30:
		return 5
	if wave > 20:
		return 2
	return 1


static func start_message(wave: int, is_boss: bool) -> String:
	if is_boss:
		return "第 %d 波 Boss 關開始：只有一隻巨大敵人，擊倒會記錄時間！" % wave
	return "第 %d 波開始。" % wave


static func boss_spawn_delay() -> float:
	return 1.1


static func spawn_interval(wave: int) -> float:
	return max(0.35, 0.95 - wave * 0.025)


static func enemy_type_for_spawn(wave: int, spawn_index: int) -> String:
	if wave > 40:
		if spawn_index % 14 == 5:
			return Defs.ENEMY_FLYING
		if spawn_index % 5 == 2:
			return Defs.ENEMY_REVIVER
		if spawn_index % 3 == 0:
			return Defs.ENEMY_TANK
		if spawn_index % 3 == 1:
			return Defs.ENEMY_FAST
		return Defs.ENEMY_BASIC
	if wave >= 30:
		if spawn_index % 7 == 5:
			return Defs.ENEMY_FLYING
		if spawn_index % 5 == 2:
			return Defs.ENEMY_REVIVER
	if wave >= 20:
		if spawn_index % 5 == 2:
			return Defs.ENEMY_REVIVER
	if wave < 3:
		return Defs.ENEMY_BASIC
	if wave < 5:
		if spawn_index % 4 == 3:
			return Defs.ENEMY_FAST
		return Defs.ENEMY_BASIC
	if wave < 8:
		if spawn_index % 5 == 4:
			return Defs.ENEMY_TANK
		if spawn_index % 4 == 2:
			return Defs.ENEMY_FAST
		return Defs.ENEMY_BASIC
	if wave < 12:
		if spawn_index % 4 == 0:
			return Defs.ENEMY_TANK
		if spawn_index % 3 == 1:
			return Defs.ENEMY_FAST
		return Defs.ENEMY_BASIC
	if spawn_index % 3 == 0:
		return Defs.ENEMY_TANK
	if spawn_index % 3 == 1:
		return Defs.ENEMY_FAST
	return Defs.ENEMY_BASIC
