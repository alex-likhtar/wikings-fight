extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100
var chase = false
var alive = true

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	# Гравитация работает всегда
	if not is_on_floor():
		velocity.y += gravity * delta

	if alive:
		var player = get_tree().get_first_node_in_group("player")

		if chase and player:
			# ПРЕСЛЕДОВАНИЕ
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed

			# Поворот спрайта
			anim.flip_h = direction.x < 0

			# Проигрываем run, только если не проигрывается анимация смерти
			if anim.animation != "death":
				anim.play("run")
		else:
			# ОСТАНОВКА (когда игрок вышел из детектора или его нет)
			velocity.x = move_toward(velocity.x, 0, speed)

			# Проигрываем idle, только если гриб жив и не играет смерть
			if anim.animation != "death":
				anim.play("idle")

		move_and_slide()

# --- СИГНАЛЫ ДЕТЕКТОРА ---

func _on_detector_body_entered(body):
	if body.is_in_group("player"):
		chase = true

func _on_detector_body_exited(body):
	if body.is_in_group("player"):
		chase = false # Как только игрок вышел, chase станет false и сработает idle

# --- ЛОГИКА СМЕРТИ (С ТВИНОМ УХОДА ПОД ЗЕМЛЮ) ---

func die():
	if not alive: return
	alive = false
	chase = false

	velocity = Vector2.ZERO

	# Отключаем физику, чтобы гриб не мешал игроку
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("death/CollisionShape2D"):
		$death/CollisionShape2D.set_deferred("disabled", true)
	if has_node("death2/CollisionShape2D"):
		$death2/CollisionShape2D.set_deferred("disabled", true)
	if has_node("detector/CollisionShape2D"):
		$detector/CollisionShape2D.set_deferred("disabled", true)

	# Анимация смерти (без повтора)
	anim.sprite_frames.set_animation_loop("death", false)
	anim.play("death")

	await anim.animation_finished

	# Красивый уход под землю
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self , "position", position + Vector2(0, 35), 0.6)
	tween.tween_property(self , "modulate:a", 0, 0.6)

	tween.chain().tween_callback(queue_free)

# --- УРОН И ПРЫЖОК ---

func _on_death_body_entered(body):
	if alive and body.is_in_group("player"):
		if "velocity" in body:
			body.velocity.y = -350
		die()

func _on_death_2_body_entered(body):
	if alive and body.is_in_group("player"):
		if "health" in body:
			body.health -= 60
		die()
