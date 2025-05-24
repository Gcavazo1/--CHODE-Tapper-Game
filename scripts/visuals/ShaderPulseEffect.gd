extends Node

# Animation properties for shader pulsing
var shader_pulse_time: float = 0.0
var shader_pulse_speed: float = 0.5  # Adjust for faster/slower pulsing
var min_intensity: float = 0.5       # Minimum light intensity
var max_intensity: float = 2.0       # Maximum light intensity

# The node with the shader material
@export var target_node: Node
@export var shader_param_name: String = "light_intensity"
@export_range(0.1, 3.0) var pulse_speed: float = 0.5
@export_range(0.0, 1.0) var min_value: float = 0.5
@export_range(1.0, 5.0) var max_value: float = 2.0

# Reference to the shader material
var shader_material: ShaderMaterial

func _ready():
	# Get the shader material from the target node
	if target_node and target_node.material:
		shader_material = target_node.material as ShaderMaterial
		print("ShaderPulseEffect: Found shader material on ", target_node.name)
		
		# Initialize with custom values if set
		shader_pulse_speed = pulse_speed
		min_intensity = min_value
		max_intensity = max_value
	else:
		push_error("ShaderPulseEffect: Target node or material not found")

func _process(delta):
	if shader_material:
		# Update pulse time
		shader_pulse_time += delta
		
		# Calculate pulse factor (0 to 1)
		var pulse_factor = (sin(shader_pulse_time * PI * shader_pulse_speed) + 1) / 2
		
		# Apply to shader parameter
		shader_material.set_shader_parameter(shader_param_name, lerp(min_intensity, max_intensity, pulse_factor)) 