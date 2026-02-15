extends Node2D

# Ссылки на узлы управления светом и цветом
@onready var sun = $DirectionalLight2D
@onready var timer = $DayNight
@onready var tint_world = $CanvasModulate # Основное затемнение (блоки, игрок, мобы)
@onready var tint_bg = $bg/CanvasModulate # Затемнение для фона (внутри ParallaxBackground)

# Фазы суток
enum Phase {MORNING, DAY, EVENING, NIGHT}
var current_phase = Phase.DAY

# Настройки цветов (NIGHT сделана максимально темной)
const GLOBAL_COLORS = {
	Phase.MORNING: Color("9b7a68"), # Рассвет
	Phase.DAY: Color("ffffff"), # День (без изменений)
	Phase.EVENING: Color("4e4263"), # Закат
	Phase.NIGHT: Color("020208") # ГЛУБОКАЯ НОЧЬ (почти черный)
}

# Энергия солнца (DirectionalLight2D)
const SUN_ENERGY = {
	Phase.MORNING: 0.5,
	Phase.DAY: 1.0,
	Phase.EVENING: 0.3,
	Phase.NIGHT: 0.0
}

func _ready():
	# Настройка таймера
	if timer:
		timer.wait_time = 10.0 # Длительность одной фазы в секундах
		timer.timeout.connect(_on_day_night_timeout)
		timer.start()

	# Устанавливаем начальное состояние без анимации
	apply_phase_settings(true)

func _on_day_night_timeout():
	# Переключаем фазы по кругу
	match current_phase:
		Phase.MORNING: current_phase = Phase.DAY
		Phase.DAY: current_phase = Phase.EVENING
		Phase.EVENING: current_phase = Phase.NIGHT
		Phase.NIGHT: current_phase = Phase.MORNING

	apply_phase_settings(false)

func apply_phase_settings(instant: bool):
	var target_tint = GLOBAL_COLORS[current_phase]
	var target_energy = SUN_ENERGY[current_phase]
	var duration = 4.0 # Длительность перехода в секундах

	if instant:
		tint_world.color = target_tint
		tint_bg.color = target_tint
		sun.energy = target_energy
	else:
		# Создаем плавный переход для всех параметров сразу
		var tween = create_tween().set_parallel(true)

		# Затемняем основной мир
		tween.tween_property(tint_world, "color", target_tint, duration)

		# Затемняем фон (внутри ParallaxBackground)
		if tint_bg:
			tween.tween_property(tint_bg, "color", target_tint, duration)

		# Гасим/зажигаем солнце
		tween.tween_property(sun, "energy", target_energy, duration)

	print("Смена фазы на: ", Phase.keys()[current_phase])
