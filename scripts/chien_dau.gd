extends Node2D

signal done
signal fell
signal coin(amount: int)
signal knocked_out(total: int)
signal sound(kind: String)

const DATA = preload("res://scripts/noi_dung.gd")
const ARENA := Rect2(52, 178, 852, 480)
const FONT = preload("res://fonts/NotoSans-Regular.ttf")

var school := 0
var realm := 0
var skill_cool := 0.0
var skill_power := 1.0
var velocity := Vector2.ZERO
var active := false
var frozen := false
var pos := Vector2(478, 418)
var facing := Vector2.RIGHT
var life := 100.0
var life_max := 100.0
var stamina := 100.0
var exhausted := false
var dash_cool := 0.0
var dash_time := 0.0
var invincible := 0.0
var monsters: Array[Dictionary] = []
var missiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var coins: Array[Dictionary] = []
var floating: Array[Dictionary] = []
var weapons: Array[Dictionary] = []
var relics: Array[String] = []
var pillars: Array[Vector2] = []
var room_type := 0
var floor_index := 0
var wave := 0
var waves := 0
var wait_wave := 0.0
var kills := 0
var clock := 0.0
var stride := 0.0
var moving := false
var hard := true
var rng := RandomNumberGenerator.new()
var background_rng := RandomNumberGenerator.new()

func enter(room: int, floor_number: int, battle: bool, seed_value: int) -> void:
	room_type = room
	floor_index = floor_number
	rng.seed = seed_value
	pos = Vector2(478, 460)
	velocity = Vector2.ZERO
	dash_cool = 0.0
	dash_time = 0.0
	invincible = 0.0
	stamina = 100.0
	exhausted = false
	facing = Vector2.UP
	for list in [monsters, missiles, effects, coins, floating, pillars]:
		list.clear()
	pillars.append_array([Vector2(258,343),Vector2(697,500)] if room == 1 else [])
	if room == 2:
		pillars.append_array([Vector2(280,505),Vector2(660,322),Vector2(724,535)])
	for i in range(pillars.size()):
		pillars[i] += Vector2(rng.randf_range(-53,53),rng.randf_range(-57,57))
	active = battle
	wave = 0
	waves = 1 if room == 5 else 2
	wait_wave = 0.85
	queue_redraw()

func heal(amount: float) -> void:
	life = minf(life_max, life + amount)

func _physics_process(delta: float) -> void:
	if frozen:
		return
	clock += delta
	invincible = maxf(0, invincible - delta)
	dash_cool = maxf(0, dash_cool - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	skill_cool = maxf(0.0, skill_cool - delta)
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and not exhausted and direction != Vector2.ZERO
	stamina = clampf(stamina + delta * (-36.0 if sprint else 28.0), 0, 100)
	if stamina <= 0.0:
		exhausted = true
	elif stamina >= 25.0:
		exhausted = false
	moving = direction != Vector2.ZERO or dash_time > 0.0
	if moving:
		stride += delta * (20.0 if sprint else 14.0)
	if dash_time > 0.0:
		dash_time -= delta
		move_actor(facing * 840.0 * delta, true)
		if relics.has("vo"):
			for monster in monsters:
				if monster.p.distance_to(pos) < 45 and not monster.get("dash_hit", false):
					monster.dash_hit = true
					hit(monster, 12.0)
	else:
		if direction != Vector2.ZERO:
			facing = direction
		velocity = velocity.move_toward(direction * (326.0 if sprint else 222.0), 1500.0 * delta)
		move_actor(velocity * delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].ttl -= delta
		if effects[i].ttl <= 0:
			effects.remove_at(i)
	for i in range(floating.size() - 1, -1, -1):
		floating[i].ttl -= delta
		floating[i].p.y -= delta * 30
		if floating[i].ttl <= 0:
			floating.remove_at(i)
	for i in range(coins.size() - 1, -1, -1):
		var token := coins[i]
		if pos.distance_to(token.p) < 90:
			token.p = token.p.move_toward(pos, 400.0 * delta)
		if pos.distance_to(token.p) < 17:
			coin.emit(token.amount)
			coins.remove_at(i)
	if active:
		step_battle(delta)
	queue_redraw()

func move_actor(step: Vector2, ignore_pillars := false) -> void:
	var next := boxed(pos + step, 15.0)
	if not ignore_pillars:
		for p in pillars:
			if next.distance_to(p) < 37 and next != p:
				next = p + p.direction_to(next) * 37.0
	pos = boxed(next, 15.0)

func boxed(p: Vector2, margin: float) -> Vector2:
	return p.clamp(ARENA.position + Vector2.ONE * margin, ARENA.end - Vector2.ONE * margin)

func dash() -> void:
	if frozen or dash_cool > 0:
		return
	dash_time = 0.18
	dash_cool = 1.05 if relics.has("dep") else 1.5
	invincible = maxf(invincible, 0.26)
	for monster in monsters:
		monster.dash_hit = false
	effects.append({"kind":"dash","p":pos,"dir":facing,"ttl":0.26,"color":Color("8de1d8")})
	sound.emit("luot")

func step_battle(delta: float) -> void:
	if monsters.is_empty():
		wait_wave -= delta
		if wait_wave <= 0.0:
			if wave == waves:
				finish()
			else:
				spawn_wave()
		return
	for weapon in weapons:
		weapon.timer = maxf(0, weapon.timer - delta)
		if weapon.timer <= 0:
			fire_weapon(weapon)
	for m in monsters:
		if m.hp > 0:
			step_enemy(m, delta)
		if not active:
			return
	for i in range(missiles.size()-1, -1, -1):
		if step_missile(missiles[i], delta):
			missiles.remove_at(i)
		if not active:
			return
	for i in range(monsters.size()-1,-1,-1):
		var m := monsters[i]
		if m.hp <= 0:
			monsters.remove_at(i)
			kills += 1
			knocked_out.emit(kills)
			var reward := (9 if m.kind == "boss" else 1) + int(relics.has("von"))
			coins.append({"p":m.p,"amount":reward})
			effects.append({"kind":"ring","p":m.p,"r":31.0,"ttl":0.34,"color":Color("b56e5f")})
			if relics.has("coi") and kills % 5 == 0:
				heal(3.0)
	if monsters.is_empty():
		wait_wave = 0.72

func finish() -> void:
	active = false
	missiles.clear()
	for token in coins:
		coin.emit(token.amount)
	coins.clear()
	sound.emit("thang")
	done.emit()

func spawn_wave() -> void:
	wave += 1
	var count := (4 + wave + floor_index * 2 + int(room_type == 2)) if hard else (2 + wave + floor_index)
	if room_type == 5:
		count = 1
	for i in range(count):
		var angle := TAU * float(i) / count + rng.randf_range(-0.19,0.19)
		var at := boxed(Vector2(478,418) + Vector2(cos(angle)*330,sin(angle)*188), 38)
		var kind := ["duoi","duoi","ban","huc","duoi"][i % 5] as String
		if i == 0 and room_type == 2:
			kind = "ban"
		if room_type == 5:
			kind = "boss"
			at = Vector2(478,315)
		var hp := (520.0 + floor_index * 215.0 - (0.0 if hard else 155.0)) if kind == "boss" else (26.0 + floor_index*10 + (14.0 if kind == "huc" else 0.0))
		var radius := 38.0 if kind == "boss" else (22.0 if kind == "huc" else 15.0)
		monsters.append({"id":wave*100+i,"kind":kind,"p":at,"hp":hp,"max":hp,"r":radius,"delay":rng.randf_range(0.65,1.35),"warn":0.0,"charge":0.0,"heading":Vector2.ZERO,"cycle":0,"flash":0.0,"slow":0.0,"phase":false})
		effects.append({"kind":"ring","p":at,"r":57.0,"ttl":0.46,"color":Color("ed8a67")})

func fire_weapon(w: Dictionary) -> void:
	var target: Dictionary = {}
	var best := float(w.range)
	for m in monsters:
		var distance: float = pos.distance_to(m.p) - m.r
		if m.hp > 0 and distance < best:
			best = distance
			target = m
	if target.is_empty():
		return
	w.timer = w.period
	var aim := pos.direction_to(target.p)
	if w.id == "loi":
		var previous := pos
		var struck: Array[int] = []
		var current: Dictionary = target
		for chain in range(3):
			if current.is_empty():
				break
			effects.append({"kind":"lightning","p":previous,"end":current.p,"ttl":0.32,"color":Color("b9a6ed")})
			hit(current, w.damage * pow(0.75, chain))
			struck.append(current.id)
			previous = current.p
			current = {}
			var nearest := 155.0
			for candidate in monsters:
				if candidate.hp > 0 and not struck.has(candidate.id) and previous.distance_to(candidate.p) < nearest:
					nearest = previous.distance_to(candidate.p)
					current = candidate
	elif w.id in ["kiem", "luan", "bang"]:
		var color := Color("f3d39c") if w.id == "kiem" else Color("f99d61")
		effects.append({"kind":w.id,"p":pos,"dir":aim,"r":w.range,"ttl":0.28,"color":color})
		for m in monsters:
			if pos.distance_to(m.p) <= w.range + m.r and (w.id in ["luan", "bang"] or aim.dot(pos.direction_to(m.p)) > 0.2):
				hit(m, w.damage)
				if w.id == "bang":
					m.slow = 1.5
	else:
		missiles.append({"p":pos+aim*14,"v":aim * (595.0 if w.id == "cham" else 690.0),"ttl":0.95,"friendly":true,"slow":w.id == "cham","damage":w.damage,"pierce":3 if w.id == "no" else 1,"hit_ids":[],"target":target if w.id == "cham" else {},"color":Color("98e4e6") if w.id == "cham" else Color("ffca78")})

func hit(m: Dictionary, damage: float) -> void:
	if m.hp <= 0:
		return
	m.hp -= damage
	m.flash = 0.1
	if floating.size() < 26:
		floating.append({"p":m.p + Vector2(-8,-22),"ttl":0.52,"text":str(roundi(damage))})

func hurt(damage: float) -> void:
	if invincible > 0 or life <= 0:
		return
	life = maxf(0, life - damage)
	invincible = 0.85
	effects.append({"kind":"ring","p":pos,"r":50.0,"ttl":0.32,"color":Color("f77b68")})
	sound.emit("dau")
	if life <= 0:
		active = false
		fell.emit()

func step_enemy(m: Dictionary, delta: float) -> void:
	m.flash = maxf(0, m.flash - delta)
	var to_player := pos - Vector2(m.p)
	var aim := to_player.normalized()
	var distance := to_player.length()
	m.slow = maxf(0, m.get("slow", 0.0) - delta)
	var speed := (1.0 if hard else 0.83) * (1.0 + floor_index * 0.12) * (0.65 if m.slow > 0 else 1.0)
	if m.kind == "boss" and floor_index == 2 and m.hp < m.max * 0.5:
		speed *= 1.25
		if not m.phase:
			m.phase = true
			m.delay = 0.1
			effects.append({"kind":"ring","p":m.p,"r":160.0,"ttl":0.7,"color":Color("e8a8f2")})
	if m.charge > 0.0:
		m.charge -= delta
		m.p = boxed(m.p + m.heading * (480.0 if m.kind == "boss" else 420.0) * delta, m.r)
	elif m.warn > 0.0:
		m.warn -= delta
		if m.warn <= 0.0:
			if m.kind == "ban":
				for turn in [-0.20,0.0,0.20]:
					fire_enemy(m.p, m.heading.rotated(turn), 177.0 * speed, 9.0)
			elif m.kind == "boss" and m.cycle % 2 == 1:
				for i in range(14 + 4 * floor_index):
					fire_enemy(m.p, m.heading.rotated(TAU*i/(14.0 + 4.0*floor_index)), 206.0*speed, 14.0)
				effects.append({"kind":"ring","p":m.p,"r":87.0,"ttl":0.38,"color":Color("ea8368")})
			else:
				m.charge = 0.49
	elif m.kind == "duoi":
		m.p = boxed(m.p + aim * 103.0 * speed * delta, m.r)
	else:
		m.delay -= delta
		if m.delay <= 0:
			m.cycle += 1
			m.delay = (1.05 if m.phase else 1.55) if m.kind == "boss" else 1.95
			m.heading = aim
			m.warn = 0.52 if m.kind == "boss" else 0.44
		elif m.kind != "ban" or distance > 245:
			var velocity := (75.0 if m.kind == "boss" else 85.0) * speed
			m.p = boxed(m.p + aim * velocity * delta, m.r)
	for other in monsters:
		if other.id == m.id:
			continue
		var sep := Vector2(m.p) - Vector2(other.p)
		if sep.length_squared() > 0.01 and sep.length_squared() < pow(m.r + other.r + 5.0,2):
			m.p = boxed(m.p + sep.normalized() * 97.0 * delta, m.r)
	for p in pillars:
		var offset := Vector2(m.p) - p
		if not offset.is_zero_approx() and offset.length() < m.r + 21.0:
			m.p = boxed(p + offset.normalized() * (m.r + 21.0), m.r)
	if pos.distance_to(m.p) < m.r + 12.0:
		hurt((20.0 if m.kind == "boss" else 11.0) * (1.0 if hard else 0.75))

func fire_enemy(p: Vector2, aim: Vector2, speed: float, damage: float) -> void:
	if relics.has("mat"):
		speed *= 0.78
	missiles.append({"p":p,"v":aim*speed,"ttl":3.0,"friendly":false,"damage":damage,"color":Color("f47a63")})

func step_missile(m: Dictionary, delta: float) -> bool:
	m.ttl -= delta
	if m.friendly and not m.target.is_empty() and m.target.hp > 0.0:
		var speed: float = m.v.length()
		m.v = Vector2(m.v).lerp(Vector2(m.p).direction_to(m.target.p)*speed, minf(1,delta*14)).normalized()*speed
	m.p += m.v * delta
	if m.ttl <= 0.0 or not ARENA.grow(12).has_point(m.p):
		return true
	if m.friendly:
		for enemy in monsters:
			if enemy.hp > 0 and not m.hit_ids.has(enemy.id) and Vector2(m.p).distance_to(enemy.p) < enemy.r+9:
				m.hit_ids.append(enemy.id)
				hit(enemy,m.damage)
				if m.get("slow",false):
					enemy.slow = 1.5
				m.pierce -= 1
				if m.pierce == 0:
					return true
	elif pos.distance_to(m.p) < 15.0:
		hurt(m.damage)
		return true
	return false

func _draw() -> void:
	draw_rect(ARENA.grow(13),Color("0b1116"))
	draw_rect(ARENA.grow(8),Color("273434"), false,1.0)
	draw_rect(ARENA,[Color("152c2b"),Color("242332"),Color("283046")][floor_index])
	background_rng.seed = 4971 + 11*room_type + floor_index
	for y in range(9):
		for x in range(15):
			var corner := ARENA.position + Vector2(x*56.8,y*53.35)
			var tile := Rect2(corner,Vector2(56,52)).intersection(ARENA)
			if tile.has_area():
				var tone := background_rng.randf_range(0.025,0.105)
				draw_rect(tile,Color(0.76,0.53,0.36,tone) if floor_index == 0 else Color(0.34,0.65,0.68,tone))
	for i in range(360):
		var p := ARENA.position + Vector2(background_rng.randf_range(3,842),background_rng.randf_range(3,474))
		var length := background_rng.randf_range(1,13)
		draw_line(p,p+Vector2(length,background_rng.randf_range(-3,3)),Color(0.65,0.55,0.41,background_rng.randf_range(0.04,0.15)),1)
	var center := ARENA.get_center()
	for radius in [91.0,104.0,111.0,194.0]:
		draw_arc(center,radius,0,TAU,96,Color(0.67,0.54,0.37,0.13),1.1,true)
	for i in range(16):
		var d := Vector2.RIGHT.rotated(i*TAU/16)
		draw_line(center+d*89,center+d*114,Color(0.74,0.55,0.33,0.19),1.1)
	for x in [82.0,874.0]:
		for y in [210.0,625.0]:
			draw_lantern(Vector2(x,y))
	# Original vector scenery: bamboo, mountain silhouettes and drifting qi.
	for i in range(17):
		var x := 62.0 + i * 52.0
		if floor_index == 0:
			draw_line(Vector2(x,182),Vector2(x+4,228+sin(i)*14),Color("51736a"),2,true)
			for j in range(3):
				var at := Vector2(x+2,190+j*11)
				draw_line(at,at+Vector2(13,-7),Color("718c72"),2,true)
		elif floor_index == 2:
			draw_colored_polygon(PackedVector2Array([Vector2(x-24,216),Vector2(x+8,180),Vector2(x+43,216)]),Color("3e4860"))
	for i in range(18):
		var mote := Vector2(82+fmod(i*73.0+clock*7,785),220+fmod(i*39.0-clock*8,400))
		draw_circle(mote,1.5,Color(0.65,0.88,0.80,0.2+0.13*sin(clock+i)))
	for p in pillars:
		draw_colored_polygon(PackedVector2Array([p+Vector2(-30,12),p+Vector2(8,-7),p+Vector2(43,20),p+Vector2(-4,35)]),Color(0,0,0,0.34))
		draw_rect(Rect2(p-Vector2(17,35),Vector2(34,56)),Color("171e20"))
		draw_rect(Rect2(p-Vector2(15,34),Vector2(30,51)),Color("5a5450"),false,2)
		draw_rect(Rect2(p-Vector2(13,29),Vector2(26,8)),Color("8b7361"))
	if room_type in [0,3,4]:
		draw_shrine(Vector2(478,321))
	for token in coins:
		draw_circle(token.p,6.0,Color("745035"))
		draw_circle(token.p,4.0,Color("f5bd69"),true,-1,true)
		draw_rect(Rect2(token.p-Vector2(1,1),Vector2(2,2)),Color("71543c"))
	for m in monsters:
		draw_enemy(m)
	for m in missiles:
		var direction := Vector2(m.v).normalized()
		draw_line(m.p-direction*(23 if m.friendly else 11),m.p,m.color,3.0,true)
		draw_circle(m.p,4.5 if m.friendly else 6.0,m.color,true,-1,true)
		draw_circle(m.p,2.0,Color("fff0c7"),true,-1,true)
	for fx in effects:
		var tint: Color = fx.color
		tint.a = minf(1,fx.ttl*3.8)
		match fx.kind:
			"lightning":
				var middle: Vector2 = (Vector2(fx.p)+Vector2(fx.end))*0.5 + Vector2(8,-14)
				draw_polyline(PackedVector2Array([fx.p,middle,fx.end]),tint,3.0,true)
			"kiem":
				var angle := Vector2(fx.dir).angle()
				draw_arc(fx.p,fx.r*0.68,angle-1.15,angle+1.15,36,tint,7.0,true)
				draw_arc(fx.p,fx.r*0.82,angle-0.9,angle+0.9,36,tint,2.0,true)
			"dash":
				for i in range(4):
					var from := Vector2(fx.p)+Vector2(fx.dir).orthogonal()*(i-1.5)*5
					draw_line(from,from+Vector2(fx.dir)*113,tint,1.8,true)
			_:
				draw_arc(fx.p,fx.r*(1.05-fx.ttl),0,TAU,50,tint,2.4,true)
	draw_actor()
	for t in floating:
		draw_string(FONT,t.p,t.text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1.0,0.87,0.64,clampf(t.ttl*3,0,1)))

func draw_lantern(p: Vector2) -> void:
	for radius in [32.0,24.0,14.0]:
		draw_circle(p,radius,Color(0.92,0.48,0.24,0.048))
	draw_line(p+Vector2(0,-14),p+Vector2(0,13),Color("87604b"),2)
	draw_rect(Rect2(p - Vector2(6,7),Vector2(12,13)),Color("c5734f"))
	draw_rect(Rect2(p - Vector2(2,5),Vector2(4,9)),Color("ffd28c"))

func draw_shrine(p: Vector2) -> void:
	draw_ellipse_shadow(p+Vector2(0,13),1.8)
	match room_type:
		0:
			for offset in [-12,0,12]:
				var h := 30+sin(clock*7+offset)*8.0
				draw_colored_polygon(PackedVector2Array([p+Vector2(offset-10,9),p+Vector2(offset+2,-h),p+Vector2(offset+9,9)]),Color("dc8253"))
				draw_line(p+Vector2(offset,8),p+Vector2(offset+4,-h*0.5),Color("fbd38b"),4,true)
			draw_line(p+Vector2(-27,14),p+Vector2(27,14),Color("9b7160"),7)
		3:
			draw_rect(Rect2(p+Vector2(-45,-26),Vector2(90,47)),Color("4c322c"))
			draw_rect(Rect2(p+Vector2(-50,-39),Vector2(100,14)),Color("9c5844"))
			for i in range(3):
				draw_circle(p+Vector2(-27+i*27,-10),7,Color("d2a472"))
		4:
			draw_circle(p,35,Color("354c48"))
			draw_arc(p,39,0,TAU,48,Color("86a697"),2,true)
			draw_set_transform(p,PI/4.0)
			draw_rect(Rect2(-13,-13,26,26),Color("9bbbac"),false,2)
			draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(p: Vector2, scale_factor: float) -> void:
	draw_set_transform(p,0,Vector2(1,0.38)*scale_factor)
	draw_circle(Vector2.ZERO,22.0,Color(0,0,0,0.5),true,-1,true)
	draw_set_transform(Vector2.ZERO)

func draw_enemy(m: Dictionary) -> void:
	var p: Vector2 = m.p
	var r: float = m.r
	var color := Color("915950") if m.kind == "duoi" else Color("705b87")
	if m.kind == "boss":
		color = Color("9f6449") if floor_index == 0 else Color("47786f")
	if m.kind == "huc":
		color = Color("aa764d")
	if m.flash > 0:
		color = Color("f7d4ad")
	draw_ellipse_shadow(p+Vector2(0,r*0.65),r/19)
	if m.warn > 0.0:
		var caution := Color("f17d66")
		if m.kind == "boss" and m.cycle % 2 == 1:
			draw_arc(p,r+40,0,TAU,50,caution,2.0,true)
		else:
			draw_line(p,p + m.heading*(300.0 if m.kind == "boss" else 205.0),Color(0.95,0.35,0.27,0.25),14,true)
			draw_line(p,p + m.heading*(300.0 if m.kind == "boss" else 205.0),caution,1.6,true)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-r,r*0.6),p+Vector2(-r*0.75,-r*0.55),p+Vector2(0,-r),p+Vector2(r*0.72,-r*0.60),p+Vector2(r,r*0.60),p+Vector2(r*0.18,r*0.40),p+Vector2(-r*0.22,r*0.8)]),color)
	draw_line(p+Vector2(-r*0.69,r*0.40),p+Vector2(0,-r*0.66),color.lightened(0.25),2,true)
	draw_line(p+Vector2(0,-r*0.66),p+Vector2(r*0.69,r*0.40),color.darkened(0.38),3,true)
	for side in [-1,1]:
		var eye := p+Vector2(side*r*0.22,-r*0.15)
		draw_circle(eye,maxf(2,r*0.09),Color("ffe2a8"),true,-1,true)
		if m.kind in ["huc","boss"]:
			draw_line(p+Vector2(side*r*0.52,-r*0.46),p+Vector2(side*r*0.96,-r),color.lightened(0.4),maxf(2,r*0.11),true)
	if m.kind == "boss":
		draw_string(FONT,p+Vector2(-100,-r-23),DATA.TRUM[floor_index],HORIZONTAL_ALIGNMENT_CENTER,200,15,Color("e4c698"))
	if m.hp < m.max or m.kind == "boss":
		var bar := Rect2(p.x-r,p.y-r-12,r*2,4)
		draw_rect(bar,Color("1b1517"))
		draw_rect(Rect2(bar.position,Vector2(bar.size.x*maxf(0,m.hp/m.max),4)),Color("dd8266"))

func draw_actor() -> void:
	if invincible > 0 and fmod(clock,0.14) < 0.045:
		return
	draw_ellipse_shadow(pos+Vector2(0,11),0.88)
	var tilt := facing.x*6
	var step := sin(stride)*4.5 if moving else 0.0
	draw_line(pos+Vector2(-6,6),pos+Vector2(-7,15+step),Color("192b2c"),4,true)
	draw_line(pos+Vector2(6,6),pos+Vector2(7,15-step),Color("192b2c"),4,true)
	var cloak := PackedVector2Array([pos+Vector2(-17,13),pos+Vector2(-9,-10),pos+Vector2(tilt,-16),pos+Vector2(11,-9),pos+Vector2(17,11),pos+Vector2(2,8)])
	draw_colored_polygon(cloak,[Color("d7e4d4"),Color("8e80ba"),Color("73b2a5")][school])
	draw_polyline(cloak,Color("80b0a0"),1.3,true)
	draw_line(pos+Vector2(-10,4),pos+Vector2(11,3),Color("d2a471"),2,true)
	# Long hair, topknot and an orbiting spirit sword identify the cultivator.
	draw_line(pos+Vector2(tilt,-18),pos+Vector2(-10-step,5),Color("152224"),5,true)
	draw_circle(pos+Vector2(tilt,-24),3.5,Color("1b292d"),true,-1,true)
	var orbit := Vector2.RIGHT.rotated(clock*0.8)*29
	draw_line(pos+orbit-Vector2(0,12),pos+orbit+Vector2(0,8),Color("d6e9dd"),2,true)
	draw_line(pos+orbit+Vector2(-4,4),pos+orbit+Vector2(4,4),Color("d9ba79"),2,true)
	draw_arc(pos,26.0+realm*2,0,TAU,48,Color(0.52,0.85,0.76,0.22),1,true)
	draw_circle(pos+Vector2(tilt,-13),9,Color("d7c7a0"),true,-1,true)
	draw_line(pos+Vector2(tilt-5,-13),pos+Vector2(tilt+5,-13),Color("253739"),3,true)
	draw_line(pos+Vector2(tilt,-21),pos+Vector2(tilt+7,-19),Color("c8775d"),2.4,true)
	draw_arc(pos,23.0,facing.angle()-0.38,facing.angle()+0.38,10,Color("a2d6cb"),1.35,true)

func use_skill() -> bool:
	if frozen or not active or skill_cool > 0:
		return false
	skill_cool = DATA.MON_PHAI[school].hoi
	sound.emit("thang")
	match school:
		0:
			effects.append({"kind":"ring","p":pos,"r":230.0,"ttl":0.6,"color":Color("ffe2a7")})
			for m in monsters:
				if pos.distance_to(m.p) < 230.0 + m.r:
					hit(m, 56.0 * skill_power)
		1:
			var targets := monsters.filter(func(m): return m.hp > 0)
			targets.sort_custom(func(a,b): return pos.distance_squared_to(a.p) < pos.distance_squared_to(b.p))
			for m in targets.slice(0,5):
				effects.append({"kind":"lightning","p":Vector2(m.p.x,ARENA.position.y),"end":m.p,"ttl":0.55,"color":Color("cebbff")})
				hit(m, 65.0 * skill_power)
		2:
			heal(22.0 + realm*4)
			invincible = maxf(invincible, 2.0)
			effects.append({"kind":"ring","p":pos,"r":120.0,"ttl":0.7,"color":Color("a4efcf")})
	return true
