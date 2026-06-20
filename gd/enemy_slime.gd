extends Enemy

@onready var left_ray := $leftRay
@onready var right_ray := $rightRay
@onready var down_ray := $downRay
@onready var detection := $detection/CollisionShape2D
@onready var eatParticles := $eatParticles
@onready var bleedParticles := $bleedParticles
@onready var fallParticles := $fallParticles
@onready var new_scale := scale # NOTE: Use this instead of scale for calculations

var direction := 0.0
var lerpWeight : = 0.0
var acceleration := 5
var friction := 6

var jump_sprite := preload("res://resources/1bit slime platformer/alpha_bg/slime2_jump_a.png")

func emit_particle(particle: GPUParticles2D) -> void:
	var emitted_particles := particle.duplicate()
	emitted_particles.position = position
	get_parent().add_child(emitted_particles)
	emitted_particles.restart()
	await emitted_particles.finished
	emitted_particles.queue_free()
	
func calculate_vector_areas(original: Vector2, added: Vector2, subtract := false) -> Vector2:
	var original_area = original.x*original.y
	var added_area = added.x*added.y
	if subtract: added_area *= -1
	return Vector2(sqrt(original_area+added_area), sqrt(original_area+added_area))

func death(cause = "unspecified") -> void:
	dead = true
	set_collision_layer_value(5, false)
	sprite.visible = false
	can_jump = false
	velocity = Vector2.ZERO
	eatParticles.amount = round(8*scale.x)
	fallParticles.amount = round(8*scale.x)
	if cause is Player: emit_particle(eatParticles)
	elif cause == "fall": emit_particle(fallParticles)
	elif cause == "small":
		bleedParticles.emitting = false
		emit_particle(eatParticles)
	else: emit_particle(eatParticles)
	await get_tree().create_timer(3).timeout
	queue_free()

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

func _ready() -> void: detection.shape.radius = detection_range

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
# Animation
	ani.speed_scale = 1+abs(velocity.x)*0.075
	if is_on_floor(): ani.play("walk" if target else "idle")
	elif not is_on_floor():
		ani.stop()
		sprite.texture = jump_sprite
		if velocity.y < -100: sprite.frame = 1
		elif velocity.y < 100: sprite.frame = 2
		elif velocity.y > 100: sprite.frame = 3
# Targeting
	if target:
		aggressive = target.new_scale < scale
		sprite.flip_h = target.position.x < position.x
	# Jumping and dropping
		if can_jump:
			if position.distance_to(target.position) < detection.shape.radius*0.6 and target.position.y+(8*scale.y) < position.y and aggressive: velocity.y = -(jump_power + (scale.x-1)*25)
			elif position.distance_to(target.position) < detection.shape.radius and (left_ray.is_colliding() or right_ray.is_colliding()): velocity.y = -(jump_power + (scale.x-1)*25)
			elif not down_ray.is_colliding(): velocity.y = -(jump_power + (scale.x-1)*25)
		if aggressive: set_collision_mask_value(4, not(position.distance_to(target.position) < detection.shape.radius and target.position.y-1 > position.y))
		else: set_collision_mask_value(4, not(position.distance_to(target.position) < detection.shape.radius*0.6 and target.position.y+(scale.y*8) < position.y))
	can_jump = is_on_floor()
	if target: direction = -1 if target.position < position else 1
	else: direction = 0
	if not aggressive: direction *= -1
# Movement
	lerpWeight = delta*(acceleration if direction else friction)
	velocity.x = lerp(velocity.x, direction*speed, lerpWeight)
	move_and_slide()
# Size scaling
	if new_scale != scale: scale = scale.move_toward(new_scale, delta)
	if scale <= Vector2(0.25,0.25) and not dead: death("small")

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		match body.name:
			"spikes":
				emit_particle(eatParticles)
			"instakill":
				death()
func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		match body.name:
			"spikes":
				bleedParticles.restart()
				spike_1()
