extends Node2D

const DATA = preload("res://scripts/noi_dung.gd")
const STORAGE = preload("res://scripts/luu_tru.gd")
const COMBAT = preload("res://scripts/chien_dau.gd")
const BODY = preload("res://fonts/NotoSans-Regular.ttf")
const TITLE = preload("res://fonts/NotoSerifDisplay-Bold.ttf")
const CREAM := Color("f5e6c8")
const MUTED := Color("a3ada5")
const GOLD := Color("e4b885")
const GREEN := Color("a8dac2")
const RED := Color("e3816f")
const BORDER := Color("3a4b47")
const BG := Color("111b20")
const SAVE := "user://ky_luc.cfg"

var school := 0
var realm := 0
var cultivation := 0
var pending_breakthroughs := 0
var power_bonus := 0.0
var haste_bonus := 0.0
var kills_at_entry := 0
var elapsed_before := 0
var skill_label: Label
var cultivation_label: Label
var after_breakthrough := "reward"
var battle = COMBAT.new()
var ui := Control.new()
var overlay: Control
var hp_label: Label
var status: Label
var prompt_label: Label
var info: Label
var relic_label: Label
var rank: Label
var life_bar: ProgressBar
var stamina_bar: ProgressBar
var dash_bar: ProgressBar
var move_button: Button
var slot_buttons: Array[Button] = []
var items: Array[Dictionary] = []
var relics: Array[String] = []
var heard: Dictionary = {}
var notes: Dictionary = {}
var rng := RandomNumberGenerator.new()
var screen := "title"
var coins := 0
var depth := 0
var room := 0
var open_slots := 4
var focused_slot := -1
var incoming := ""
var discard_button: Button
var pending_rewards: Array[String] = []
var has_claim := false
var altar_used := false
var difficulty := true
var muted := false
var help_from_title := false
var game_start := 0
var recorded := 0
var sfx := AudioStreamPlayer.new()
var tones: Dictionary = {}
var msg := ""
var msg_until := 0
var room_seeds: Array[int] = []

func _ready() -> void:
	rng.randomize()
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.15)
	var key_sets := [[KEY_A,KEY_LEFT],[KEY_D,KEY_RIGHT],[KEY_W,KEY_UP],[KEY_S,KEY_DOWN]]
	for i in range(4):
		for key in key_sets[i]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(["move_left","move_right","move_up","move_down"][i],ev)
	add_child(battle)
	add_child(ui)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sfx)
	sfx.volume_db = -13
	battle.done.connect(room_cleared)
	battle.fell.connect(func(): show_end(false))
	battle.coin.connect(add_coins)
	battle.sound.connect(play_sound)
	make_tones()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		recorded = int(cfg.get_value("ky_luc","ha_guc",0))
		muted = bool(cfg.get_value("tuy_chon","im_lang",false))
	build_ui()
	battle.enter(0,0,false,rng.randi())
	show_title()

func rect_for(parent: Node, box: Rect2, panel_color: Color, outline: Color = BORDER, radius := 9) -> Panel:
	var p := Panel.new()
	p.position = box.position
	p.size = box.size
	p.add_theme_stylebox_override("panel",style(panel_color,outline,radius))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func style(color: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 9
	s.content_margin_right = 9
	return s

func label(parent: Node, at: Vector2, width: float, value: String, points: int, tint := CREAM, serif := false) -> Label:
	var l := Label.new()
	l.position = at
	l.size.x = width
	l.text = value
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",TITLE if serif else BODY)
	l.add_theme_font_size_override("font_size",points)
	l.add_theme_color_override("font_color",tint)
	parent.add_child(l)
	return l

func button(parent: Node, box: Rect2, value: String, action: Callable, primary := false, points := 16) -> Button:
	var b := Button.new()
	b.position = box.position
	b.size = box.size
	b.text = value
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font",BODY)
	b.add_theme_font_size_override("font_size",points)
	b.add_theme_color_override("font_color",CREAM)
	b.add_theme_color_override("font_disabled_color",Color("707a76"))
	b.add_theme_stylebox_override("normal",style(Color("335c50") if primary else Color("1b2a2e"),Color("679a83") if primary else BORDER,8))
	b.add_theme_stylebox_override("hover",style(Color("457361") if primary else Color("31433f"),Color("93b19e"),8))
	b.add_theme_stylebox_override("pressed",style(Color("142522"),GREEN,8))
	b.add_theme_stylebox_override("disabled",style(Color("141f22"),Color("283431"),8))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func bar(parent: Node, at: Vector2, width: float, tint: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.position = at
	b.size = Vector2(width,7)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("background",style(Color("253135"),Color("253135"),4))
	b.add_theme_stylebox_override("fill",style(tint,tint,4))
	parent.add_child(b)
	return b

func build_ui() -> void:
	label(ui,Vector2(43,19),500,"HUYỀN MÔN",36,CREAM,true)
	label(ui,Vector2(47,69),500,"TIÊN LỘ · BẢN CHƠI THỬ 0.2",14,GOLD)
	rank = label(ui,Vector2(703,36),530,"",17,MUTED)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cultivation_label = label(ui,Vector2(480,75),754,"",13,GREEN)
	cultivation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rect_for(ui,Rect2(40,106,876,53),BG)
	hp_label = label(ui,Vector2(57,111),195,"",14,CREAM)
	life_bar = bar(ui,Vector2(57,137),191,RED)
	label(ui,Vector2(269,111),125,"Thể lực",14,MUTED)
	stamina_bar = bar(ui,Vector2(269,137),118,GREEN)
	label(ui,Vector2(407,111),100,"Lướt",14,MUTED)
	dash_bar = bar(ui,Vector2(407,137),101,Color("8ab5c0"))
	status = label(ui,Vector2(524,117),371,"",14,GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rect_for(ui,Rect2(936,106,304,568),BG)
	label(ui,Vector2(956,121),257,"Hồn trận",25,CREAM,true)
	label(ui,Vector2(958,159),270,"Chọn hai ô để đổi chỗ hoặc ghép.",13,MUTED)
	for i in range(6):
		var b := button(ui,Rect2(954 + (i%3)*90,191 + floori(float(i)/3.0)*69,85,61),"",slot_pressed.bind(i),false,12)
		slot_buttons.append(b)
	info = label(ui,Vector2(956,342),263,"",14,CREAM)
	info.autowrap_mode = 2
	skill_label = label(ui,Vector2(956,531),267,"",12,GREEN)
	label(ui,Vector2(956,430),255,"Linh bảo mang theo",21,CREAM,true)
	relic_label = label(ui,Vector2(956,469),251,"",14,MUTED)
	relic_label.autowrap_mode = 2
	discard_button = button(ui,Rect2(954,558,268,34),"Bỏ vật phẩm đang nhận",discard_item,false,13)
	discard_button.hide()
	move_button = button(ui,Rect2(954,606,268,45),"Bản đồ · M",show_map,true)
	rect_for(ui,Rect2(40,690,1200,43),BG)
	prompt_label = label(ui,Vector2(55,701),930,"",14,MUTED)
	button(ui,Rect2(1000,696,90,30),"Luật chơi",show_help,false,13)
	button(ui,Rect2(1099,696,123,30),"Tạm dừng",show_pause,false,13)

func set_overlay(which: String, title: String, detail: String, wide := false) -> Control:
	if is_instance_valid(overlay):
		overlay.hide()
		overlay.queue_free()
	overlay = Control.new()
	overlay.size = Vector2(1280,760)
	ui.add_child(overlay)
	var dim := ColorRect.new()
	dim.size = Vector2(1280,760)
	dim.color = Color(0.018,0.028,0.038,0.80)
	overlay.add_child(dim)
	var bounds := Rect2(262,86,756,588) if wide else Rect2(331,115,618,530)
	rect_for(overlay,bounds,Color("101b20"),Color("696156"),13)
	rect_for(overlay,Rect2(bounds.position+Vector2(13,13),bounds.size-Vector2(26,26)),Color(0,0,0,0),Color("2e413e"),8)
	var mat := Control.new()
	mat.position = bounds.position
	mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(mat)
	label(mat,Vector2(33,25),bounds.size.x-66,title,38,CREAM,true)
	var sub := label(mat,Vector2(35,86),bounds.size.x-70,detail,16,MUTED)
	sub.autowrap_mode = 2
	screen = which
	battle.frozen = true
	return mat

func close_overlay() -> void:
	if is_instance_valid(overlay):
		overlay.hide()
		overlay.queue_free()
	overlay = null
	screen = "play"
	battle.frozen = false
	refresh()

func show_title() -> void:
	var mat := set_overlay("title","Huyền Môn · Tiên Lộ","Linh mạch vỡ, ba bí cảnh chìm trong yêu khí. Chọn tông môn để bắt đầu chuyến mới, kết pháp trận và vượt Đài Độ Kiếp.",true)
	for i in range(DATA.MON_PHAI.size()):
		var row: Dictionary = DATA.MON_PHAI[i]
		var y := 140 + i * 90
		button(mat,Rect2(35,y,686,49),row.ten + "   ·   " + str(int(row.mau)) + " sinh lực",start_school.bind(i,true),i == 0)
		label(mat,Vector2(44,y+52),670,row.mo,13,MUTED)
	button(mat,Rect2(35,420,336,43),"Tập sự · Thanh Vân Kiếm Tông",start_school.bind(0,false))
	var continued := button(mat,Rect2(385,420,336,43),"Tiếp tục chuyến đang lưu",resume_run,true)
	continued.disabled = STORAGE.read_run().is_empty()
	button(mat,Rect2(35,478,336,40),"Cách chơi",show_help)
	button(mat,Rect2(385,478,336,40),"Thoát trò chơi",func(): get_tree().quit())
	label(mat,Vector2(35,540),670,"3 tông môn · 3 bí cảnh · 5 cảnh giới   |   Kỷ lục: %d yêu vật" % recorded,13,GOLD)

func start(ash: bool, standard: bool) -> void:
	start_school(0 if ash else 2, standard)

func start_school(selected: int, standard: bool) -> void:
	school = selected
	realm = 0
	cultivation = 0
	pending_breakthroughs = 0
	power_bonus = 0
	haste_bonus = 0
	elapsed_before = 0
	items.clear()
	for i in range(6):
		items.append({})
	items[0] = new_item(DATA.MON_PHAI[school].vu_khi)
	items[1] = new_item(DATA.MON_PHAI[school].ho_tro)
	relics.clear()
	depth = 0
	coins = 5
	open_slots = 4
	focused_slot = -1
	incoming = ""
	has_claim = false
	difficulty = standard
	battle.hard = standard
	battle.school = school
	battle.realm = realm
	battle.skill_cool = 0
	battle.relics = relics
	battle.life_max = DATA.MON_PHAI[school].mau
	battle.life = battle.life_max
	battle.kills = 0
	game_start = Time.get_ticks_msec()
	close_overlay()
	next_floor()
	play_sound("thang")

func next_floor() -> void:
	room_seeds.clear()
	for i in range(6):
		room_seeds.append(rng.randi())
	heard = {0:true}
	notes = {0:true}
	altar_used = false
	has_claim = false
	pending_rewards.clear()
	battle.heal(22.0 if depth > 0 else 0.0)
	enter_room(0)
	announce("Chọn một lối xuống trên bản đồ.")

func enter_room(n: int) -> void:
	if n in [1,2,5] and not notes.has(n) and battle.weapons.is_empty():
		close_overlay()
		announce("Đặt ít nhất một vũ khí vào hồn trận trước khi vào phòng chiến đấu.")
		return
	room = n
	kills_at_entry = battle.kills
	heard[room] = true
	if room in [0,3,4]:
		notes[room] = true
	focused_slot = -1
	incoming = ""
	battle.enter(room,depth,room in [1,2,5] and not notes.has(room),room_seeds[room])
	rebuild_weapons()
	close_overlay()
	announce("Đã đến %s." % DATA.DIA_DIEM[room])
	save_run(true)

func refresh() -> void:
	if items.size() != 6:
		return
	for i in range(6):
		var b := slot_buttons[i]
		var item := items[i]
		b.disabled = not is_open(i) or battle.active
		var text := "Chưa mở" if not is_open(i) else "Ô trống"
		if not item.is_empty():
			text = "%s\nBậc %d" % [DATA.TEN_NGAN[item.id],item.lv]
		b.text = text
		b.tooltip_text = item_desc(i)
		b.add_theme_color_override("font_color",GREEN if i == focused_slot else CREAM)
		b.add_theme_color_override("font_disabled_color",CREAM if is_open(i) else Color("7d8b85"))
		b.add_theme_stylebox_override("normal",style(Color("294941") if i == focused_slot else (Color("223736") if not item.is_empty() else Color("152428")),GREEN if i == focused_slot else BORDER,8))
		b.add_theme_stylebox_override("disabled",style(Color("202e31") if is_open(i) else Color("141e22"),Color("30413d"),8))
	if not incoming.is_empty():
		info.text = "Đang nhận %s. Chọn một ô để đặt vào hoặc đổi món." % DATA.DO[incoming].ten
	elif focused_slot >= 0:
		info.text = item_desc(focused_slot)
	else:
		info.text = "Pháp khí tác động lên vũ khí ở ô chung cạnh." if not battle.active else "Có thể xếp lại hồn trận sau khi dọn phòng."
	var names := PackedStringArray()
	for id in relics:
		names.append(DATA.DI_VAT[id][0])
	relic_label.text = "Chưa có linh bảo." if names.is_empty() else " · ".join(names)
	discard_button.visible = not incoming.is_empty()
	move_button.disabled = battle.active
	move_button.text = "Nhận chiến lợi phẩm · E" if has_claim else "Bản đồ · M"

func item_desc(i: int) -> String:
	if not is_open(i):
		return "Có thể mở ô này ở Linh Bảo Các."
	var item := items[i]
	if item.is_empty():
		return "Ô trống. Chọn thêm một ô để chuyển vật phẩm."
	var row: Dictionary = DATA.DO[item.id]
	if row.loai == "Hỗ trợ":
		return "%s · %s\n%s" % [row.ten,row.loai,row.mo]
	var stats := weapon_mod(i)
	return "%s · %s\n%d sát thương · %.2f giây mỗi đòn\n%s" % [row.ten,row.loai,roundi(stats.damage),stats.period,row.mo]

func is_open(i: int) -> bool:
	return DATA.MO_O.find(i) < open_slots

func new_item(id: String) -> Dictionary:
	return {"id":id,"lv":1}

func slot_pressed(i: int) -> void:
	if battle.active or not is_open(i):
		return
	if not incoming.is_empty():
		var same: bool = items[i].get("id","") == incoming and items[i].get("lv",0) == 1
		if same:
			items[i].lv = 2
			announce("Đã ghép thành %s bậc 2." % DATA.DO[incoming].ten)
		else:
			var drops_last_weapon: bool = battle.weapons.size() == 1 and not items[i].is_empty() and DATA.DO[items[i].id].loai != "Hỗ trợ"
			if drops_last_weapon and DATA.DO[incoming].loai == "Hỗ trợ":
				announce("Hãy giữ ít nhất một vũ khí trong hồn trận.")
				return
			items[i] = new_item(incoming)
			announce("Đã đặt %s vào hồn trận." % DATA.DO[incoming].ten)
		incoming = ""
		focused_slot = -1
	elif focused_slot == i:
		focused_slot = -1
	elif focused_slot < 0:
		focused_slot = i
	else:
		var first := items[focused_slot]
		var second := items[i]
		if not first.is_empty() and not second.is_empty() and first.id == second.id and first.lv == second.lv and first.lv < 4:
			second.lv += 1
			items[focused_slot] = {}
			announce("Đã ghép thành %s bậc %d." % [DATA.DO[second.id].ten,second.lv])
		else:
			items[focused_slot] = second
			items[i] = first
		focused_slot = -1
	rebuild_weapons()
	refresh()
	save_run()

func weapon_mod(i: int) -> Dictionary:
	var item := items[i]
	var row: Dictionary = DATA.DO[item.id]
	var damage: float = row.sat * (1.0 + 0.65 * (item.lv - 1.0))
	var period: float = row.nhip
	var reach: float = row.tam
	for adj in DATA.O_LIEN_KE[i]:
		var support := items[adj]
		if support.is_empty():
			continue
		match support.id:
			"an": damage *= 1.0 + 0.35 * support.lv
			"phu": period /= 1.0 + 0.18 * support.lv
			"ngoc": reach *= 1.0 + 0.28 * support.lv
	damage *= 1.0 + realm * 0.08 + power_bonus
	period /= 1.0 + haste_bonus
	return {"id":item.id,"damage":damage,"period":maxf(0.16,period),"range":reach,"timer":0.12}

func rebuild_weapons() -> void:
	battle.realm = realm
	battle.skill_power = 1.0 + realm * 0.08 + power_bonus
	battle.weapons.clear()
	for i in range(items.size()):
		if not items[i].is_empty() and DATA.DO[items[i].id].loai != "Hỗ trợ":
			battle.weapons.append(weapon_mod(i))

func equip(id: String) -> void:
	for i in range(6):
		if is_open(i) and items[i].is_empty():
			items[i] = new_item(id)
			focused_slot = -1
			announce("Đã nhận %s." % DATA.DO[id].ten)
			rebuild_weapons()
			refresh()
			save_run()
			return
	incoming = id
	focused_slot = -1
	announce("Hồn trận đã đầy. Chọn một ô để đặt vật phẩm mới.")
	refresh()

func discard_item() -> void:
	incoming = ""
	announce("Đã bỏ vật phẩm đang nhận.")
	refresh()
	save_run()

func add_coins(amount: int) -> void:
	coins += amount

func room_cleared() -> void:
	notes[room] = true
	battle.heal(10.0 if difficulty else 18.0)
	cultivation += battle.kills - kills_at_entry + (10 if room == 5 else 0)
	while realm < DATA.CANH_GIOI.size()-1 and cultivation >= DATA.MOC_TU_VI[realm+1]:
		realm += 1
		pending_breakthroughs += 1
	rebuild_weapons()
	after_breakthrough = "end" if room == 5 and depth == DATA.TANG.size()-1 else ("descent" if room == 5 else "reward")
	if room != 5:
		has_claim = true
		pending_rewards.clear()
		var pool: Array = DATA.DO.keys()
		for i in range(2):
			pending_rewards.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	save_run()
	continue_after_battle()

func continue_after_battle() -> void:
	if pending_breakthroughs > 0:
		show_breakthrough()
	elif after_breakthrough == "end":
		show_end(true)
	elif after_breakthrough == "descent":
		show_descent()
	else:
		close_overlay()
		announce("Bí cảnh đã yên. Nhấn E để nhận chiến lợi phẩm.")

func show_breakthrough() -> void:
	var mat := set_overlay("breakthrough","Đột phá · " + DATA.CANH_GIOI[realm],"Tu vi đã đủ. Chọn một đạo pháp để củng cố căn cơ trong chuyến này.")
	var choices := [["Kiếm ý · Thêm 15% sát thương","Tăng sức mạnh vũ khí và tuyệt kỹ gây sát thương."],["Thần tốc · Thêm 15% tốc đánh","Tăng tốc độ kích hoạt mọi vũ khí trong pháp trận."],["Trường sinh · Thêm 25 sinh lực","Tăng giới hạn sinh lực và hồi ngay 25 điểm."]]
	for i in range(choices.size()):
		button(mat,Rect2(35,155+i*100,548,49),choices[i][0],pick_breakthrough.bind(i),true)
		label(mat,Vector2(42,208+i*100),530,choices[i][1],13,MUTED)

func pick_breakthrough(choice: int) -> void:
	if pending_breakthroughs <= 0 or screen != "breakthrough":
		return
	match choice:
		0: power_bonus += 0.15
		1: haste_bonus += 0.15
		2:
			battle.life_max += 25
			battle.heal(25)
	pending_breakthroughs -= 1
	rebuild_weapons()
	save_run()
	continue_after_battle()

func show_reward() -> void:
	if not has_claim:
		return
	var mat := set_overlay("reward","Chiến lợi phẩm","Chọn một vật phẩm hoặc đổi phần thưởng lấy linh thạch.")
	var y := 162
	for id in pending_rewards:
		var row: Dictionary = DATA.DO[id]
		button(mat,Rect2(35,y,548,47),"%s   ·   %s" % [row.ten,row.loai],pick_reward.bind(id),true)
		label(mat,Vector2(47,y+51),526,row.mo,13,MUTED)
		y += 91
	button(mat,Rect2(35,353,548,49),"Nhận 6 linh thạch",pick_reward.bind(""))
	button(mat,Rect2(35,453,548,38),"Để sau",close_overlay)

func pick_reward(id: String) -> void:
	has_claim = false
	pending_rewards.clear()
	close_overlay()
	if id.is_empty():
		add_coins(6)
		announce("Đã nhận 6 linh thạch.")
	else:
		equip(id)
	refresh()
	save_run()

func accessible(n: int) -> bool:
	if heard.has(n):
		return true
	for edge in DATA.NOI:
		if edge.has(n) and notes.has(edge[1] if edge[0] == n else edge[0]):
			return true
	return false

func show_map() -> void:
	if has_claim:
		show_reward()
		return
	if not incoming.is_empty():
		announce("Chọn ô đặt vật phẩm đang nhận trước khi sang phòng khác.")
		return
	if battle.active or screen not in ["play","map"]:
		return
	var mat := set_overlay("map",DATA.TANG[depth],"Chọn phòng đã ghé hoặc phòng nối với đường đã mở.",true)
	for edge in DATA.NOI:
		var line := Line2D.new()
		line.add_point(DATA.VI_TRI_BAN_DO[edge[0]])
		line.add_point(DATA.VI_TRI_BAN_DO[edge[1]])
		line.width = 2.0
		line.default_color = Color("638478") if accessible(edge[0]) and accessible(edge[1]) else Color("33403e")
		mat.add_child(line)
	for i in range(6):
		var p: Vector2 = DATA.VI_TRI_BAN_DO[i]
		var suffix := "Đang ở đây" if i == room else ("Đã ghé" if heard.has(i) else ("Đường mở" if accessible(i) else "Chưa mở"))
		var b := button(mat,Rect2(p-Vector2(77,25),Vector2(154,50)),DATA.DIA_DIEM[i],enter_room.bind(i),i == room,14)
		b.disabled = not accessible(i) or i == room
		var l := label(mat,p+Vector2(-77,28),154,suffix,13,GREEN if i == room else MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(mat,Rect2(33,491,690,49),"Về phòng hiện tại",close_overlay)

func interact() -> void:
	if battle.active:
		return
	if not incoming.is_empty():
		announce("Chọn ô đặt vật phẩm đang nhận trước khi tương tác.")
		return
	if has_claim:
		show_reward()
	elif room == 3:
		show_shop()
	elif room == 4 and not altar_used:
		show_altar()
	elif room == 5 and depth < DATA.TANG.size()-1:
		show_descent()
	else:
		show_map()

func show_shop() -> void:
	var mat := set_overlay("shop","Linh Bảo Các","Linh Bảo Các nhận linh thạch. Hiện có %d linh thạch." % coins)
	var goods := [["loi",8],["no",14],["phu",9],["life",6],["slot",11]]
	for i in range(goods.size()):
		var id: String = goods[i][0]
		var cost: int = goods[i][1]
		var title: String = "Hồi Nguyên Đan · Hồi 30 sinh lực" if id == "life" else ("Mở một ô hồn trận" if id == "slot" else DATA.DO[id].ten)
		var b := button(mat,Rect2(35,139+i*57,548,46),"%s   ·   %d linh thạch" % [title,cost],buy.bind(id,cost))
		b.disabled = coins < cost or (id == "slot" and open_slots == 6) or (id == "life" and battle.life >= battle.life_max)
	button(mat,Rect2(35,438,548,47),"Rời quán",close_overlay)

func buy(id: String, cost: int) -> void:
	if coins < cost:
		return
	coins -= cost
	if id == "slot":
		open_slots += 1
	elif id == "life":
		battle.heal(30.0)
	else:
		close_overlay()
		equip(id)
		return
	refresh()
	show_shop()
	save_run()

func show_altar() -> void:
	var mat := set_overlay("altar","Cổ Đàn","Đặt tay lên trụ đá. Anh có thể mang một dị vật ra khỏi phòng.")
	var options: Array = []
	for id in DATA.DI_VAT:
		if not relics.has(id):
			options.append(id)
	options.shuffle()
	for i in range(mini(3,options.size())):
		var id: String = options[i]
		var y := 155 + 87*i
		button(mat,Rect2(35,y,548,44),DATA.DI_VAT[id][0],claim_relic.bind(id),true)
		label(mat,Vector2(45,y+47),520,DATA.DI_VAT[id][1],14,MUTED)
	button(mat,Rect2(35,438,548,43),"Rời đàn",close_overlay)

func claim_relic(id: String) -> void:
	if altar_used:
		return
	altar_used = true
	relics.append(id)
	close_overlay()
	announce("Linh bảo đã nhận: %s." % DATA.DI_VAT[id][0])
	save_run()

func show_descent() -> void:
	var mat := set_overlay("descent","Trấn ấn đã phá","Lối đến %s đã mở. Có thể quay lại khám phá trước khi lên đường." % DATA.TANG[depth+1])
	button(mat,Rect2(35,199,548,54),"Đến bí cảnh tiếp theo · Hồi 22 sinh lực",descend,true)
	button(mat,Rect2(35,273,548,50),"Ở lại khám phá",close_overlay)

func descend() -> void:
	depth += 1
	next_floor()

func show_help() -> void:
	help_from_title = screen == "title"
	var mat := set_overlay("help","Cách chơi","Giữ khoảng cách và để vũ khí tự chọn mục tiêu trong tầm.")
	var lines := [
		"Di chuyển: W A S D hoặc các phím mũi tên.",
		"Chạy: giữ Shift. Lướt miễn sát thương ngắn: phím cách.",
		"Tuyệt kỹ: Q. Tương tác: E. Bản đồ: M. Tạm dừng: Esc.",
		"Hai ô: đổi chỗ hoặc ghép hai món cùng loại, cùng bậc.",
		"Đặt pháp khí chung cạnh vũ khí. Tu vi tăng khi dọn phòng; đủ mốc sẽ được chọn đạo pháp đột phá."
	]
	for i in range(lines.size()):
		var l := label(mat,Vector2(35,148+i*53),546,lines[i],16,CREAM)
		l.autowrap_mode = 2
	button(mat,Rect2(35,435,548,49),"Quay lại",show_title if help_from_title else close_overlay,true)

func show_pause() -> void:
	if screen != "play":
		return
	var mat := set_overlay("pause","Tạm dừng","Chuyến đi sẽ tiếp tục khi anh quay lại.")
	button(mat,Rect2(35,178,548,56),"Tiếp tục",close_overlay,true)
	button(mat,Rect2(35,249,548,53),"Âm thanh: %s" % ("Tắt" if muted else "Bật"),toggle_sound)
	button(mat,Rect2(35,319,548,53),"Về màn hình đầu",confirm_quit)

func confirm_quit() -> void:
	var mat := set_overlay("quit","Rời chuyến đi","Chuyến đi tự lưu ở cửa phòng và sau khi nhận thưởng. Nếu đang giao chiến, tiếp tục sẽ bắt đầu lại phòng đó.")
	button(mat,Rect2(35,183,548,54),"Về màn hình đầu",show_title)
	button(mat,Rect2(35,256,548,51),"Chơi tiếp",close_overlay,true)

func toggle_sound() -> void:
	muted = not muted
	save_options()
	screen = "play"
	show_pause()

func save_options() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ky_luc","ha_guc",recorded)
	cfg.set_value("tuy_chon","im_lang",muted)
	cfg.save(SAVE)

func show_end(win: bool) -> void:
	STORAGE.clear_run()
	recorded = maxi(recorded,battle.kills)
	save_options()
	var caption := "Ba trấn ấn đã phá. Linh mạch hồi sinh; đường tu tiên lại mở." if win else "Chuyến tu hành kết thúc. Chọn tông môn và kết pháp trận mới để trở lại bí cảnh."
	var mat := set_overlay("end","Trở về" if win else "Ngã xuống",caption)
	var elapsed := elapsed_before + floori(float(Time.get_ticks_msec()-game_start)/1000.0)
	label(mat,Vector2(35,168),548,"Địch hạ gục: %d   ·   Linh thạch: %d" % [battle.kills,coins],21,GOLD)
	label(mat,Vector2(35,218),548,"Thời gian: %d phút %02d giây   ·   Kỷ lục: %d" % [floori(elapsed/60.0),elapsed%60,recorded],16,MUTED)
	button(mat,Rect2(35,303,548,54),"Bắt đầu chuyến mới",show_title,true)

func announce(text: String) -> void:
	msg = text
	msg_until = Time.get_ticks_msec()+3300

func _process(_delta: float) -> void:
	if items.size() != 6:
		return
	var next_xp := str(DATA.MOC_TU_VI[realm+1]) if realm < 4 else "viên mãn"
	cultivation_label.text = "%s  ·  %s  ·  Tu vi %d / %s" % [DATA.MON_PHAI[school].ten,DATA.CANH_GIOI[realm],cultivation,next_xp]
	skill_label.text = "Q · %s
%s" % [DATA.MON_PHAI[school].tuyet_ky, "Sẵn sàng" if battle.skill_cool <= 0 else "Hồi chiêu: %d giây" % ceili(battle.skill_cool)]
	rank.text = "%s   /   %s" % [DATA.TANG[depth],DATA.DIA_DIEM[room]]
	hp_label.text = "Sinh lực  %d / %d" % [ceili(battle.life),roundi(battle.life_max)]
	life_bar.value = 100.0*battle.life/battle.life_max
	stamina_bar.value = battle.stamina
	dash_bar.value = 100.0 - 100.0*battle.dash_cool/(1.05 if relics.has("dep") else 1.5)
	var round_info := "   ·   Đợt %d / %d" % [maxi(1,battle.wave),battle.waves] if battle.active else ""
	status.text = "%d linh thạch · %d hạ gục%s" % [coins,battle.kills,round_info]
	if Time.get_ticks_msec() < msg_until:
		prompt_label.text = msg
	elif battle.active:
		prompt_label.text = "Di chuyển  W A S D   ·   Chạy  Shift   ·   Lướt  Phím cách   ·   Tuyệt kỹ  Q"
	elif has_claim:
		prompt_label.text = "E  Nhận chiến lợi phẩm"
	elif room == 3:
		prompt_label.text = "E  Mua vật phẩm   ·   M  Bản đồ"
	elif room == 4 and not altar_used:
		prompt_label.text = "E  Chọn dị vật   ·   M  Bản đồ"
	else:
		prompt_label.text = "M  Bản đồ   ·   Esc  Tạm dừng"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).physical_keycode
	if k == KEY_ESCAPE:
		if screen == "play":
			show_pause()
		elif screen == "descent" or screen in ["pause","map","reward","altar","shop","quit"]:
			close_overlay()
		elif screen == "help":
			if help_from_title:
				show_title()
			else:
				close_overlay()
		return
	if screen == "map" and k == KEY_M:
		close_overlay()
		return
	if screen != "play":
		return
	match k:
		KEY_Q: battle.use_skill()
		KEY_SPACE: battle.dash()
		KEY_E: interact()
		KEY_M: show_map()

func make_tones() -> void:
	for kind in ["luot","dau","thang"]:
		var sample := AudioStreamWAV.new()
		sample.format = AudioStreamWAV.FORMAT_16_BITS
		sample.mix_rate = 22050
		var buffer := PackedByteArray()
		var duration := 0.25 if kind == "thang" else 0.12
		var n := int(22050*duration)
		buffer.resize(n*2)
		for i in range(n):
			var t := float(i)/22050.0
			var freq := (360.0 if kind == "thang" else (170.0 if kind == "luot" else 84.0))
			var curve := 0.95+t*4.0 if kind == "thang" else 1.0-t*3.5
			var value := int(8700*sin(TAU*freq*t*curve)*sin(PI*i/float(n))*exp(-t*4.0))
			buffer.encode_s16(i*2,value)
		sample.data = buffer
		tones[kind] = sample

func play_sound(kind: String) -> void:
	if not muted and tones.has(kind):
		sfx.stream = tones[kind]
		sfx.play()

func save_run(at_door := false) -> void:
	if items.size() != 6 or screen in ["title", "end"] or not incoming.is_empty() or (battle.active and not at_door):
		return
	var state := {
		"version":1, "school":school, "realm":realm, "cultivation":cultivation,
		"pending_breakthroughs":pending_breakthroughs, "power_bonus":power_bonus,
		"haste_bonus":haste_bonus, "depth":depth, "room":room, "coins":coins,
		"open_slots":open_slots, "items":items, "relics":relics,
		"heard":heard.keys(), "notes":notes.keys(), "room_seeds":room_seeds,
		"altar_used":altar_used, "has_claim":has_claim, "pending_rewards":pending_rewards,
		"difficulty":difficulty, "life":battle.life, "life_max":battle.life_max,
		"kills":battle.kills, "kills_at_entry":kills_at_entry,
		"elapsed":elapsed_before + int((Time.get_ticks_msec()-game_start)/1000),
		"after_breakthrough":after_breakthrough, "skill_cool":battle.skill_cool
	}
	if not STORAGE.write_run(state):
		announce("Không lưu được tiến độ. Kiểm tra quyền ghi thư mục dữ liệu.")

func resume_run() -> void:
	var saved: Dictionary = STORAGE.read_run()
	if saved.is_empty():
		announce("Không tìm thấy bản lưu hợp lệ.")
		return
	for key in ["school","realm","cultivation","pending_breakthroughs","power_bonus","haste_bonus","depth","room","coins","open_slots","altar_used","has_claim","difficulty","kills_at_entry","after_breakthrough"]:
		set(key,saved[key])
	items.assign(saved.items)
	relics.assign(saved.relics)
	pending_rewards.assign(saved.pending_rewards)
	room_seeds.assign(saved.room_seeds)
	heard.clear()
	notes.clear()
	for n in saved.heard:
		heard[int(n)] = true
	for n in saved.notes:
		notes[int(n)] = true
	battle.life = saved.life
	battle.life_max = saved.life_max
	battle.kills = int(saved.kills)
	battle.hard = difficulty
	battle.school = school
	battle.realm = realm
	battle.relics = relics
	battle.skill_cool = saved.skill_cool
	elapsed_before = int(saved.elapsed)
	game_start = Time.get_ticks_msec()
	incoming = ""
	focused_slot = -1
	battle.enter(room,depth,room in [1,2,5] and not notes.has(room),room_seeds[room])
	rebuild_weapons()
	close_overlay()
	if pending_breakthroughs > 0:
		show_breakthrough()
	elif room == 5 and notes.has(room):
		if depth == DATA.TANG.size()-1:
			show_end(true)
		else:
			show_descent()
	announce("Đã khôi phục chuyến tu hành.")
