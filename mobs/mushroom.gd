extends CharacterBody2D

var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')

var chase = false
var speed = 100
@onready var anim = $AnimatedSprite2D
var alive = true

func _physics_process(delta):
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta

	# Ищем игрока (путь как в твоем проекте для скелета)
	var player = $"../player/player"

	if alive == true:
		if chase == true:
			var direction = (player.position - self.position).normalized()
			velocity.x = direction.x * speed
			anim.play("run")

			# Поворот спрайта в сторону игрока
			if direction.x < 0:
				$AnimatedSprite2D.flip_h = true
			else:
				$AnimatedSprite2D.flip_h = false
		else:
			velocity.x = 0
			anim.play("idle")

	move_and_slide()

# --- КОПИРУЕМ ЛОГИКУ ВЗАИМОДЕЙСТВИЯ ---

func _on_detector_body_entered(body):
	if body.name == "player":
		chase = true

func _on_detector_body_exited(body):
	if body.name == "player":
		chase = false

func _on_death_body_entered(body):
	if body.name == "player":
		# Игрок подпрыгивает, когда наступает на гриб
		body.velocity.y -= 200
		death()

func _on_death_2_body_entered(body):
	if body.name == "player":
		if alive == true:
			# Наносим урон игроку (как у скелета)
			body.health -= 40
		death() # Гриб тоже исчезает при столкновении

func death():
	alive = false
	anim.play("death")
	await anim.animation_finished
	queue_free()
