extends CharacterBody2D

enum {
	IDLE,
	ATACK1,
	ATACK2,
	MOVE,
	BLOCK,
	SLIDE
}

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
var health = 100
var gold = 0
var state = MOVE

func _physics_process(delta):
	match state:
		MOVE:
			move_state()
		ATACK1:
			pass
		ATACK2:
			pass
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
	
	# Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Анимация падения (Включаем только если мы НЕ в блоке и НЕ в слайде)
	if velocity.y > 0 and state == MOVE:
		animPlayer.play("fall")  
		
	if health <= 0:
		health = 0
		animPlayer.play("death")
		# Здесь используем await аккуратно, так как это конец игры
		await animPlayer.animation_finished
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")            

	move_and_slide()

func move_state():
	# 1. Прыжок на ПРОБЕЛ (ui_accept)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animPlayer.play("jump")

	# 2. Атака на ЛЕВУЮ кнопку мыши (attack)
	if Input.is_action_just_pressed("attack"):
		# Можно добавить переход в состояние атаки: state = ATACK1
		print("Атака!")

	# 3. Движение
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if velocity.y == 0:
			animPlayer.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("idle")
			
	if direction == -1:
		anim.flip_h = true
	elif direction == 1:
		anim.flip_h = false 

	# 4. Блок и Слайд (ПРАВАЯ кнопка мыши - block)
	if Input.is_action_just_pressed("block"):
		if velocity.x == 0:
			state = BLOCK
		else:
			start_slide() # Вызываем специальную функцию для старта слайда

# Специальная функция для настройки слайда
func start_slide():
	state = SLIDE
	animPlayer.play("slide")
	
	# --- ПРИНУДИТЕЛЬНОЕ ЛЕЧЕНИЕ ---
	# Этот код программно отключает повтор анимации, 
	# если вы забыли выключить его в редакторе.
	if animPlayer.has_animation("slide"):
		animPlayer.get_animation("slide").loop_mode = Animation.LOOP_NONE
	# ------------------------------

func block_state():
	velocity.x = 0
	if animPlayer.current_animation != "block":
		animPlayer.play("block")
		
	# Если отпустили кнопку блока -> бежим дальше
	if not Input.is_action_pressed("block"):
		state = MOVE
		
func slide_state():
	# 1. Если анимация закончилась -> выход
	if not animPlayer.is_playing():
		state = MOVE
		return

	# 2. ЗАЩИТА ОТ ЗАВИСАНИЯ:
	# Если AnimationPlayer вдруг переключился на что-то другое (не "slide"),
	# или имя анимации в коде не совпадает с редактором -> выход.
	if animPlayer.current_animation != "slide":
		state = MOVE
