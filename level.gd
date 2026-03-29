extends Node2D

# --- НАСТРОЙКИ СПАВНА ---
@export var mushroom_scene: PackedScene = preload("res://mobs/mushrom.tscn")
@export var skeleton_scene: PackedScene = preload("res://mobs/skeleton.tscn")

@onready var forbidden_zone = $player/SpawnForbiddenZone
@onready var player = $player
@onready var mobs_container = $mobs

var spawn_timer: Timer

# Дистанции спавна
var min_spawn_distance = 500.0
var max_spawn_distance = 1300.0

# Лимиты и задержки
var current_max_mobs = 0
var mobs_spawned_in_phase = 0
var min_spawn_delay = 2.0
var max_spawn_delay = 10.0

# Высота, с которой "прощупываем" землю (чуть выше твоих 576)
const SPAWN_CHECK_HEIGHT = 500.0
# -------------------------

# Ссылки на UI и окружение
@onready var day_label_ui = $CanvasLayer/DayCounter
@onready var new_day_popup = $CanvasLayer/NewDayLabel
@onready var sun = $DirectionalLight2D
@onready var timer = $DayNight
@onready var tint_world = $CanvasModulate
@onready var tint_bg = $bg/CanvasModulate
@onready var lights = [$PointLight2D, $PointLight2D2, $PointLight2D3]

enum Phase {MORNING, DAY, EVENING, NIGHT}
var current_phase = Phase.DAY
var day_count = 1

const PHASE_DURATION = {
	Phase.MORNING: 60.0,
	Phase.DAY: 120.0,
	Phase.EVENING: 60.0,
	Phase.NIGHT: 120.0
}

const GLOBAL_COLORS = {
	Phase.MORNING: Color("9b7a68"), Phase.DAY: Color("ffffff"),
	Phase.EVENING: Color("4e4263"), Phase.NIGHT: Color("020208")
}

const SUN_ENERGY = {
	Phase.MORNING: 0.5, Phase.DAY: 1.0, Phase.EVENING: 0.3, Phase.NIGHT: 0.0
}

func _ready():
	randomize()

	# Создаем таймер сразу, чтобы избежать ошибки null
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	if timer:
		timer.timeout.connect(_on_day_night_timeout)
		start_phase(Phase.MORNING)

	update_ui_text()
	show_new_day_animation()
	apply_phase_settings(true)
	set_random_spawn_timer()

func _on_day_night_timeout():
	var next_phase: Phase
	match current_phase:
		Phase.MORNING: next_phase = Phase.DAY
		Phase.DAY: next_phase = Phase.EVENING
		Phase.EVENING: next_phase = Phase.NIGHT
		Phase.NIGHT:
			next_phase = Phase.MORNING
			day_count += 1
			update_ui_text()
			show_new_day_animation()
	start_phase(next_phase)

func start_phase(phase: Phase):
	current_phase = phase
	mobs_spawned_in_phase = 0

	match current_phase:
		Phase.MORNING: current_max_mobs = 0
		Phase.DAY: current_max_mobs = randi_range(2, 8)
		Phase.EVENING: current_max_mobs = randi_range(10, 25)
		Phase.NIGHT: pass

	if timer:
		timer.stop()
		timer.wait_time = PHASE_DURATION[phase]
		timer.start()

	apply_phase_settings(false)
	set_random_spawn_timer()

func set_random_spawn_timer():
	if spawn_timer:
		spawn_timer.start(randf_range(min_spawn_delay, max_spawn_delay))

# --- ЛОГИКА СПАВНА С ПРОВЕРКОЙ ТЕРРЕЙНА ---

func _on_spawn_timer_timeout():
	if mobs_spawned_in_phase < current_max_mobs:
		attempt_spawn()
	set_random_spawn_timer()

func attempt_spawn():
	if not player: return

	# Увеличиваем количество попыток поиска, так как не везде есть земля
	for i in range(20):
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		var direction = 1 if randf() > 0.5 else -1
		var target_x = player.global_position.x + (distance * direction)

		# 1. Проверка зоны детектора (чтобы не спавнить на глазах)
		if is_x_in_forbidden_zone(target_x):
			continue

		# 2. Проверка: есть ли под этой точкой твердый блок?
		var ground_pos = check_for_solid_ground(target_x)

		if ground_pos != Vector2.ZERO:
			spawn_mob_at(ground_pos)
			return # Успешный спавн, выходим из цикла попыток

func check_for_solid_ground(x_pos: float) -> Vector2:
	var space_state = get_world_2d().direct_space_state

	# Пускаем луч из точки чуть выше земли (500) до точки ниже земли (700)
	var ray_start = Vector2(x_pos, SPAWN_CHECK_HEIGHT)
	var ray_end = Vector2(x_pos, 750)

	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	query.collision_mask = 1 # Слой твоей земли (TileMap/StaticBody)

	var result = space_state.intersect_ray(query)

	if result:
		# Если луч во что-то врезался, возвращаем координаты точки столкновения
		return result.position

	# Если луч ничего не нашел (там пропасть), возвращаем пустой вектор
	return Vector2.ZERO

func spawn_mob_at(pos: Vector2):
	var mob_scene = mushroom_scene if randf() > 0.5 else skeleton_scene
	var mob = mob_scene.instantiate()

	# Ставим моба точно на найденную поверхность
	mob.global_position = pos - Vector2(0, 2) # Смещение на 2 пикселя вверх, чтобы не застрял

	mobs_container.add_child(mob)
	mobs_spawned_in_phase += 1
	print("Заспавнен на твердой поверхности в: ", pos)

func is_x_in_forbidden_zone(x_pos: float) -> bool:
	if not forbidden_zone: return false
	var shape = forbidden_zone.get_node("CollisionShape2D")
	if not shape or not shape.shape: return false
	var zone_x = forbidden_zone.global_position.x
	var radius = 0.0
	if shape.shape is CircleShape2D:
		radius = shape.shape.radius
	elif shape.shape is RectangleShape2D:
		radius = shape.shape.size.x / 2
	return abs(x_pos - zone_x) < radius

# --- UI И ВИЗУАЛ (БЕЗ ИЗМЕНЕНИЙ) ---

func update_ui_text():
	if day_label_ui: day_label_ui.text = "ДЕНЬ: " + str(day_count)
	if new_day_popup: new_day_popup.text = "ДЕНЬ " + str(day_count)

func show_new_day_animation():
	if not new_day_popup: return
	new_day_popup.modulate.a = 0
	new_day_popup.scale = Vector2(0.8, 0.8)
	new_day_popup.pivot_offset = new_day_popup.size / 2
	var tween = create_tween()
	tween.tween_property(new_day_popup, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(new_day_popup, "scale", Vector2(1.1, 1.1), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.5)
	tween.tween_property(new_day_popup, "modulate:a", 0.0, 1.0)

func apply_phase_settings(instant: bool):
	var target_tint = GLOBAL_COLORS[current_phase]
	var target_energy = SUN_ENERGY[current_phase]
	var duration = 4.0
	var is_dark = (current_phase == Phase.NIGHT or current_phase == Phase.EVENING)
	var target_light_energy = 3.5 if is_dark else 0.0
	if instant:
		tint_world.color = target_tint
		if tint_bg: tint_bg.color = target_tint
		sun.energy = target_energy
		for light in lights: if light: light.energy = target_light_energy
	else:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(tint_world, "color", target_tint, duration)
		if tint_bg: tween.tween_property(tint_bg, "color", target_tint, duration)
		tween.tween_property(sun, "energy", target_energy, duration)
		for light in lights:
			if light: tween.tween_property(light, "energy", target_light_energy, duration)
