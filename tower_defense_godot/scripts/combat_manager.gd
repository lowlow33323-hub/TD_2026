extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Tower = preload("res://scripts/tower.gd")

const BUSY_VISUAL_LOAD := 130
const MAX_SPLASH_IMPACTS_NORMAL := 3
const MAX_SPLASH_IMPACTS_BUSY := 1


static func update_towers(owner, delta: float) -> void:
	for tower in owner.towers:
		tower.cooldown = max(0.0, tower.cooldown - delta)
		if tower.cooldown > 0.0:
			continue
		var targets := enemies_for_tower(owner, tower)
		if targets.is_empty():
			continue
		var aim_vector: Vector2 = targets[0].pos - owner.tower_center(tower)
		if aim_vector.length_squared() > 0.001:
			tower.aim_dir = aim_vector.normalized()
		for target in targets:
			owner.projectiles.append(Projectile.new(owner.tower_center(tower), target, tower))
		tower.cooldown = tower.fire_rate
		owner.play_tower_sound(tower.type_id)


static func update_projectiles(owner, delta: float) -> void:
	for i in range(owner.projectiles.size() - 1, -1, -1):
		var projectile: Projectile = owner.projectiles[i]
		if not owner.enemies.has(projectile.target):
			owner.projectiles.remove_at(i)
			continue

		var direction: Vector2 = projectile.target.pos - projectile.pos
		var distance: float = direction.length()
		var step: float = projectile.speed * delta
		if distance <= step:
			apply_projectile_hit(owner, projectile)
			owner.projectiles.remove_at(i)
		else:
			projectile.pos += direction.normalized() * step


static func apply_projectile_hit(owner, projectile: Projectile) -> void:
	if not projectile.target.is_targetable():
		return
	if projectile.tower_type == Defs.TYPE_CANNON and projectile.splash_radius > 0.0:
		var center := projectile.target.pos
		var shown_impacts := 0
		var max_splash_impacts := MAX_SPLASH_IMPACTS_BUSY if owner.visual_load() >= BUSY_VISUAL_LOAD else MAX_SPLASH_IMPACTS_NORMAL
		for enemy in owner.enemies:
			if not enemy.is_targetable() or enemy.is_flying:
				continue
			var dist: float = enemy.pos.distance_to(center)
			if dist <= projectile.splash_radius:
				var ratio := 1.0 - clampf(dist / projectile.splash_radius, 0.0, 0.45)
				var damage := adjusted_projectile_damage(projectile, enemy) * ratio
				apply_damage_to_enemy(owner, enemy, damage)
				if enemy == projectile.target or shown_impacts < max_splash_impacts:
					enemy.apply_hit_flash()
					owner.add_impact_wave(enemy.pos, projectile.color, (enemy.pos - projectile.pos).normalized())
					shown_impacts += 1
	else:
		apply_damage_to_enemy(owner, projectile.target, adjusted_projectile_damage(projectile, projectile.target))
		projectile.target.apply_hit_flash()
		owner.add_impact_wave(projectile.target.pos, projectile.color, (projectile.target.pos - projectile.pos).normalized())
		if projectile.tower_type == Defs.TYPE_ICE:
			projectile.target.apply_slow(projectile.slow_factor, projectile.slow_duration)


static func apply_damage_to_enemy(owner, enemy: Enemy, damage: float) -> void:
	if enemy.is_auditor:
		owner.audit_damage_taken += damage
		enemy.hp = enemy.max_hp
	else:
		enemy.hp -= damage


static func adjusted_projectile_damage(projectile: Projectile, enemy: Enemy) -> float:
	var damage := float(projectile.damage)
	if projectile.tower_type == Defs.TYPE_ARROW:
		damage *= enemy.arrow_damage_taken_multiplier
	return damage


static func enemies_for_tower(owner, tower: Tower) -> Array[Enemy]:
	var origin: Vector2 = owner.tower_center(tower)
	var candidates: Array[Enemy] = []
	for enemy in owner.enemies:
		if not enemy.is_targetable():
			continue
		if tower.type_id == Defs.TYPE_CANNON and enemy.is_flying:
			continue
		if origin.distance_to(enemy.pos) <= tower.range:
			candidates.append(enemy)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.index > b.index
	)

	var result: Array[Enemy] = []
	var count: int = min(tower.target_count, candidates.size())
	for i in range(count):
		result.append(candidates[i])
	return result
