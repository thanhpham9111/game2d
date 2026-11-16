extends SceneTree

const GAME = preload("res://scripts/tro_choi.gd")
const STORAGE = preload("res://scripts/luu_tru.gd")
var g: Node2D
var checks := 0
var failures := 0
var original_save := ""
var original_options := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + name)

func settle_realm() -> void:
	while g.pending_breakthroughs > 0:
		g.pick_breakthrough(0)

func run() -> void:
	if FileAccess.file_exists(STORAGE.PATH):
		original_save = FileAccess.get_file_as_string(STORAGE.PATH)
	if FileAccess.file_exists(GAME.SAVE):
		original_options = FileAccess.get_file_as_string(GAME.SAVE)
	g = GAME.new()
	root.add_child(g)
	await process_frame
	g.muted = true
	g.battle.set_physics_process(false)
	check(g.screen == "title", "Title opens")
	for school in range(3):
		g.start_school(school, true)
		check(g.battle.school == school and g.battle.weapons.size() == 1, "School starter loadout %d" % school)
		check(not STORAGE.read_run().is_empty(), "Initial checkpoint %d" % school)
		g.enter_room(1)
		g.battle.spawn_wave()
		check(g.battle.monsters.size() == 5, "First wave count")
		check(g.battle.use_skill(), "Skill activates %d" % school)
		check(not g.battle.use_skill(), "Skill cooldown %d" % school)
		var before: float = g.battle.life
		g.battle.dash()
		g.battle.hurt(30)
		check(g.battle.life == before, "Dash invulnerability")
		g.battle.invincible = 0
		g.battle.hurt(10)
		check(g.battle.life < before, "Damage outside invulnerability")
	g.start_school(0, false)
	var base: float = g.DATA.DO.kiem.sat
	check(is_equal_approx(g.weapon_mod(0).damage, base*1.35), "Adjacent damage multiplier")
	g.items[1] = {}
	g.items[4] = g.new_item("an")
	check(is_equal_approx(g.weapon_mod(0).damage, base), "Diagonal support excluded")
	g.items[1] = g.new_item("kiem")
	g.slot_pressed(0)
	g.slot_pressed(1)
	check(g.items[0].is_empty() and g.items[1].lv == 2, "Merge matching gear")
	g.items[0] = g.new_item("loi")
	g.items[1] = g.new_item("phu")
	check(g.weapon_mod(0).period < g.DATA.DO.loi.nhip, "Adjacent haste")
	g.save_run()
	var saved := STORAGE.read_run()
	check(not saved.is_empty(), "Save readback")
	var bad := saved.duplicate(true)
	bad.items[0].id = "unknown"
	check(not STORAGE.valid(bad), "Reject unknown gear")
	bad = saved.duplicate(true)
	bad.depth = 9
	check(not STORAGE.valid(bad), "Reject invalid floor")
	bad = saved.duplicate(true)
	bad.realm = 4
	check(not STORAGE.valid(bad), "Reject inconsistent cultivation")
	g.coins = 999
	g.resume_run()
	check(g.coins == saved.coins and g.items[0].id == "loi", "Restore exact checkpoint")
	g.enter_room(1)
	g.battle.spawn_wave()
	g.battle.pos = Vector2(400,400)
	for i in range(g.battle.monsters.size()):
		g.battle.monsters[i].p = Vector2(450+i*28,400)
	g.battle.fire_weapon(g.weapon_mod(0))
	var hit_count := 0
	for m in g.battle.monsters:
		if m.hp < m.max:
			hit_count += 1
	check(hit_count == 3, "Lightning chains to three targets")
	g.items[0] = g.new_item("bang")
	g.battle.fire_weapon(g.weapon_mod(0))
	check(g.battle.monsters[0].slow > 0, "Frost slows")
	# A full campaign goes through the actual wave/death/room-clear state machine.
	g.start_school(0, true)
	for floor_id in range(3):
		check(g.depth == floor_id, "Campaign floor %d" % floor_id)
		for room_id in [1,2,5]:
			g.enter_room(room_id)
			var safety := 0
			while g.battle.active and safety < 12:
				if g.battle.monsters.is_empty():
					g.battle.step_battle(1.0)
				else:
					for m in g.battle.monsters:
						g.battle.hit(m, 100000)
					g.battle.step_battle(0.016)
				safety += 1
			check(not g.battle.active and g.notes.has(room_id), "Clear room %d/%d" % [floor_id,room_id])
			settle_realm()
			if g.has_claim:
				g.pick_reward("")
		if floor_id < 2:
			check(g.screen == "descent", "Descent screen")
			g.descend()
	check(g.screen == "end", "Campaign victory")
	check(g.realm == 4, "Reach Hoa Than")
	check(STORAGE.read_run().is_empty(), "Victory removes checkpoint")
	# A pause freezes cooldowns and motion through the normal game flag.
	g.start_school(2, false)
	g.enter_room(1)
	g.battle.skill_cool = 5
	g.show_pause()
	var pos: Vector2 = g.battle.pos
	g.battle._physics_process(1)
	check(g.battle.skill_cool == 5 and g.battle.pos == pos, "Pause freezes battle")
	g.close_overlay()
	g.battle.invincible = 0
	g.battle.hurt(100000)
	check(g.screen == "end" and STORAGE.read_run().is_empty(), "Defeat clears checkpoint")
	if not original_save.is_empty():
		var f := FileAccess.open(STORAGE.PATH,FileAccess.WRITE)
		f.store_string(original_save)
		f.close()
	else:
		STORAGE.clear_run()
	if not original_options.is_empty():
		var f := FileAccess.open(GAME.SAVE,FileAccess.WRITE)
		f.store_string(original_options)
		f.close()
	elif FileAccess.file_exists(GAME.SAVE):
		DirAccess.remove_absolute(GAME.SAVE)
	print("RESULT: %d/%d checks passed" % [checks-failures, checks])
	g.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
