extends CharacterBody2D

enum {
	IDLE,
	ATTACK1,
	ATTACK2,
	MOVE,
	BLOCK,
	SLIDE,
	DEATH # Добавили новое состояние
}

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer

var health = 100
var gold = 0
var state = MOVE

# Переменная для запоминания следующего удара
var next_attack = 1

func _ready():
	animPlayer.animation_finished.connect(_on_animation_finished)

	# Отключаем повторы для атак и слайда
	if animPlayer.has_animation("attack1"):
		animPlayer.get_animation("attack1").loop_mode = Animation.LOOP_NONE
	if animPlayer.has_animation("attack2"):
		animPlayer.get_animation("attack2").loop_mode = Animation.LOOP_NONE
	if animPlayer.has_animation("slide"):
		animPlayer.get_animation("slide").loop_mode = Animation.LOOP_NONE

	# ИСПРАВЛЕНИЕ: Отключаем повтор для смерти, чтобы она сыграла 1 раз и остановилась
	if animPlayer.has_animation("death"):
		animPlayer.get_animation("death").loop_mode = Animation.LOOP_NONE

func _physics_process(delta):
	# Глобальная проверка здоровья
	# Если здоровье 0 и мы еще не в состоянии смерти -> переходим в смерть
	if health <= 0 and state != DEATH:
		state = DEATH

	# Машина состояний
	match state:
		MOVE:
			move_state()
		ATTACK1:
			attack1_state()
		ATTACK2:
			attack2_state()
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
		DEATH:
			death_state() # Вызываем функцию смерти

	# Гравитация работает всегда, даже при смерти (чтобы труп падал на землю)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Анимация падения (только если живой и двигается)
	if velocity.y > 0 and state == MOVE:
		animPlayer.play("fall")

	move_and_slide()

# --- ОБРАБОТКА СИГНАЛОВ (КОНЕЦ АНИМАЦИИ) ---
func _on_animation_finished(anim_name):
	if anim_name == "attack1":
		if Input.is_action_pressed("attack"):
			state = ATTACK2
		else:
			state = MOVE
			next_attack = 2

	elif anim_name == "attack2":
		# Бесконечное комбо: если кнопка зажата, бьем снова 1-й атакой
		if Input.is_action_pressed("attack"):
			state = ATTACK1
		else:
			state = MOVE
			next_attack = 1

	elif anim_name == "slide":
		state = MOVE

	# КОГДА АНИМАЦИЯ СМЕРТИ ЗАКОНЧИЛАСЬ
	elif anim_name == "death":
		# Удаляем персонажа и выходим в меню
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
# ------------------------------------------------------

func move_state():
	if Input.is_action_just_pressed("attack"):
		velocity.x = 0
		if next_attack == 1:
			state = ATTACK1
		else:
			state = ATTACK2
		return

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animPlayer.play("jump")

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
		anim.position.x = -5
		# Отражаем хитбокс влево. Замени "AttackArea" на точное имя твоего узла атаки!
		if has_node("AttackArea"):
			$AttackArea.scale.x = -1

	elif direction == 1:
		anim.flip_h = false
		anim.position.x = 5
		# Возвращаем хитбокс вправо
		if has_node("AttackArea"):
			$AttackArea.scale.x = 1

	if Input.is_action_just_pressed("block"):
		if velocity.x == 0:
			state = BLOCK
		else:
			state = SLIDE

func start_slide():
	pass

func block_state():
	velocity.x = 0
	if animPlayer.current_animation != "block":
		animPlayer.play("block")
	if not Input.is_action_pressed("block"):
		state = MOVE

func slide_state():
	if animPlayer.current_animation != "slide":
		animPlayer.play("slide")

func attack1_state():
	velocity.x = 0
	if not animPlayer.has_animation("attack1"): return
	if animPlayer.current_animation != "attack1":
		animPlayer.play("attack1")

func attack2_state():
	velocity.x = 0
	if not animPlayer.has_animation("attack2"): return
	if animPlayer.current_animation != "attack2":
		animPlayer.play("attack2")

# --- НОВАЯ ФУНКЦИЯ ДЛЯ СОСТОЯНИЯ СМЕРТИ ---
func death_state():
	velocity.x = 0 # Труп не должен скользить

	# Запускаем анимацию только один раз
	if animPlayer.current_animation != "death":
		animPlayer.play("death")

	# Здесь нет проверки кнопок, поэтому игрок не может двигаться
	# Ждем, пока сработает сигнал _on_animation_finished
