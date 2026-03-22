extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100
var chase = false
var alive = true

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta

	if alive:
		var player = get_tree().get_first_node_in_group("player")
		if chase and player:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			anim.play("run")
			anim.flip_h = direction.x < 0
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			# Проверка, чтобы не перебивать анимацию смерти
			if anim.animation != "death":
				anim.play("idle")

		move_and_slide()

# Функция смерти
func die():
	if not alive: return
	alive = false
	chase = false

	velocity = Vector2.ZERO # Останавливаем движение

	# 1. Отключаем коллизии (физическое тело и зоны урона)
	$CollisionShape2D.set_deferred("disabled", true)
	# Проверь имена этих узлов в сцене скелета, если они отличаются — подправь пути
	if has_node("detector/CollisionShape2D"):
		$detector/CollisionShape2D.set_deferred("disabled", true)
	if has_node("death/CollisionShape2D"):
		$death/CollisionShape2D.set_deferred("disabled", true)
	if has_node("death2/CollisionShape2D"):
		$death2/CollisionShape2D.set_deferred("disabled", true)

	# 2. Проигрываем анимацию смерти (отключаем Loop программно)
	anim.sprite_frames.set_animation_loop("death", false)
	anim.play("death")

	# Ждем окончания анимации
	await anim.animation_finished

	# 3. Эффект ухода под землю (Tween)
	var tween = get_tree().create_tween()
	tween.set_parallel(true) # Выполнять перемещение и прозрачность одновременно

	# Плавно опускаем на 30 пикселей вниз и выводим прозрачность в 0 за 0.6 секунды
	tween.tween_property(self , "position", position + Vector2(0, 30), 0.6)
	tween.tween_property(self , "modulate:a", 0, 0.6)

	# 4. Удаляем скелета из игры после завершения эффекта
	tween.chain().tween_callback(queue_free)

# --- Сигналы (подключи их в редакторе Godot к этим функциям) ---

func _on_detector_body_entered(body):
	if body.is_in_group("player"):
		chase = true

func _on_detector_body_exited(body):
	if body.is_in_group("player"):
		chase = false

func _on_death_body_entered(body):
	if alive and body.is_in_group("player"):
		# Прыжок игрока
		if "velocity" in body:
			body.velocity.y = -350
		die()

func _on_death_2_body_entered(body):
	if alive and body.is_in_group("player"):
		# Урон игроку
		if "health" in body:
			body.health -= 40 # Скелет может бить слабее или сильнее гриба
		die()
