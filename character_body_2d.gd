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
			pass
		SLIDE:
			pass
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		

	# Handle jump.
	
	 
		
	if velocity.y > 0:
		animPlayer.play("fall")  
		
	if health <= 0:
		health = 0
		animPlayer.play("death")
		await animPlayer.animation_finished
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")            


	move_and_slide()
func move_state ():
	if Input.is_action_just_pressed("atack") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animPlayer.play("jump")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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

func block_state ():
	animPlayer.play("block")
	animPlayer.animation_finished
