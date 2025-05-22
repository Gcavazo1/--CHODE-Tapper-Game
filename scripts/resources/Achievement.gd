class_name Achievement
extends Resource

@export var id: String = ""
@export var title: String = "Achievement"
@export var description: String = "Achievement description"
@export var icon: Texture2D
@export var is_secret: bool = false
@export var date_unlocked: String = "" # When unlocked, store the date string
@export var is_unlocked: bool = false

# Static methods to create achievement instances
static func create(p_id: String, p_title: String, p_description: String, p_icon: Texture2D = null, p_is_secret: bool = false) -> Achievement:
	var achievement = Achievement.new()
	achievement.id = p_id
	achievement.title = p_title
	achievement.description = p_description
	achievement.icon = p_icon
	achievement.is_secret = p_is_secret
	return achievement

# Mark the achievement as unlocked with the current date
func unlock() -> void:
	if not is_unlocked:
		is_unlocked = true
		# Store the current date as a string
		var date = Time.get_datetime_dict_from_system()
		date_unlocked = "%04d-%02d-%02d" % [date.year, date.month, date.day] 