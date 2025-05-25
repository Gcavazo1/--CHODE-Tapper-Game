extends Node

# Manages all UI tab navigation and content panel visibility.

# --- Dependencies (Injected by MainLayout.gd via initialize_navigation) ---

# Top-Left Panel (Upgrades)
var upgrade_buttons = {} # Dict: {"upgrade1": ButtonNode, ...}
var top_left_content_vbox # The VBoxContainer holding the UpgradeContent Label

# Bottom-Left Panel (Achievements, Trophies, Blockchain)
var bottom_left_buttons = {} # Dict: {"achievements": ButtonNode, ...}
var achievements_content_vbox # AchievementsContentVBox
var trophies_content_grid # TrophiesContentVBox (GridContainer)
var blockchain_content_vbox # BlockchainContentVBox

# Top-Right Panel (Store Tabs)
var top_right_buttons = {} # Dict: {"store": ButtonNode, ...} -> maps to ShopTab1Button etc.
var store_content_vbox # StoreContentVBox holding the StoreContentLabel

# Bottom-Right Panel (Settings, Stats, Info)
var bottom_right_buttons = {} # Dict: {"settings": ButtonNode, ...}
var settings_content_vbox # SettingsContentVBox
var stats_content_vbox # StatsContentVBox
var info_content_vbox # InfoContentVBox

# --- State Variables ---
var current_top_left_tab: String = "upgrade1" # Default active tab (corresponds to Upgrade1Button)
var current_bottom_left_tab: String = "achievements"
var current_top_right_tab: String = "store" # Default for ShopTab1Button
var current_bottom_right_tab: String = "settings"

# --- Initialization ---
func initialize_navigation(
		p_upgrade_buttons: Dictionary, p_top_left_vbox: Node,
		p_bottom_left_buttons: Dictionary, p_ach_vbox: Node, p_tro_grid: Node, p_bc_vbox: Node,
		p_top_right_buttons: Dictionary, p_store_vbox: Node,
		p_bottom_right_buttons: Dictionary, p_set_vbox: Node, p_stat_vbox: Node, p_inf_vbox: Node
	):
	print("UINavigationManager: Initializing...")

	# Assign dependencies
	upgrade_buttons = p_upgrade_buttons
	top_left_content_vbox = p_top_left_vbox
	
	bottom_left_buttons = p_bottom_left_buttons
	achievements_content_vbox = p_ach_vbox
	trophies_content_grid = p_tro_grid
	blockchain_content_vbox = p_bc_vbox
	
	top_right_buttons = p_top_right_buttons
	store_content_vbox = p_store_vbox
	
	bottom_right_buttons = p_bottom_right_buttons
	settings_content_vbox = p_set_vbox
	stats_content_vbox = p_stat_vbox
	info_content_vbox = p_inf_vbox

	# Connect signals for Top-Left buttons
	for button_keyName in upgrade_buttons: # e.g. "upgrade1", "upgrade2"
		var button_node = upgrade_buttons[button_keyName]
		if is_instance_valid(button_node) and button_node.has_signal("pressed"):
			if not button_node.is_connected("pressed", Callable(self, "_on_top_left_tab_selected").bind(button_keyName)):
				button_node.pressed.connect(Callable(self, "_on_top_left_tab_selected").bind(button_keyName))
		else:
			push_error("UINavigationManager: Invalid button or no 'pressed' signal for top-left button: " + button_keyName)

	# Connect signals for Bottom-Left buttons
	for button_keyName in bottom_left_buttons: # "achievements", "trophies", "blockchain"
		var button_node = bottom_left_buttons[button_keyName]
		if is_instance_valid(button_node) and button_node.has_signal("pressed"):
			if not button_node.is_connected("pressed", Callable(self, "_on_bottom_left_tab_selected").bind(button_keyName)):
				button_node.pressed.connect(Callable(self, "_on_bottom_left_tab_selected").bind(button_keyName))
		else:
			push_error("UINavigationManager: Invalid button or no 'pressed' signal for bottom-left button: " + button_keyName)

	# Connect signals for Top-Right buttons
	for button_keyName in top_right_buttons: # "store", "premium", etc.
		var button_node = top_right_buttons[button_keyName]
		if is_instance_valid(button_node) and button_node.has_signal("pressed"):
			if not button_node.is_connected("pressed", Callable(self, "_on_top_right_tab_selected").bind(button_keyName)):
				button_node.pressed.connect(Callable(self, "_on_top_right_tab_selected").bind(button_keyName))
		else:
			push_error("UINavigationManager: Invalid button or no 'pressed' signal for top-right button: " + button_keyName)
			
	# Connect signals for Bottom-Right buttons
	for button_keyName in bottom_right_buttons: # "settings", "stats", "info"
		var button_node = bottom_right_buttons[button_keyName]
		if is_instance_valid(button_node) and button_node.has_signal("pressed"):
			if not button_node.is_connected("pressed", Callable(self, "_on_bottom_right_tab_selected").bind(button_keyName)):
				button_node.pressed.connect(Callable(self, "_on_bottom_right_tab_selected").bind(button_keyName))
		else:
			push_error("UINavigationManager: Invalid button or no 'pressed' signal for bottom-right button: " + button_keyName)
			
	# Set initial visibility based on default states
	_update_top_left_content_visibility()
	_update_bottom_left_content_visibility()
	_update_top_right_content_visibility()
	_update_bottom_right_content_visibility()
	
	_apply_button_styling()
	print("UINavigationManager: Initialization complete. Buttons connected, initial content set.")

# --- Tab Selection Handlers ---
func _on_top_left_tab_selected(tab_key_name: String):
	if not upgrade_buttons.has(tab_key_name):
		push_error("UINavigationManager: Unknown top-left tab selected: " + tab_key_name)
		return
	current_top_left_tab = tab_key_name
	print("UINavigationManager: Top-left tab selected: %s" % tab_key_name)
	_update_top_left_content_visibility()
	_apply_button_styling()

func _on_bottom_left_tab_selected(tab_key_name: String):
	if not bottom_left_buttons.has(tab_key_name):
		push_error("UINavigationManager: Unknown bottom-left tab selected: " + tab_key_name)
		return
	current_bottom_left_tab = tab_key_name
	print("UINavigationManager: Bottom-left tab selected: %s" % tab_key_name)
	_update_bottom_left_content_visibility()
	_apply_button_styling()

func _on_top_right_tab_selected(tab_key_name: String):
	if not top_right_buttons.has(tab_key_name):
		push_error("UINavigationManager: Unknown top-right tab selected: " + tab_key_name)
		return
	
	# Track shop icon taps for achievement
	if tab_key_name == "store" and Global:
		Global.shop_icon_taps += 1
		
		# Unlock achievement when tapped enough times
		if Global.shop_icon_taps >= 25:
			AchievementManager.unlock_achievement("let_me_in")
		
		# First time viewing bazaar achievement
		if not Global.has_viewed_bazaar:
			Global.has_viewed_bazaar = true
			AchievementManager.unlock_achievement("window_shopper")
	
	current_top_right_tab = tab_key_name
	print("UINavigationManager: Top-right tab selected: %s" % tab_key_name)
	_update_top_right_content_visibility()
	_apply_button_styling()

func _on_bottom_right_tab_selected(tab_key_name: String):
	if not bottom_right_buttons.has(tab_key_name):
		push_error("UINavigationManager: Unknown bottom-right tab selected: " + tab_key_name)
		return
	current_bottom_right_tab = tab_key_name
	print("UINavigationManager: Bottom-right tab selected: %s" % tab_key_name)
	_update_bottom_right_content_visibility()
	_apply_button_styling()

# --- Content Update & Visibility Functions ---

func _update_top_left_content_visibility():
	# This panel currently has one shared content label based on MainLayout.tscn
	if is_instance_valid(top_left_content_vbox):
		var content_label = top_left_content_vbox.get_node_or_null("UpgradeContent")
		if is_instance_valid(content_label) and content_label is Label:
			# The key name for upgrade_buttons is like "upgrade1", "upgrade2", etc.
			var display_name = current_top_left_tab.capitalize()
			# If upgrade_buttons stores the actual button nodes, we can get their text
			if upgrade_buttons.has(current_top_left_tab) and is_instance_valid(upgrade_buttons[current_top_left_tab]):
				display_name = upgrade_buttons[current_top_left_tab].text
			content_label.text = "Selected: %s\n(Dynamic content for '%s' will appear here)" % [display_name, current_top_left_tab]
		else:
			push_warning("UINavigationManager: 'UpgradeContent' Label not found or not a Label in top_left_content_vbox.")
	else:
		push_error("UINavigationManager: top_left_content_vbox is not valid.")

func _update_bottom_left_content_visibility():
	if is_instance_valid(achievements_content_vbox): achievements_content_vbox.visible = (current_bottom_left_tab == "achievements")
	if is_instance_valid(trophies_content_grid): trophies_content_grid.visible = (current_bottom_left_tab == "trophies")
	if is_instance_valid(blockchain_content_vbox): blockchain_content_vbox.visible = (current_bottom_left_tab == "blockchain")

func _update_top_right_content_visibility():
	# This panel also has one shared content label based on MainLayout.tscn
	if is_instance_valid(store_content_vbox):
		var content_label = store_content_vbox.get_node_or_null("StoreContentLabel")
		if is_instance_valid(content_label) and content_label is Label:
			var display_name = current_top_right_tab.capitalize()
			if top_right_buttons.has(current_top_right_tab) and is_instance_valid(top_right_buttons[current_top_right_tab]):
				display_name = top_right_buttons[current_top_right_tab].text
			content_label.text = "Selected: %s\n(Dynamic content for '%s' will appear here)" % [display_name, current_top_right_tab]
		else:
			push_warning("UINavigationManager: 'StoreContentLabel' Label not found or not a Label in store_content_vbox.")
	else:
		push_error("UINavigationManager: store_content_vbox is not valid.")

func _update_bottom_right_content_visibility():
	if is_instance_valid(settings_content_vbox): settings_content_vbox.visible = (current_bottom_right_tab == "settings")
	if is_instance_valid(stats_content_vbox): stats_content_vbox.visible = (current_bottom_right_tab == "stats")
	if is_instance_valid(info_content_vbox): info_content_vbox.visible = (current_bottom_right_tab == "info")

# --- Button Styling --- 
func _apply_button_styling():
	_style_button_group(upgrade_buttons, current_top_left_tab)
	_style_button_group(bottom_left_buttons, current_bottom_left_tab)
	_style_button_group(top_right_buttons, current_top_right_tab)
	_style_button_group(bottom_right_buttons, current_bottom_right_tab)

func _style_button_group(buttons: Dictionary, active_tab_key: String):
	for btn_key_name in buttons:
		var btn_node = buttons[btn_key_name]
		if is_instance_valid(btn_node):
			# Example: Change modulate for active/inactive. 
			# More advanced styling could involve StyleBoxes or themes.
			if btn_key_name == active_tab_key:
				btn_node.modulate = Color.WHITE # Active
			else:
				btn_node.modulate = Color(0.7, 0.7, 0.7, 0.8) # Inactive
			# Consider adding a specific style for "pressed" or "hover" if not default

# Helper to print if nodes are valid for debugging
func _check_node_validity():
	print("--- UINavigationManager Node Validity Check ---")
	print("Upgrade Buttons:")
	for btn_name in upgrade_buttons: print("  %s: %s" % [btn_name, is_instance_valid(upgrade_buttons[btn_name])])
	print("Top-Left Content Container: %s" % is_instance_valid(top_left_content_vbox))
	
	print("Bottom-Left Buttons:")
	for btn_name in bottom_left_buttons: print("  %s: %s" % [btn_name, is_instance_valid(bottom_left_buttons[btn_name])])
	print("Achievements Panel: %s" % is_instance_valid(achievements_content_vbox))
	print("Trophies Panel: %s" % is_instance_valid(trophies_content_grid))
	print("Blockchain Panel: %s" % is_instance_valid(blockchain_content_vbox))

	print("Top-Right Buttons:")
	for btn_name in top_right_buttons: print("  %s: %s" % [btn_name, is_instance_valid(top_right_buttons[btn_name])])
	print("Top-Right Content Container: %s" % is_instance_valid(store_content_vbox))

	print("Bottom-Right Buttons:")
	for btn_name in bottom_right_buttons: print("  %s: %s" % [btn_name, is_instance_valid(bottom_right_buttons[btn_name])])
	print("Settings Panel: %s" % is_instance_valid(settings_content_vbox))
	print("Stats Panel: %s" % is_instance_valid(stats_content_vbox))
	print("Info Panel: %s" % is_instance_valid(info_content_vbox))
	print("--------------------------------------------")

# --- Button Click Handlers ---
func _on_button_click(button_key: String, button_group: Dictionary, button_group_name: String):
	var old_tab = ""
	
	# Update the active tab based on the button group
	if button_group_name == "top_left":
		old_tab = current_top_left_tab
		current_top_left_tab = button_key
		_update_top_left_content_visibility()
	elif button_group_name == "bottom_left":
		old_tab = current_bottom_left_tab
		current_bottom_left_tab = button_key
		_update_bottom_left_content_visibility()
	elif button_group_name == "top_right":
		old_tab = current_top_right_tab
		current_top_right_tab = button_key
		_update_top_right_content_visibility()
		
		# Track shop button clicks for achievements
		if button_key == "store" and Global and not Global.has_viewed_bazaar:
			# First time viewing the Girth Bazaar achievement
			Global.has_viewed_bazaar = true
			AchievementManager.unlock_achievement("window_shopper")
	elif button_group_name == "bottom_right":
		old_tab = current_bottom_right_tab
		current_bottom_right_tab = button_key
		_update_bottom_right_content_visibility()
	
	# Update button styling
	_apply_button_styling()
	
	print("UINavigationManager: Tab switched from '%s' to '%s' in %s panel" % [old_tab, button_key, button_group_name]) 