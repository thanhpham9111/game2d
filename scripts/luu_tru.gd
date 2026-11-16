extends RefCounted

const DATA = preload("res://scripts/noi_dung.gd")
const PATH := "user://tien_lo.json"

static func valid(d: Variant) -> bool:
	if not d is Dictionary or d.get("version") != 1:
		return false
	var ranges := {"school":[0,2],"realm":[0,4],"cultivation":[0,100000],"pending_breakthroughs":[0,4],"depth":[0,2],"room":[0,5],"coins":[0,1000000],"open_slots":[4,6],"kills":[0,100000],"kills_at_entry":[0,100000],"elapsed":[0,100000000]}
	for key in ranges:
		if not d.has(key) or not (d[key] is int or d[key] is float):
			return false
		if not is_finite(float(d[key])) or d[key] != int(d[key]) or d[key] < ranges[key][0] or d[key] > ranges[key][1]:
			return false
	for key in ["life","life_max","power_bonus","haste_bonus","skill_cool"]:
		if not d.get(key) is float and not d.get(key) is int:
			return false
		if not is_finite(float(d[key])) or d[key] < 0 or d[key] > 10000:
			return false
	if d.life <= 0 or d.life_max < 1 or d.life > d.life_max or d.kills_at_entry > d.kills or d.pending_breakthroughs > d.realm:
		return false
	if d.cultivation < DATA.MOC_TU_VI[int(d.realm)]:
		return false
	if d.realm < 4 and d.cultivation >= DATA.MOC_TU_VI[int(d.realm)+1]:
		return false
	for key in ["altar_used","has_claim","difficulty"]:
		if not d.get(key) is bool:
			return false
	for key in ["items","relics","heard","notes","room_seeds","pending_rewards"]:
		if not d.get(key) is Array:
			return false
	if d.items.size() != 6 or d.room_seeds.size() != 6 or d.relics.size() > DATA.DI_VAT.size() or d.pending_rewards.size() > 2:
		return false
	var weapon_count := 0
	for i in range(6):
		var item: Variant = d.items[i]
		if not item is Dictionary:
			return false
		if item.is_empty():
			continue
		if not DATA.DO.has(item.get("id")) or not (item.get("lv") is int or item.get("lv") is float):
			return false
		if item.lv < 1 or item.lv > 4 or item.lv != int(item.lv) or DATA.MO_O.find(i) >= d.open_slots:
			return false
		if DATA.DO[item.id].loai != "Hỗ trợ":
			weapon_count += 1
	if weapon_count == 0:
		return false
	for key in ["heard","notes"]:
		if d[key].size() > 6:
			return false
		for n in d[key]:
			if not (n is float or n is int) or n < 0 or n > 5 or n != int(n):
				return false
	for seed_value in d.room_seeds:
		if not (seed_value is int or seed_value is float) or not is_finite(float(seed_value)):
			return false
	for id in d.relics:
		if not DATA.DI_VAT.has(id):
			return false
	for id in d.pending_rewards:
		if not DATA.DO.has(id):
			return false
	return d.get("after_breakthrough") in ["reward","descent","end"]

static func read_run() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return d if valid(d) else {}

static func write_run(d: Dictionary) -> bool:
	if not valid(d):
		return false
	var f := FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d))
	f.flush()
	var ok := f.get_error() == OK
	f.close()
	if not ok:
		return false
	return DirAccess.rename_absolute(PATH+".tmp",PATH) == OK

static func clear_run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
