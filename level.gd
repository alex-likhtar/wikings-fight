extends Node2D

# Ссылки на UI
@onready var day_label_ui = $CanvasLayer/DayCounter # Тот, что в углу (постоянный)
@onready var new_day_popup = $CanvasLayer/NewDayLabel # Тот, что в центре (всплывающий)

# Окружение
@onready var sun = $DirectionalLight2D
@onready var timer = $DayNight
@onready var tint_world = $CanvasModulate
@onready var tint_bg = $bg/CanvasModulate

@onready var lights = [$PointLight2D, $PointLight2D2, $PointLight2D3]

enum Phase {MORNING, DAY, EVENING, NIGHT}
var current_phase = Phase.DAY
var day_count = 1

# Настройки времени
const PHASE_DURATION = {
	Phase.MORNING: 60.0,
	Phase.DAY: 120.0,
	Phase.EVENING: 60.0,
	Phase.NIGHT: 120.0
}

const GLOBAL_COLORS = {
	Phase.MORNING: Color("9b7a68"),
	Phase.DAY: Color("ffffff"),
	Phase.EVENING: Color("4e4263"),
	Phase.NIGHT: Color("020208")
}

const SUN_ENERGY = {
	Phase.MORNING: 0.5,
	Phase.DAY: 1.0,
	Phase.EVENING: 0.3,
	Phase.NIGHT: 0.0
}

func _ready():
	if timer:
		timer.timeout.connect(_on_day_night_timeout)
		# Начинаем игру с утра первого дня
		start_phase(Phase.MORNING)

	# Сразу показываем текст "ДЕНЬ 1" при старте
	update_ui_text()
	show_new_day_animation()
	apply_phase_settings(true)

func _on_day_night_timeout():
	var next_phase: Phase
	match current_phase:
		Phase.MORNING: next_phase = Phase.DAY
		Phase.DAY: next_phase = Phase.EVENING
		Phase.EVENING: next_phase = Phase.NIGHT
		Phase.NIGHT:
			next_phase = Phase.MORNING
			day_count += 1 # Увеличиваем счетчик при наступлении утра
			update_ui_text() # Обновляем текст
			show_new_day_animation() # Запускаем анимацию в центре

	start_phase(next_phase)

# Обновление текста в интерфейсе
func update_ui_text():
	if day_label_ui:
		day_label_ui.text = "ДЕНЬ: " + str(day_count)
	if new_day_popup:
		new_day_popup.text = "ДЕНЬ " + str(day_count)

# Красивая анимация появления и исчезновения
func show_new_day_animation():
	if not new_day_popup: return

	# Сбрасываем состояние перед анимацией
	new_day_popup.modulate.a = 0
	new_day_popup.scale = Vector2(0.8, 0.8)
	new_day_popup.pivot_offset = new_day_popup.size / 2 # Центрируем точку увеличения

	var tween = create_tween()

	# 1. Плавно проявляем и увеличиваем
	tween.tween_property(new_day_popup, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(new_day_popup, "scale", Vector2(1.1, 1.1), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Держим текст на экране 2.5 секунды
	tween.tween_interval(2.5)

	# 3. Плавно скрываем
	tween.tween_property(new_day_popup, "modulate:a", 0.0, 1.0)

func start_phase(phase: Phase):
	current_phase = phase
	timer.stop()
	timer.wait_time = PHASE_DURATION[phase]
	timer.start()
	apply_phase_settings(false)
	print("Началась фаза: ", Phase.keys()[current_phase], " День: ", day_count)

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
