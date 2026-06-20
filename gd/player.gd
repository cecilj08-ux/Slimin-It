class_name Player extends CharacterBody2D

@onready var sprite := $playerSprite
@onready var ani := $playerSprite/AnimationPlayer
@onready var coyoteTime := $coyoteTime
@onready var bleedTime := $bleedTime
@onready var eatParticles := $eatParticles
@onready var bleedParticles := $bleedParticles
@onready var fallParticles := $fallParticles
@onready var chargeParticles := $chargeParticles
@onready var camera := $Camera2D
@onready var new_scale := scale # NOTE: Use this instead of scale for calculations

const jump_power := 220
const acceleration := 5
const fallspeed_cap := 600

var friction := 6
var speed := 120.0
var direction := 0.0
var lerpWeight := 0.0
var charge_Jump := 0.0 

var can_walk := true
var can_jump := false
var was_on_wall := false
var can_stick := true
var dead := false

const jump_sprite := preload("res://resources/1bit slime platformer/hybrid_bg/slime_jump_h.png")
const walk_sprite := preload("res://resources/1bit slime platformer/hybrid_bg/slime_walk_h.png")
const wall_sprite := preload("res://resources/1bit slime platformer/hybrid_bg/slime_wall_h.png")
const crouch_sprite := preload("res://resources/1bit slime platformer/hybrid_bg/slime_crouch_h.png")

func apply_gravity(delta: float) -> void: velocity += get_gravity() * (delta if Input.is_action_pressed("up") else delta*3)

func calculate_vector_areas(original: Vector2, added: Vector2, subtract := false) -> Vector2:
	var original_area = original.x*original.y
	var added_area = added.x*added.y
	if subtract: added_area *= -1
	return Vector2(sqrt(original_area+added_area), sqrt(original_area+added_area))

func spike_1() -> void:
	if new_scale != Vector2(0,0):
		if new_scale.x <= sqrt(3):
			new_scale = calculate_vector_areas(new_scale, Vector2.ONE, true)
			new_scale.x = sqrt(round(new_scale.x**2))
			new_scale.y = sqrt(round(new_scale.y**2))
		else:
			new_scale = calculate_vector_areas(new_scale,new_scale-Vector2.ONE, true)
			new_scale.x = sqrt(floor(new_scale.x**2))
			new_scale.y = sqrt(floor(new_scale.y**2))

func death(cause = "unspecified") -> void:
	dead = true
	Global.can_pause = false
	set_collision_layer_value(5, false)
	$playerHitbox.set_collision_mask_value(5,false)
	sprite.visible = false
	can_walk = false
	can_jump = false
	velocity = Vector2.ZERO
	eatParticles.amount = round(8*scale.x)
	fallParticles.amount = round(8*scale.x)
	if cause is Enemy:
		camera.reparent(cause)
		emit_particle(eatParticles)
	elif cause == "fall": emit_particle(fallParticles)
	elif cause == "small":
		bleedParticles.emitting = false
		emit_particle(eatParticles)
	else: emit_particle(eatParticles)
	await get_tree().create_timer(2.5).timeout
	Global.can_pause = true
	Global.attempts += 1
	if Global.time_trial:
		Global.time_trial = false
		Global.time_limit = 0.0
		Global.time_taken = 0.0
		get_tree().change_scene_to_file("res://tscn/stages/world_" + str(get_tree().current_scene.get_meta("world_id")[0]) + "/" + "stage_selection_" + str(get_tree().current_scene.get_meta("world_id")[0]) + ".tscn")
	else:
		get_tree().reload_current_scene.call_deferred()

func emit_particle(particle: GPUParticles2D) -> void:
	var emitted_particles := particle.duplicate()
	emitted_particles.position = position
	get_parent().add_child(emitted_particles)
	emitted_particles.restart()
	await emitted_particles.finished
	emitted_particles.queue_free()

func _ready() -> void:
	if not get_tree().get_nodes_in_group("void").is_empty(): camera.limit_bottom = get_tree().get_first_node_in_group("void").position.y-(new_scale.y*8)
	if get_tree().current_scene.has_meta("attempt_counter") and get_tree().current_scene.get_meta("attempt_counter"):
		var attempt_counter_scene = preload("res://tscn/elements/attempt_counter.tscn")
		var attemptCounter := attempt_counter_scene.instantiate()
		add_child(attemptCounter)
	if !get_tree().current_scene.has_meta("world_id"): 
		Global.time_trial = false
		Global.time_limit = 0.0

func _physics_process(delta: float) -> void:
# Gravity
	apply_gravity(delta)
	if is_on_wall_only() and can_stick:
		if velocity.y < 0 and Input.is_action_pressed("up"): pass
		else: velocity.y = 30 if Input.is_action_pressed("down") else 0
		was_on_wall = true
	elif is_on_floor(): was_on_wall = false
	if velocity.y > fallspeed_cap: velocity.y = fallspeed_cap
# Coyote Timing
	if is_on_floor() or is_on_wall():
		if not can_stick and is_on_wall_only(): pass
		else: coyoteTime.start()
	can_jump = coyoteTime.time_left != 0 and velocity.y >= 0 and sprite.visible
# Super Jump
	if charge_Jump == 0.75:
		if Input.is_action_just_pressed("up"):
			emit_particle(fallParticles)
			velocity.y = -((jump_power) + (scale.x-1)*25)*2
			charge_Jump = 0
			can_jump = false
			new_scale = calculate_vector_areas(new_scale, Vector2.ONE, true)
			new_scale.x = sqrt(round(new_scale.x**2))
			new_scale.y = sqrt(round(new_scale.y**2))
	if Input.is_action_pressed("down") and can_jump and charge_Jump <= 0.75 and !is_on_wall_only() and new_scale.x > 1 and not direction: 
		charge_Jump += delta
		if charge_Jump > 0.75: charge_Jump = 0.75
	elif charge_Jump > 0: charge_Jump -= delta*2
# Jump and drop
	if Input.is_action_just_pressed("up") and can_jump:
		if is_on_wall_only() and can_stick:
			sprite.flip_h = not sprite.flip_h
			velocity += Vector2(-speed - (scale.x-1)*25 if sprite.flip_h else speed + (scale.x-1)*25, -jump_power*0.66)
		elif was_on_wall and can_stick: velocity += Vector2(-speed - (scale.x-1)*25 if sprite.flip_h else speed + (scale.x-1)*25, -(jump_power*0.66) - velocity.y)
		elif can_stick or is_on_floor(): velocity.y = -(jump_power + (scale.x-1)*25)
	set_collision_mask_value(4, not Input.is_action_pressed("down"))
# Movement
	direction = Input.get_axis("left", "right") if can_walk else 0.0
	if direction: charge_Jump = 0
	lerpWeight = delta*(acceleration if direction else friction)
	velocity.x = lerp(velocity.x, direction*speed, lerpWeight)
	move_and_slide()
# Animation
	if velocity.x < 0 and not is_on_wall(): sprite.flip_h = true
	elif velocity.x > 0 and not is_on_wall(): sprite.flip_h = false
	ani.speed_scale = 1+abs(velocity.x)*0.075
	if is_on_floor():
		if charge_Jump > 0:
			ani.stop()
			sprite.texture = crouch_sprite
		elif abs(velocity.x) < 10: ani.play("idle")
		elif abs(velocity.x) >= 10: ani.play("walk")
	elif not is_on_floor():
		ani.stop()
		if is_on_wall() and can_stick:
			sprite.texture = wall_sprite
			if velocity.y < -10: sprite.frame = 0
			elif velocity.y <= 0: sprite.frame = 1
			elif Input.is_action_pressed("down"): sprite.frame = 2
		else:
			sprite.texture = jump_sprite
			if velocity.y < -100: sprite.frame = 1
			elif velocity.y < 100: sprite.frame = 2
			elif velocity.y > 100: sprite.frame = 3
	chargeParticles.emitting = true if charge_Jump >= 0.75 else false
# Size scaling
	if new_scale != scale: scale = scale.move_toward(new_scale, delta)
	if scale <= Vector2(0.25,0.25) and not dead: death("small")
# Camera
	if camera.position != Vector2.ZERO: camera.position = lerp(camera.position, Vector2.ZERO, delta)

func _on_coyote_timer_timeout() -> void: was_on_wall = false

func _on_player_hitbox_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		if body.name == "ice":
			can_stick = false
			friction = 0
			speed *= 1.2
		elif body.name == "spikes":
			emit_particle(eatParticles)
		elif body.name == "instakill": death()
		elif "hider" in body.name: body.visible = false
	elif body is Enemy:
		if new_scale >= body.scale:
			new_scale = calculate_vector_areas(new_scale, body.scale)
			camera.limit_bottom = get_tree().get_first_node_in_group("void").position.y-(new_scale.y*8)
			emit_particle(eatParticles)
			body.queue_free()
		else: death(body)
func _on_player_hitbox_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		if body.name == "ice":
			can_stick = true
			friction = 6
			speed /= 1.2
		elif body.name == "spikes":
			bleedParticles.restart()
			spike_1()
		elif "hider" in body.name: body.visible = true
