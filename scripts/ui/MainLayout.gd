extends Control

# External scene references - None here anymore for UI components directly managed

# --- Core Component References (Still needed for manager initialization if not children of managers) ---
@onready var tapper_center_node = get_parent().get_node("TapperCenter")
@onready var girth_counter = get_parent().get_node("GirthCounterMainContainer/GirthCounter")
@onready var charge_meter = $Margin/MainHBox/CenterArea/HUDMessagesPanel/HUDSectionPanel/ChargeAndSkillMeterContainer/ChargeMeterContainer/ChargeMeter
@onready var skill_tap_meter = $Margin/MainHBox/CenterArea/HUDMessagesPanel/HUDSectionPanel/ChargeAndSkillMeterContainer/SkillTapMeter
@onready var tapper_area = tapper_center_node.get_node("TapperPanelContainer/TapperCenterNode2D/TapperArea") if tapper_center_node else null

# --- Manager Node References ---
@onready var ui_navigation_manager = $UINavigationManager
@onready var achievement_ui_manager = $AchievementUIManager
@onready var effects_manager = $EffectsManager
@onready var skill_tap_ui_manager = $SkillTapUIManager
@onready var charge_meter_ui_manager = $ChargeMeterUIManager
@onready var game_stats_ui_manager = $GameStatsUIManager

# Style panel references for theme customization (Potentially moved to a ThemeManager or UIStyleManager later)
# These might still be useful if MainLayout directly applies overarching themes not handled by UINavigationManager
@onready var top_style_panel = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel
@onready var bottom_style_panel = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel
@onready var right_top_style_panel = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel
@onready var right_bottom_style_panel = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel

# --- References to UI elements for UINavigationManager ---
# Top left panel (Upgrades)
@onready var upgrade1_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/Upgrade1Button
@onready var upgrade2_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/Upgrade2Button
@onready var upgrade3_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/Upgrade3Button
@onready var upgrade4_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/Upgrade4Button
@onready var upgrade5_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/Upgrade5Button
@onready var upgrade6_button = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/Upgrade6Button
@onready var top_left_content_vbox = $Margin/MainHBox/LeftPanel/TopLeftContainer/TopStylePanel/TopContent/TopContentPanel/TopScrollContainer/TopContentVBox

# Bottom left panel (Achievements, Trophies, Blockchain)
@onready var achievements_button = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/AchievementsButton
@onready var trophies_button = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/TrophiesButton
@onready var blockchain_button = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/TabsHBox/RightColumn/BlockchainButton
@onready var achievements_content_vbox = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/AchievementsContentVBox
@onready var trophies_content_grid = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/TrophiesContentVBox
@onready var blockchain_content_vbox = $Margin/MainHBox/LeftPanel/BottomLeftContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/BlockchainContentVBox

# Top right panel (Store)
@onready var shop_tab1_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/ShopTab1Button
@onready var shop_tab2_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/ShopTab2Button
@onready var shop_tab3_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/LeftColumn/ShopTab3Button
@onready var shop_tab4_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/ShopTab4Button
@onready var shop_tab5_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/ShopTab5Button
@onready var shop_tab6_button = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TabsHBox/RightColumn/ShopTab6Button
@onready var store_content_vbox = $Margin/MainHBox/RightPanel/TopRightContainer/TopStylePanel/TopContent/TopContentPanel/TopScrollContainer/StoreContentVBox

# Bottom right panel (Settings, Stats, Info)
@onready var settings_button = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/SettingsButton
@onready var stats_button = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/TabsHBox/LeftColumn/StatsButton
@onready var info_button = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/TabsHBox/RightColumn/InfoButton
@onready var settings_content_vbox = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/SettingsContentVBox
@onready var stats_content_vbox = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/StatsContentVBox
@onready var info_content_vbox = $Margin/MainHBox/RightPanel/BottomRightContainer/BottomStylePanel/BottomContent/BottomContentPanel/BottomScrollContainer/InfoContentVBox

# --- Signals from MainLayout (if any are still needed) ---
# (Most signals like charge_meter_ready/used, girth_counter_updated have been moved or their original purpose is now internal to managers)

# --- Obsolete State Variables (Moved to UINavigationManager) ---
# var current_left_tab = "upgrades"
# var current_right_tab = "store"
# var current_left_bottom_tab = "achievements"
# var current_right_bottom_tab = "settings"

func _ready():
	print("MainLayout: Ready")
	
	# Initialize UINavigationManager
	if ui_navigation_manager:
		var upgrade_btns = {
			"upgrade1": upgrade1_button, "upgrade2": upgrade2_button, "upgrade3": upgrade3_button,
			"upgrade4": upgrade4_button, "upgrade5": upgrade5_button, "upgrade6": upgrade6_button
		}
		var bottom_left_btns = {
			"achievements": achievements_button, "trophies": trophies_button, "blockchain": blockchain_button
		}
		var top_right_btns = {
			"store": shop_tab1_button, "premium": shop_tab2_button, "boosts": shop_tab3_button,
			"nft": shop_tab4_button, "skins": shop_tab5_button, "special": shop_tab6_button
		}
		var bottom_right_btns = {
			"settings": settings_button, "stats": stats_button, "info": info_button
		}
		ui_navigation_manager.initialize_navigation(
			upgrade_btns, top_left_content_vbox,
			bottom_left_btns, achievements_content_vbox, trophies_content_grid, blockchain_content_vbox,
			top_right_btns, store_content_vbox,
			bottom_right_btns, settings_content_vbox, stats_content_vbox, info_content_vbox
		)
	else:
		print("ERROR: MainLayout - UINavigationManager node not found!")

	# Initialize Achievement UI Manager
	if achievement_ui_manager:
		if is_instance_valid(tapper_area): # Ensure tapper_area is valid before passing
			achievement_ui_manager.initialize_achievements(tapper_area)
		else:
			achievement_ui_manager.initialize_achievements(null) # Pass null if tapper_area isn't valid, manager will warn
			print("WARNING: MainLayout - TapperArea node is not valid. AchievementUIManager might not function fully for popups from TapperArea.")
	else:
		print("ERROR: MainLayout - AchievementUIManager node not found!")

	# Initialize Effects Manager
	if effects_manager:
		if tapper_center_node:
			effects_manager.initialize_effects_manager(tapper_center_node)
		else:
			print("ERROR: MainLayout - TapperCenter node not found! Cannot initialize EffectsManager correctly.")
	else:
		print("ERROR: MainLayout - EffectsManager node not found!")

	# Initialize SkillTap UI Manager
	if skill_tap_ui_manager:
		if is_instance_valid(skill_tap_meter) and is_instance_valid(effects_manager) and is_instance_valid(tapper_area):
			skill_tap_ui_manager.initialize_manager(skill_tap_meter, effects_manager, tapper_area)
		else:
			print("ERROR: MainLayout - One or more dependencies for SkillTapUIManager are invalid! (SkillTapMeter, EffectsManager, or TapperArea)")
	else:
		print("ERROR: MainLayout - SkillTapUIManager node not found!")
		
	# Initialize ChargeMeter UI Manager
	if charge_meter_ui_manager:
		if is_instance_valid(charge_meter):
			charge_meter_ui_manager.initialize_manager(charge_meter)
		else:
			print("ERROR: MainLayout - ChargeMeter node is invalid, cannot initialize ChargeMeterUIManager.")
	else:
		print("ERROR: MainLayout - ChargeMeterUIManager node not found!")

	# Initialize GameStats UI Manager
	if game_stats_ui_manager:
		if is_instance_valid(girth_counter):
			game_stats_ui_manager.initialize_manager(girth_counter)
		else:
			print("ERROR: MainLayout - GirthCounter node is invalid, cannot initialize GameStatsUIManager.")
	else:
		print("ERROR: MainLayout - GameStatsUIManager node not found!")
	
	# --- Connect signals that MainLayout still directly mediates or needs awareness of (should be minimal now) ---

	# Debug tapper_center_node path
	print("Looking for TapperCenter node as a sibling...")
	if tapper_center_node:
		print("Found TapperCenter instance (as TapperCenter)!")
		if tapper_area: # Ensure tapper_area was found before trying to connect
			print("MainLayout: Found TapperArea, connecting its signals...")
			# TapperArea.floating_number_requested is connected to EffectsManager
			if effects_manager and tapper_area.has_signal("floating_number_requested"):
				if not tapper_area.is_connected("floating_number_requested", effects_manager._on_floating_number_requested):
					tapper_area.connect("floating_number_requested", effects_manager._on_floating_number_requested)
					print("MainLayout: Connected TapperArea.floating_number_requested to EffectsManager")
			# TapperArea.achievement_unlocked is connected to AchievementUIManager
			if achievement_ui_manager and tapper_area.has_signal("achievement_unlocked"):
				# AchievementUIManager now handles its own TapperArea signal connection internally 
				# in its initialize_achievements method, which receives tapper_area.
				# No explicit connection needed here anymore.
				pass 
		else:
			print("MainLayout: ERROR - TapperArea not found within TapperCenter! Cannot connect its signals.")
	else:
		print("ERROR: Could not find TapperCenter instance (TapperCenter) as a sibling!")
	
	# Connect ChargeMeter signals to ChargeMeterUIManager
	if charge_meter and charge_meter_ui_manager:
		if not charge_meter.is_connected("charge_ready", charge_meter_ui_manager._on_charge_ready):
			charge_meter.connect("charge_ready", charge_meter_ui_manager._on_charge_ready)
		if not charge_meter.is_connected("charge_used", charge_meter_ui_manager._on_charge_used):
			charge_meter.connect("charge_used", charge_meter_ui_manager._on_charge_used)
	
	# Connect SkillTapMeter signals to SkillTapUIManager
	if skill_tap_meter and skill_tap_ui_manager:
		if not skill_tap_meter.is_connected("giga_slap_success", skill_tap_ui_manager._on_giga_slap_success):
			skill_tap_meter.connect("giga_slap_success", skill_tap_ui_manager._on_giga_slap_success)
		if not skill_tap_meter.is_connected("giga_slap_failure", skill_tap_ui_manager._on_giga_slap_failure):
			skill_tap_meter.connect("giga_slap_failure", skill_tap_ui_manager._on_giga_slap_failure)
	
	# Connect to Global signals (delegated to appropriate managers)
	if Global:
		print("MainLayout: Connecting Global signals to respective managers...")
		# Global.girth_updated -> GameStatsUIManager
		if game_stats_ui_manager and not Global.is_connected("girth_updated", game_stats_ui_manager._on_global_girth_updated):
			Global.connect("girth_updated", game_stats_ui_manager._on_global_girth_updated)
			
		# Global.achievement_unlocked -> AchievementUIManager (handles its own connection)
		
		# Global.giga_slap_attempt_ready -> SkillTapUIManager
		if skill_tap_ui_manager and not Global.is_connected("giga_slap_attempt_ready", skill_tap_ui_manager._on_giga_slap_attempt_ready):
			Global.connect("giga_slap_attempt_ready", skill_tap_ui_manager._on_giga_slap_attempt_ready)
		
		# Initial girth display (now handled by GameStatsUIManager if it initializes with current value)
		# if game_stats_ui_manager and is_instance_valid(girth_counter): # GameStatsUIManager should handle this
		# 	game_stats_ui_manager.update_girth_display(Global.current_girth)
		# else:
		# 	push_warning("MainLayout: Could not set initial girth via GameStatsUIManager or GirthCounter.")

	else:
		print("MainLayout: ERROR - Global singleton not found!")
		
	_setup_styling_panels() # This might still be relevant for overall panel styles
		
	# AchievementManager.achievement_unlocked -> AchievementUIManager (handles its own connection)
	# No longer need to connect to AchievementManager directly here for the list update

func _setup_styling_panels():
	if top_style_panel and bottom_style_panel and right_top_style_panel and right_bottom_style_panel:
		pass # Add subtle glow effect or other runtime style adjustments if needed

func _process(delta):
	pass # Should be minimal or empty now

# --- Obsolete Functions (Moved to UINavigationManager or other managers) ---
# func _update_left_top_tab_content(): pass
# func _update_left_bottom_tab_content(): pass
# func _update_right_top_tab_content(): pass
# func _update_right_bottom_tab_content(): pass

# All specific signal handlers like _on_giga_slap_success, _on_charge_ready, etc., have been removed.
# All specific content update functions like update_girth_counter, etc., have been removed.

# This script is attached to the root MainLayout node. 
 
