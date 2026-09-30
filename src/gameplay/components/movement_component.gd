class_name MovementComponent
extends Node
## Velocity for a CharacterBody2D: steering (accel/friction), impulses (knockback)
## and forced velocity (dashes, lunges). The owner calls physics_step() once per frame.

@export var body: CharacterBody2D
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0
## How fast knockback impulses fade (px/s^2).
@export var impulse_friction: float = 1100.0

var max_speed: float = 100.0
var speed_multiplier: float = 1.0

var _desired: Vector2 = Vector2.ZERO
var _speed_factor: float = 1.0
var _steer_velocity: Vector2 = Vector2.ZERO
var _impulse: Vector2 = Vector2.ZERO
var _forced: Vector2 = Vector2.ZERO
var _has_forced: bool = false


## Request movement for this frame. `direction` may be any length (clamped to 1).
func move(direction: Vector2, speed_factor: float = 1.0) -> void:
	_desired = direction.limit_length(1.0)
	_speed_factor = speed_factor


func stop_immediately() -> void:
	_desired = Vector2.ZERO
	_steer_velocity = Vector2.ZERO
	_impulse = Vector2.ZERO
	clear_forced()


func impulse(velocity: Vector2) -> void:
	_impulse += velocity


func set_forced(velocity: Vector2) -> void:
	_forced = velocity
	_has_forced = true


func clear_forced() -> void:
	if _has_forced:
		_has_forced = false
		_steer_velocity = _forced.limit_length(max_speed)


func has_forced() -> bool:
	return _has_forced


func physics_step(delta: float) -> void:
	if _has_forced:
		_steer_velocity = _forced
	else:
		var target := _desired * max_speed * speed_multiplier * _speed_factor
		var rate := acceleration if target != Vector2.ZERO else friction
		_steer_velocity = _steer_velocity.move_toward(target, rate * delta)
	_impulse = _impulse.move_toward(Vector2.ZERO, impulse_friction * delta)
	body.velocity = _steer_velocity + _impulse
	body.move_and_slide()
	_desired = Vector2.ZERO
	_speed_factor = 1.0
