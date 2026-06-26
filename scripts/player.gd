extends CharacterBody2D

@export var maximum_speed         =   512 # pixels per second
@export var minimum_speed         =     8 # pixels per second
@export var positive_acceleration =  4096 # pixels per second per second
@export var negative_acceleration = -4096 # pixels per second per second

func _enter_tree() -> void:
  set_multiplayer_authority(name.to_int())

  # fixes weird spawning behavior with CharacterBody2D
  $CollisionShape2D.disabled = true
  await get_tree().create_timer(0.1).timeout
  $CollisionShape2D.disabled = false

func _physics_process(delta) -> void:
  if !is_multiplayer_authority():
    return
    
  var dy = Input.get_axis("move_north", "move_south")
  var dx = Input.get_axis("move_west" , "move_east" )

  var direction = Vector2(dx, dy).normalized()

  if direction: # some input is pressed
    # then apply positive acceleration toward maximum speed
    velocity += direction             * positive_acceleration * delta
    if velocity.length() > maximum_speed:
      velocity = velocity.normalized() * maximum_speed
  else:
    # then apply negative acceleration toward zero
    velocity += velocity.normalized() * negative_acceleration * delta
    if velocity.length() < minimum_speed:
      velocity = Vector2.ZERO

  move_and_slide()
