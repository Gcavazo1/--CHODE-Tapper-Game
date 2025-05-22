extends Node

# Singleton instance reference
static var _instance

# Dictionary to store all achievements, keyed by ID
var achievements: Dictionary = {}
# Signal emitted when an achievement is unlocked
signal achievement_unlocked(achievement)

# Singleton getter
static func get_instance():
	return _instance

# Add all the achievements for the Genesis Tap demo
func _ready():
	# Store singleton instance
	_instance = self
	
	# Genesis Tap demo achievements
	_register_achievement("genesis_tap", "Genesis Tap", "Tap your way to 10 $GIRTH!")
	_register_achievement("first_evolution", "Veinous Veridian", "Evolve your $CHODE to the Veinous Veridian form!")
	_register_achievement("ultimate_evolution", "Cracked Core", "Reach the ultimate $CHODE evolution - Cracked Core!")
	
	# Milestone achievements
	_register_achievement("girth_50", "Modest Girther", "Reach 50 $GIRTH")
	_register_achievement("girth_100", "Growing Girther", "Reach 100 $GIRTH")
	_register_achievement("girth_150", "Substantial Girther", "Reach 150 $GIRTH")
	_register_achievement("girth_250", "Impressive Girther", "Reach 250 $GIRTH")
	_register_achievement("girth_500", "Mighty Girther", "Reach 500 $GIRTH")
	_register_achievement("girth_1000", "Legendary Girther", "Reach 1000 $GIRTH")
	
	# Mega Slap achievements
	_register_achievement("first_mega_slap", "Thunder Slapper", "Deliver your first Mighty Mega Slap!")
	_register_achievement("five_mega_slaps", "Slap Enthusiast", "Deliver 5 Mighty Mega Slaps!")
	_register_achievement("ten_mega_slaps", "Slap Master", "Deliver 10 Mighty Mega Slaps!")
	_register_achievement("mega_slap_girth_100", "Mega Girther", "Earn 100 $GIRTH through Mighty Mega Slaps")
	
	# Refactory period achievements
	_register_achievement("first_refactory_overcome", "Staying Power", "Push through your first refactory period!")
	_register_achievement("refactory_master", "Endurance Champion", "Overcome 5 refactory periods!")
	_register_achievement("refactory_legend", "Insatiable", "Conquer 10 refactory periods!")
	
	# G-spot Skill Game and GigaSlap achievements
	_register_achievement("first_giga_slap", "G-Spot Guru", "Successfully hit your first G-spot for a GigaSlap!")
	_register_achievement("giga_slap_streak_3", "Triple G-Spot", "Hit 3 G-spots in a row without missing!")
	_register_achievement("giga_slap_streak_5", "G-Spot Mastery", "Hit 5 G-spots in a row without missing!")
	_register_achievement("giga_slap_streak_10", "G-Spot Virtuoso", "Hit 10 G-spots in a row! You're a G-Spot Wizard!")
	_register_achievement("perfect_g_spot", "Bullseye!", "Hit the G-spot dead center for maximum pleasure!")
	_register_achievement("last_second_g_spot", "Edge Lord", "Hit the G-spot at the very last moment before timeout!")
	_register_achievement("g_spot_girth_500", "G-Spot Gold Digger", "Earn 500 $GIRTH through perfect G-spots!")
	_register_achievement("giga_slap_10", "G-Spot Explorer", "Successfully deliver 10 GigaSlaps!")
	_register_achievement("giga_slap_50", "G-Spot Commander", "Successfully deliver 50 GigaSlaps!")
	_register_achievement("giga_slap_clutch", "Clutch Performer", "Hit the G-spot while at less than 5% refactory decay!")
	_register_achievement("giga_slap_marathon", "Marathon Slapper", "Perform 5 GigaSlaps within 30 seconds!")
	
	# Load any previously unlocked achievements
	_load_achievements()

# Static method to unlock achievement by ID
static func unlock_achievement(id: String) -> bool:
	return get_instance().unlock_achievement_instance(id)

# Static method to get an achievement by ID
static func get_achievement(id: String) -> Achievement:
	return get_instance().get_achievement_instance(id)

# Static method to get all unlocked achievements
static func get_unlocked_achievements() -> Array:
	return get_instance().get_unlocked_achievements_instance()

# Static method to get all achievements
static func get_all_achievements() -> Array:
	return get_instance().get_all_achievements_instance()

# Register a new achievement
func _register_achievement(id: String, title: String, description: String, is_secret: bool = false) -> void:
	achievements[id] = Achievement.create(id, title, description, null, is_secret)

# Instance method to unlock an achievement by ID
func unlock_achievement_instance(id: String) -> bool:
	if achievements.has(id) and not achievements[id].is_unlocked:
		achievements[id].unlock()
		emit_signal("achievement_unlocked", achievements[id])
		_save_achievements()
		return true
	return false

# Instance method to get achievement by ID
func get_achievement_instance(id: String) -> Achievement:
	if achievements.has(id):
		return achievements[id]
	return null

# Instance method to get all unlocked achievements
func get_unlocked_achievements_instance() -> Array:
	var unlocked = []
	for achievement_id in achievements:
		if achievements[achievement_id].is_unlocked:
			unlocked.append(achievements[achievement_id])
	return unlocked

# Instance method to get all achievements (unlocked and locked)
func get_all_achievements_instance() -> Array:
	var all_achievements = []
	for achievement_id in achievements:
		all_achievements.append(achievements[achievement_id])
	return all_achievements

# Save achievements to user://achievements.json
func _save_achievements() -> void:
	var save_data = {}
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		if achievement.is_unlocked:
			save_data[achievement_id] = {
				"unlocked": true,
				"date": achievement.date_unlocked
			}
	
	var file = FileAccess.open("user://achievements.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

# Load achievements from user://achievements.json
func _load_achievements() -> void:
	if not FileAccess.file_exists("user://achievements.json"):
		return
		
	var file = FileAccess.open("user://achievements.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var save_data = json.data
			for achievement_id in save_data:
				if achievements.has(achievement_id):
					achievements[achievement_id].is_unlocked = save_data[achievement_id].unlocked
					achievements[achievement_id].date_unlocked = save_data[achievement_id].date 