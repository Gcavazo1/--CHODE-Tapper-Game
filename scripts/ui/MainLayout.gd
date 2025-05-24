extends Control

# External scene references
var floating_number_scene = preload("res://scenes/ui/components/FloatingNumber.tscn")

# Component references - updated for new structure where TapperCenter is a sibling
@onready var tapper_center_node = get_parent().get_node("TapperCenter") # The TapperCenter instance in Main.tscn is named "TapperCenter"
@onready var girth_counter = get_parent().get_node("GirthCounterMainContainer/GirthCounter") # GirthCounter is now directly in Main
@onready var charge_meter = $Margin/MainHBox/CenterArea/HUDMessagesPanel/HUDSectionPanel/ChargeAndSkillMeterContainer/ChargeMeterContainer/ChargeMeter
@onready var skill_tap_meter = $Margin/MainHBox/CenterArea/HUDMessagesPanel/HUDSectionPanel/ChargeAndSkillMeterContainer/SkillTapMeter
@onready var achievement_panel = $Margin/MainHBox/CenterArea/HUDMessagesPanel/HUDSectionPanel/NotificationsContainer/AchievementPanel
@onready var tapper_area_panel = $Margin/MainHBox/CenterArea/TapperAreaPanel
@onready var tapper_area = tapper_center_node.get_node("TapperPanelContainer/TapperCenterNode2D/TapperArea") if tapper_center_node else null

# Top left panel tab references
@onready var upgrade1_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/Upgrade1Button
@onready var upgrade2_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/Upgrade2Button
@onready var upgrade3_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/Upgrade3Button
@onready var upgrade4_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/Upgrade4Button
@onready var upgrade5_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/Upgrade5Button
@onready var upgrade6_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/Upgrade6Button
@onready var top_content_vbox = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TopContentPanel/TopScrollContainer/TopContentVBox

# Bottom left panel tab references
@onready var achievements_button = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/AchievementsButton
@onready var trophies_button = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/TrophiesButton
@onready var blockchain_button = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/TabsHBox/RightColumn/BlockchainButton
@onready var achievements_content = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/AchievementsContentVBox
@onready var trophies_content = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/TrophiesContentVBox
@onready var blockchain_content = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/BlockchainContentVBox

# Top right panel tab references
@onready var shop_tab1_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/ShopTab1Button
@onready var shop_tab2_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/ShopTab2Button
@onready var shop_tab3_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/ShopTab3Button
@onready var shop_tab4_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/ShopTab4Button
@onready var shop_tab5_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/ShopTab5Button
@onready var shop_tab6_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/ShopTab6Button
@onready var store_content = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TopContentPanel/TopScrollContainer/StoreContentVBox

# Bottom right panel tab references
@onready var settings_button = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/SettingsButton
@onready var stats_button = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/StatsButton
@onready var info_button = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/TabsHBox/RightColumn/InfoButton
@onready var settings_content = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/SettingsContentVBox
@onready var stats_content = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/StatsContentVBox
@onready var info_content = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/InfoContentVBox

# Style panel references for theme customization
@onready var top_style_panel = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel
@onready var bottom_style_panel = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel
@onready var right_top_style_panel = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel
@onready var right_bottom_style_panel = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel

# Neon light reference and properties
# @onready var neon_sign_right = $Margin/MainHBox/CenterArea/TapperAreaPanel/TapperAreaBG/NeonLightsContainer/NeonSignRightSide
# var neon_pulse_time: float = 0.0
# var neon_pulse_speed: float = 0.6  # Seconds per complete pulse cycle
# var neon_min_energy: float = 0.75
# var neon_max_energy: float = 2.75

# Left neon light reference and properties
# @onready var neon_sign_left = $Margin/MainHBox/CenterArea/TapperAreaPanel/TapperAreaBG/NeonLightsContainer/NeonSignLeftSide
# var neon_left_pulse_time: float = 0.0
# var neon_left_pulse_speed: float = 0.8  # 2 seconds per cycle (1/2)
# var neon_left_min_energy: float = 0.55
# var neon_left_max_energy: float = 1.5

# Signal for when the $GIRTH counter is updated
signal girth_counter_updated(new_value)
# Signal for charge meter states
signal charge_meter_ready
signal charge_meter_used

# Achievement item scene reference
var achievement_item_scene = preload("res://scenes/ui/components/AchievementItem.tscn")

var current_left_tab = "upgrades"
var current_right_tab = "store"
var current_left_bottom_tab = "achievements"
var current_right_bottom_tab = "settings"

func _ready():
	print("MainLayout: Ready")
	
	# Debug tapper_center_node path
	print("Looking for TapperCenter node as a sibling...")
	if tapper_center_node:
		print("Found TapperCenter instance (as TapperCenter)!")
	else:
		print("ERROR: Could not find TapperCenter instance (TapperCenter) as a sibling!")
		
	# Connect tab button signals
	_connect_tab_buttons()
	
	# Debug neon light node path
	# print("Searching for neon light node...")
	# var neon_node = get_node_or_null("Margin/MainHBox/CenterArea/TapperAreaPanel/NeonLightsContainer/NeonSignRightSide")
	# if neon_node:
		# print("Found neon light node! Initial energy: ", neon_node.energy)
		
		# Optional - set the neon_sign_right variable directly
		# if neon_sign_right == null:
			# neon_sign_right = neon_node
	# else:
		# print("NEON LIGHT NODE NOT FOUND. Trying alternative path...")
		
		# Try alternative paths to locate the node
		# var container = get_node_or_null("Margin/MainHBox/CenterArea/TapperAreaPanel/NeonLightsContainer")
		# if container:
			# print("Found NeonLightsContainer. Children: ", container.get_child_count())
			# for i in range(container.get_child_count()):
				# print("Child ", i, ": ", container.get_child(i).name)
				# if container.get_child(i) is PointLight2D:
					# print("Found PointLight2D child: ", container.get_child(i).name)
		# else:
			# print("Could not find NeonLightsContainer")
	
	# Connect to directly instanced TapperArea signals
	if tapper_area:
		print("MainLayout: Found TapperArea, connecting signals")
		if tapper_area.has_signal("floating_number_requested"):
			# Disconnect first to avoid duplicate connections if reconnecting
			if tapper_area.is_connected("floating_number_requested", _on_floating_number_requested):
				tapper_area.disconnect("floating_number_requested", _on_floating_number_requested)
			tapper_area.connect("floating_number_requested", _on_floating_number_requested)
			print("MainLayout: Connected to floating_number_requested signal from TapperArea")
		else:
			print("MainLayout: WARNING - TapperArea does not have floating_number_requested signal")
		
		if tapper_area.has_signal("achievement_unlocked"):
			if tapper_area.is_connected("achievement_unlocked", _on_achievement_unlocked):
				tapper_area.disconnect("achievement_unlocked", _on_achievement_unlocked)
			tapper_area.connect("achievement_unlocked", _on_achievement_unlocked)
			print("MainLayout: Connected to achievement_unlocked signal from TapperArea")
	else:
		print("MainLayout: ERROR - TapperArea not found!")
	
	# Connect component signals
	if charge_meter:
		charge_meter.charge_ready.connect(_on_charge_ready)
		charge_meter.charge_used.connect(_on_charge_used)
	
	# Connect SkillTapMeter signals
	if skill_tap_meter:
		skill_tap_meter.giga_slap_success.connect(_on_giga_slap_success)
		skill_tap_meter.giga_slap_failure.connect(_on_giga_slap_failure)
	else:
		print("MainLayout: ERROR - SkillTapMeter not found!")
	
	# Connect to Global signals
	if Global:
		print("MainLayout: Connected to Global signals")
		Global.girth_updated.connect(_on_girth_updated)
		# Connect to Global's achievement signal as a fallback for legacy code
		Global.achievement_unlocked.connect(_on_achievement_unlocked)
		Global.giga_slap_attempt_ready.connect(_on_giga_slap_attempt_ready)
		# Initial display
		update_girth_counter(Global.current_girth)
	else:
		print("MainLayout: ERROR - Global singleton not found!")
		
	# Initialize panels with some visual styling effects
	_setup_styling_panels()
		
	# Set initial tab selections
	_show_achievements_content()
	_show_store_content()
	_show_settings_content()

	# Connect to AchievementManager signals
	await get_tree().process_frame  # Wait for AchievementManager to be ready
	if AchievementManager.get_instance():
		AchievementManager.get_instance().achievement_unlocked.connect(_on_achievement_manager_achievement_unlocked)
		# Initial achievements display
		_update_achievements_panel()

# Set up styling for the panel containers
func _setup_styling_panels():
	if top_style_panel and bottom_style_panel and right_top_style_panel and right_bottom_style_panel:
		# Add subtle glow effect or other runtime style adjustments if needed
		pass

# Connect tab button signals
func _connect_tab_buttons():
	# Left Panel - Top tabs (upgrades)
	if upgrade1_button:
		upgrade1_button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade1"))
	if upgrade2_button:
		upgrade2_button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade2"))
	if upgrade3_button:
		upgrade3_button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade3"))
	if upgrade4_button:
		upgrade4_button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade4"))
	if upgrade5_button:
		upgrade5_button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade5"))
	if upgrade6_button:
		upgrade6_button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade6"))
	
	# Left Panel - Bottom tabs
	if achievements_button:
		achievements_button.pressed.connect(_on_left_bottom_button_pressed.bind("achievements"))
	if trophies_button:
		trophies_button.pressed.connect(_on_left_bottom_button_pressed.bind("trophies"))
	if blockchain_button:
		blockchain_button.pressed.connect(_on_left_bottom_button_pressed.bind("blockchain"))
		
	# Right Panel - Top tabs (shop)
	if shop_tab1_button:
		shop_tab1_button.pressed.connect(_on_right_top_button_pressed.bind("store"))
	if shop_tab2_button:
		shop_tab2_button.pressed.connect(_on_right_top_button_pressed.bind("premium"))
	if shop_tab3_button:
		shop_tab3_button.pressed.connect(_on_right_top_button_pressed.bind("boosts"))
	if shop_tab4_button:
		shop_tab4_button.pressed.connect(_on_right_top_button_pressed.bind("nft"))
	if shop_tab5_button:
		shop_tab5_button.pressed.connect(_on_right_top_button_pressed.bind("skins"))
	if shop_tab6_button:
		shop_tab6_button.pressed.connect(_on_right_top_button_pressed.bind("special"))
	
	# Right Panel - Bottom tabs (settings)
	if settings_button:
		settings_button.pressed.connect(_on_right_bottom_button_pressed.bind("settings"))
	if stats_button:
		stats_button.pressed.connect(_on_right_bottom_button_pressed.bind("stats"))
	if info_button:
		info_button.pressed.connect(_on_right_bottom_button_pressed.bind("info"))

# Tab content switching functions - Left Panel
func _show_achievements_content():
	achievements_content.visible = true
	trophies_content.visible = false
	blockchain_content.visible = false
	
	# Visual indication of selected tab
	achievements_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	trophies_button.remove_theme_color_override("font_color")
	blockchain_button.remove_theme_color_override("font_color")

func _show_trophies_content():
	achievements_content.visible = false
	trophies_content.visible = true
	blockchain_content.visible = false
	
	# Visual indication of selected tab
	achievements_button.remove_theme_color_override("font_color")
	trophies_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	blockchain_button.remove_theme_color_override("font_color")

func _show_blockchain_content():
	achievements_content.visible = false
	trophies_content.visible = false
	blockchain_content.visible = true
	
	# Visual indication of selected tab
	achievements_button.remove_theme_color_override("font_color")
	trophies_button.remove_theme_color_override("font_color")
	blockchain_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))

# Tab content switching functions - Right Panel Top (Shop)
func _show_store_content():
	# For now, we just have the store content
	# In the future, we'll have different content VBoxes to show/hide
	
	# Visual indication of selected tab
	shop_tab1_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	shop_tab2_button.remove_theme_color_override("font_color")
	shop_tab3_button.remove_theme_color_override("font_color")
	shop_tab4_button.remove_theme_color_override("font_color")
	shop_tab5_button.remove_theme_color_override("font_color")
	shop_tab6_button.remove_theme_color_override("font_color")
	
	# Update content text
	_update_shop_content("Storefront: Regular items will be available here")

func _show_premium_content():
	# Visual indication of selected tab
	shop_tab1_button.remove_theme_color_override("font_color")
	shop_tab2_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	shop_tab3_button.remove_theme_color_override("font_color")
	shop_tab4_button.remove_theme_color_override("font_color")
	shop_tab5_button.remove_theme_color_override("font_color")
	shop_tab6_button.remove_theme_color_override("font_color")
	
	# Update content text
	_update_shop_content("Premium items and subscriptions will be available here")

func _show_boosts_content():
	# Visual indication of selected tab
	shop_tab1_button.remove_theme_color_override("font_color")
	shop_tab2_button.remove_theme_color_override("font_color")
	shop_tab3_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	shop_tab4_button.remove_theme_color_override("font_color")
	shop_tab5_button.remove_theme_color_override("font_color")
	shop_tab6_button.remove_theme_color_override("font_color")
	
	# Update content text
	_update_shop_content("Temporary boosts and power-ups will be sold here")

func _show_nft_content():
	# Visual indication of selected tab
	shop_tab1_button.remove_theme_color_override("font_color")
	shop_tab2_button.remove_theme_color_override("font_color")
	shop_tab3_button.remove_theme_color_override("font_color")
	shop_tab4_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	shop_tab5_button.remove_theme_color_override("font_color")
	shop_tab6_button.remove_theme_color_override("font_color")
	
	# Update content text
	_update_shop_content("NFT collectibles and blockchain items will be available here")

func _show_skins_content():
	# Visual indication of selected tab
	shop_tab1_button.remove_theme_color_override("font_color")
	shop_tab2_button.remove_theme_color_override("font_color")
	shop_tab3_button.remove_theme_color_override("font_color")
	shop_tab4_button.remove_theme_color_override("font_color")
	shop_tab5_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	shop_tab6_button.remove_theme_color_override("font_color")
	
	# Update content text
	_update_shop_content("Visual customizations and skins will be sold here")

func _show_special_content():
	# Visual indication of selected tab
	shop_tab1_button.remove_theme_color_override("font_color")
	shop_tab2_button.remove_theme_color_override("font_color")
	shop_tab3_button.remove_theme_color_override("font_color")
	shop_tab4_button.remove_theme_color_override("font_color")
	shop_tab5_button.remove_theme_color_override("font_color")
	shop_tab6_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	
	# Update content text
	_update_shop_content("Limited time and special offers will appear here")

# Tab content switching functions - Right Panel Bottom (Settings)
func _show_settings_content():
	settings_content.visible = true
	stats_content.visible = false
	info_content.visible = false
	
	# Visual indication of selected tab
	settings_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	stats_button.remove_theme_color_override("font_color")
	info_button.remove_theme_color_override("font_color")

func _show_stats_content():
	settings_content.visible = false
	stats_content.visible = true
	info_content.visible = false
	
	# Visual indication of selected tab
	settings_button.remove_theme_color_override("font_color")
	stats_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	info_button.remove_theme_color_override("font_color")

func _show_info_content():
	settings_content.visible = false
	stats_content.visible = false
	info_content.visible = true
	
	# Visual indication of selected tab
	settings_button.remove_theme_color_override("font_color")
	stats_button.remove_theme_color_override("font_color")
	info_button.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))

# Upgrade tab button handlers
func _on_upgrade_button_pressed(tab_name):
	current_left_tab = tab_name
	_update_left_top_tab_content()

func _on_left_bottom_button_pressed(tab_name):
	current_left_bottom_tab = tab_name
	_update_left_bottom_tab_content()

func _on_right_top_button_pressed(tab_name):
	current_right_tab = tab_name
	_update_right_top_tab_content()

func _on_right_bottom_button_pressed(tab_name):
	current_right_bottom_tab = tab_name
	_update_right_bottom_tab_content()

# Update the upgrade content area
func _update_upgrade_content(content_text: String):
	# Clear existing content
	for child in top_content_vbox.get_children():
		child.queue_free()
	
	# Add new content
	var label = Label.new()
	label.text = content_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = 3  # Enable text wrapping
	label.add_theme_font_override("font", load("res://assets/fonts/BrokenConsoleBold.ttf"))
	top_content_vbox.add_child(label)

# Update the shop content area
func _update_shop_content(content_text: String):
	# Clear existing content
	for child in store_content.get_children():
		child.queue_free()
	
	# Add new content
	var label = Label.new()
	label.text = content_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = 3  # Enable text wrapping
	label.add_theme_font_override("font", load("res://assets/fonts/BrokenConsoleBold.ttf"))
	store_content.add_child(label)

# Handle neon light pulsing in _process
func _process(delta):
	# --- Moved to TapperCenter.gd ---
	# Update neon pulse time
	# neon_pulse_time += delta
	# neon_left_pulse_time += delta
	
	# Find neon light if reference is null
	# if neon_sign_right == null:
		# neon_sign_right = get_node_or_null("Margin/MainHBox/CenterArea/TapperAreaPanel/TapperAreaBG/NeonLightsContainer/NeonSignRightSide")
		# if neon_sign_right:
			# print("Found neon light in _process!")
	# if neon_sign_left == null:
		# neon_sign_left = get_node_or_null("Margin/MainHBox/CenterArea/TapperAreaPanel/TapperAreaBG/NeonLightsContainer/NeonSignLeftSide")
		# if neon_sign_left:
			# print("Found left neon light in _process!")
	
	# Animate neon light energy if reference exists
	# if neon_sign_right:
		# Calculate pulse value (0 to 1 to 0) using sine wave
		# var pulse_factor = (sin(neon_pulse_time * PI * neon_pulse_speed) + 1) / 2
		# Apply energy value between min and max
		# neon_sign_right.energy = lerp(neon_min_energy, neon_max_energy, pulse_factor)
	# if neon_sign_left:
		# Calculate pulse value (0 to 1 to 0) using sine wave
		# var left_pulse_factor = (sin(neon_left_pulse_time * PI * neon_left_pulse_speed) + 1) / 2
		# Apply energy value between min and max
		# neon_sign_left.energy = lerp(neon_left_min_energy, neon_left_max_energy, left_pulse_factor)
	pass # Add pass if _process becomes empty after moving code

# Called to update the $GIRTH counter
func update_girth_counter(value: int) -> void:
	if girth_counter:
		girth_counter.update_girth(value)
	emit_signal("girth_counter_updated", value)

# Show an achievement notification
func show_achievement(title: String, description: String, duration: float = 3.0) -> void:
	if achievement_panel:
		achievement_panel.show_achievement(title, description, duration)

# Create a floating number at the specified position
func spawn_floating_number(global_tap_pos: Vector2, value: String = "+1", duration: float = 1.5) -> Node:
	if floating_number_scene and tapper_center_node: # Check tapper_center_node
		var instance = floating_number_scene.instantiate()
		
		# Add to TapperCenter first, so global_position can be set correctly
		tapper_center_node.add_child(instance)

		# Set the global position of the instance.
		# Godot will automatically calculate the correct local instance.position.
		instance.global_position = global_tap_pos

		# Now, if we want to apply a local offset (e.g., for the random scatter)
		# we can add to the now-correct local position.
		instance.position += Vector2(randf_range(-20, 20), randf_range(-40, -20))

		instance.value = value # Make sure this is a property the FloatingNumber script uses
		
		if duration != 1.5:
			# Ensure the path to AnimationTimer is correct within FloatingNumber.tscn
			var anim_timer = instance.get_node_or_null("AnimationTimer") 
			if anim_timer:
				anim_timer.wait_time = duration
			else:
				push_error("FloatingNumber is missing AnimationTimer node!")
		
		# If set_value isn't a direct property, ensure it's called if it exists
		if instance.has_method("set_value"):
			instance.set_value(value)
		
		return instance
	else:
		if not tapper_center_node:
			push_error("MainLayout: TapperCenter node not found, cannot spawn floating number.")
		if not floating_number_scene:
			push_error("MainLayout: FloatingNumber scene not loaded.")
	return null

# Use the charge meter's charge
func use_charge() -> bool:
	# This is now handled directly by Global, but kept for API compatibility
	return Global.is_mega_slap_primed

# Get the current charge percentage
func get_charge_percentage() -> float:
	if charge_meter:
		return charge_meter.get_charge_percentage()
	return 0.0

# Handler for when the Global singleton updates the GIRTH value
func _on_girth_updated(value):
	update_girth_counter(value)
	
	# You could also implement milestone notifications here
	# For example, special messages at certain GIRTH thresholds

# Handler for when a floating number is requested
func _on_floating_number_requested(value, position):
	spawn_floating_number(position, value)

# Handler for when an achievement is unlocked
func _on_achievement_unlocked(title, description, duration = 3.0):
	show_achievement(title, description, duration)
	
# Charge meter signal handlers
func _on_charge_ready():
	emit_signal("charge_meter_ready")
	# Potentially, we could trigger the GigaSlap attempt immediately when charge is ready
	# if we want it to be an automatic chance. For now, let TapperArea manage the trigger via player tap.
	
func _on_charge_used():
	emit_signal("charge_meter_used")

# SkillTapMeter signal handlers
func _on_giga_slap_attempt_ready():
	if skill_tap_meter:
		print("MainLayout: Giga Slap attempt ready, showing SkillTapMeter.")
		skill_tap_meter.show_and_start()

func _on_giga_slap_success():
	print("MainLayout: Giga Slap success! Instructing Global.")
	Global.increment_girth(Global.GIGA_SLAP_MULTIPLIER, true)
	Global.update_charge() # Reset charge meter after Giga Slap
	# Optional: Add specific floating text for Giga Slap success from MainLayout
	if tapper_area:
		tapper_area.emit_signal("floating_number_requested", "GIGA SLAP!", tapper_area.global_position - Vector2(0,40))
		tapper_area.emit_signal("floating_number_requested", "+" + str(Global.GIRTH_PER_TAP * Global.GIGA_SLAP_MULTIPLIER), tapper_area.global_position)

func _on_giga_slap_failure(timed_out: bool):
	print("MainLayout: Giga Slap failed. Timed out: ", timed_out)
	if timed_out:
		Global.giga_slap_timed_out() # Global handles charge reset and signal
		# Optional: Floating text for timeout
		if tapper_area:
			tapper_area.emit_signal("floating_number_requested", "TOO SLOW!", tapper_area.global_position - Vector2(0,40))
			tapper_area.emit_signal("floating_number_requested", "CHARGE LOST!", tapper_area.global_position)
	else: # Player clicked but missed
		print("MainLayout: Giga Slap missed. Performing normal Mega Slap.")
		Global.increment_girth(Global.MEGA_SLAP_MULTIPLIER, false)
		Global.update_charge() # Reset charge meter after normal Mega Slap
		# Optional: Floating text for missed Giga Slap (resulting in Mega Slap)
		if tapper_area:
			tapper_area.emit_signal("floating_number_requested", "MISS! (Mega Slap)", tapper_area.global_position - Vector2(0,40))
			tapper_area.emit_signal("floating_number_requested", "+" + str(Global.GIRTH_PER_TAP * Global.MEGA_SLAP_MULTIPLIER), tapper_area.global_position)

# --- For Genesis Tap Demo ---
# These methods are for the Genesis Tap Demo to connect with the game's core systems
# They'll be expanded or replaced in the full MVP implementation

func get_skill_tap_meter_node():
	return skill_tap_meter

# Update achievements panel with current achievements
func _update_achievements_panel():
	# Clear existing content
	for child in achievements_content.get_children():
		child.queue_free()
	
	# Add achievements header
	var header = Label.new()
	header.text = "YOUR ACHIEVEMENTS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", load("res://assets/fonts/BrokenConsoleBold.ttf"))
	header.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	achievements_content.add_child(header)
	
	# Get unlocked achievements from manager
	var unlocked_achievements = AchievementManager.get_unlocked_achievements()
	
	# If no achievements, show message
	if unlocked_achievements.is_empty():
		var no_achievements_label = Label.new()
		no_achievements_label.text = "No achievements unlocked yet.\nKeep tapping that $CHODE!"
		no_achievements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_achievements_label.autowrap_mode = true
		no_achievements_label.add_theme_font_override("font", load("res://assets/fonts/BrokenConsoleBold.ttf"))
		achievements_content.add_child(no_achievements_label)
		return
	
	# Add achievement items for each unlocked achievement
	for achievement in unlocked_achievements:
		var achievement_item = achievement_item_scene.instantiate()
		achievements_content.add_child(achievement_item)
		achievement_item.setup(achievement)
		achievement_item.achievement_selected.connect(_on_achievement_selected)
	
	# Add spacer at bottom
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	achievements_content.add_child(spacer)

# Called when an achievement is selected from the list
func _on_achievement_selected(achievement_id):
	var achievement = AchievementManager.get_achievement(achievement_id)
	if achievement and achievement.is_unlocked:
		show_achievement(achievement.title, achievement.description, 3.0)

# Called when AchievementManager unlocks a new achievement
func _on_achievement_manager_achievement_unlocked(achievement):
	# Update the achievements panel
	_update_achievements_panel()

# This script is attached to the root MainLayout node. 

func _update_left_top_tab_content():
	# Just a placeholder, this would be implemented with actual upgrade content
	top_content_vbox.get_node("UpgradeContent").text = "Selected upgrade: " + current_left_tab

func _update_left_bottom_tab_content():
	# Toggle visibility of the different content containers
	achievements_content.visible = current_left_bottom_tab == "achievements"
	trophies_content.visible = current_left_bottom_tab == "trophies"
	blockchain_content.visible = current_left_bottom_tab == "blockchain"

func _update_right_top_tab_content():
	# Just a placeholder, this would be implemented with actual store content
	store_content.get_node("StoreContentLabel").text = "Selected store tab: " + current_right_tab

func _update_right_bottom_tab_content():
	# Toggle visibility of the different content containers
	settings_content.visible = current_right_bottom_tab == "settings"
	stats_content.visible = current_right_bottom_tab == "stats"
	info_content.visible = current_right_bottom_tab == "info"

# --- Rat Spawning Logic Removed ---

# This script is attached to the root MainLayout node. 
 
