extends Node2D

# Ссылки на узлы управления светом и цветом
@onready var sun = $DirectionalLight2D
@onready var timer = $DayNight
@onready var tint_world = $CanvasModulate
@onready var tint_bg = $bg/CanvasModulate

# Ссылки на все фонари (магазин и прочие)
@onready var lights = [
	$PointLight2D,
	$PointLight2D2,
	$PointLight2D3
]

# Фазы суток
enum Phase {MORNING, DAY, EVENING, NIGHT}
var current_phase = Phase.DAY

# Настройки цветов
const GLOBAL_COLORS = {
	Phase.MORNING: Color("9b7a68"),
	Phase.DAY: Color("ffffff"),
	Phase.EVENING: Color("4e4263"),
	Phase.NIGHT: Color("020208")
}

# Энергия солнца
const SUN_ENERGY = {
	Phase.MORNING: 0.5,
	Phase.DAY: 1.0,
	Phase.EVENING: 0.3,
	Phase.NIGHT: 0.0
}

func _ready():
	if timer:
		timer.wait_time = 10.0
		timer.timeout.connect(_on_day_night_timeout)
		timer.start()

	apply_phase_settings(true)

func _on_day_night_timeout():
	match current_phase:
		Phase.MORNING: current_phase = Phase.DAY
		Phase.DAY: current_phase = Phase.EVENING
		Phase.EVENING: current_phase = Phase.NIGHT
		Phase.NIGHT: current_phase = Phase.MORNING

	apply_phase_settings(false)

func apply_phase_settings(instant: bool):
	var target_tint = GLOBAL_COLORS[current_phase]
	var target_energy = SUN_ENERGY[current_phase]
	var duration = 4.0

	# Логика искусственного освещения:
	var is_dark = (current_phase == Phase.NIGHT or current_phase == Phase.EVENING)
	var target_light_energy = 3.5 if is_dark else 0.0

	if instant:
		tint_world.color = target_tint
		if tint_bg: tint_bg.color = target_tint
		sun.energy = target_energy
		# Устанавливаем энергию всем фонарям из списка
		for light in lights:
			if light: light.energy = target_light_energy
	else:
		var tween = create_tween().set_parallel(true)

		tween.tween_property(tint_world, "color", target_tint, duration)
		if tint_bg:
			tween.tween_property(tint_bg, "color", target_tint, duration)

		tween.tween_property(sun, "energy", target_energy, duration)

		# Плавно меняем энергию для всех фонарей
		for light in lights:
			if light:
				tween.tween_property(light, "energy", target_light_energy, duration)

	print("Фаза: ", Phase.keys()[current_phase], " | Фонари: ", "ВКЛ" if is_dark else "ВЫКЛ")
