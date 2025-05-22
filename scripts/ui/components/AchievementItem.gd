extends PanelContainer

# Signals
signal achievement_selected(achievement_id)

# Node references
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var date_label = $MarginContainer/VBoxContainer/DateLabel
@onready var lock_icon = $MarginContainer/VBoxContainer/HBoxContainer/LockIcon
@onready var achievement_icon = $MarginContainer/VBoxContainer/HBoxContainer/AchievementIcon

# Achievement data
var achievement_id: String = ""
var is_unlocked: bool = false

# Setup the achievement item with data
func setup(achievement):
	achievement_id = achievement.id
	title_label.text = achievement.title
	description_label.text = achievement.description
	is_unlocked = achievement.is_unlocked
	
	# Set icon if available
	if achievement.icon != null:
		achievement_icon.texture = achievement.icon
	
	# Update UI based on unlock state
	if is_unlocked:
		if lock_icon:
			lock_icon.visible = false
		achievement_icon.modulate = Color(1, 1, 1, 1) # Full visibility
		title_label.modulate = Color(1, 0.9, 0.2, 1) # Gold color
		description_label.modulate = Color(1, 1, 1, 1) # Full visibility
		date_label.text = "Unlocked: " + achievement.date_unlocked
		date_label.visible = true
	else:
		# Achievement is locked
		if lock_icon:
			lock_icon.visible = true
		achievement_icon.modulate = Color(0.5, 0.5, 0.5, 0.5) # Dimmed
		
		if achievement.is_secret:
			title_label.text = "???"
			description_label.text = "Secret achievement"
			title_label.modulate = Color(0.7, 0.7, 0.7, 1) # Gray color
			description_label.modulate = Color(0.7, 0.7, 0.7, 1) # Gray color
		else:
			title_label.modulate = Color(0.7, 0.7, 0.7, 1) # Gray color
			description_label.modulate = Color(0.7, 0.7, 0.7, 1) # Gray color
		
		date_label.visible = false

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("achievement_selected", achievement_id) 