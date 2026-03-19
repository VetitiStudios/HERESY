extends Control

@onready var speed_label = $"Speed Label"
@onready var accel_label = $"Acceleration Label"
@onready var walljump_label = $"WallJumps Label"

var player = null
var last_velocity := Vector3.ZERO

func _process(delta):
	if player == null:
		return

	var vel = player.velocity  
	vel.y = 0
	var speed = round(vel.length() * 100) / 100.0
	speed_label.text = "Speed: " + str(speed)
	var accel = round((player.velocity - last_velocity).length() / delta * 100) / 100.0
	accel_label.text = "Accel: " + str(accel)
	walljump_label.text = "Wall Jumps: " + str(player.REMAINING_WALL_JUMPS)
	last_velocity = player.velocity
