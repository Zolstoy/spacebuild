class_name Core extends Node

enum State {INIT, WELCOME, WAITING_PORT, LOADING, PLAYING_SOLO, PLAYING_ONLINE, LEAVING, STOPPING_GAME, QUITTING}
enum PlaySoloMode {CREATION, JOIN}

@onready var server = get_tree().get_first_node_in_group("server")
@onready var container = get_tree().get_first_node_in_group("container") as Node3D
@onready var network = get_tree().get_first_node_in_group("network") as Network
@onready var player = get_tree().get_first_node_in_group("player")
@onready var ui = get_tree().get_first_node_in_group("ui")

var login = ""
var state = State.INIT
var server_process_state = Server.State.NOT_RUNNING
var close_timer = 0
var resync_timer = 0

func switch(next_state: State) -> void:
	state = next_state
	#if new_state == State.WELCOME:
		#if state != State.WELCOME:
			#ui.reticle.set_visible(false)
			#playing_menu.set_visible(false)
			#var galactics = core.container.get_children()
			#for galactic in galactics:
				#core.container.remove_child(galactic)
		#else:
			#if dest_ui_welcome_state == WelcomeState.SOLO:
				#if core.state != core.State.WELCOME:
					#list_worlds()
				#if welcome_state != WelcomeState.SOLO:
					#play_button.set_disabled(true)
					#delete_button.set_disabled(true)
				#else:
					#play_button.set_disabled(selected_world == null)
					#delete_button.set_disabled(selected_world == null)
					#create_button.set_disabled(world_field.get_text().is_empty())
			#elif dest_ui_welcome_state == WelcomeState.ONLINE:
				#play_button.set_disabled(login_field.get_text().is_empty())
	#elif core.state == core.State.INIT:
		#if dest_ui_welcome_state == WelcomeState.SOLO:
				#list_worlds()
				#play_button.set_disabled(true)
	#welcome_state = dest_ui_welcome_state


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func _ready() -> void:

	get_tree().set_auto_accept_quit(false)
#
#func refresh(to_state, to_network_state) -> void:
	#if state != State.WELCOME && to_state == State.WELCOME:
		#container.remove_from_group("celestial")
		#bodies_infos.clear()
#
	#get_tree().get_first_node_in_group("modale").set_visible(to_state == State.WELCOME)
	#get_tree().get_first_node_in_group("title").set_visible(to_state == State.WELCOME)
	#get_tree().get_first_node_in_group("loading").set_visible(to_state == State.WAITING_PORT
								 #|| to_state == State.LOADING)
	#if to_state == State.WAITING_PORT:
		#get_tree().get_first_node_in_group("loading").set_text("Waiting server...")
	#elif to_state == State.LOADING:
		#get_tree().get_first_node_in_group("loading").set_text("Connecting...")
#
	#get_tree().get_first_node_in_group("ship").set_visible(to_state == State.PLAYING_SOLO || to_state == State.PLAYING_ONLINE)
	#get_tree().get_first_node_in_group("container").set_visible(to_state == State.PLAYING_SOLO || to_state == State.PLAYING_ONLINE)
#
	#ui.refresh(to_state, ui.welcome_state)
	#state = to_state
	##network_state = to_network_state
	#

func quit_now():
	server.quit()
	get_tree().quit()

func leave():
	if state == State.LEAVING || state == State.STOPPING_GAME:
		return
	assert(state != State.QUITTING && state != State.LOADING)
	print("Leaving...")
	network.socket.close()
	#refresh(State.LEAVING, network_state)


func quit() -> void:
	print("Quit called")
	if server.state == Server.State.RUNNING:
		server.stop_server()
		state = State.QUITTING
	else:
		print("Server not running, quitting now!")
		quit_now()

func play_solo(play_mode) -> void:
	var _output = []
	var world_name = ""
	if play_mode == PlaySoloMode.CREATION:
		world_name = ui.world_field.get_text()
	elif play_mode == PlaySoloMode.JOIN:
		world_name = ui.worlds_tree.get_selected().get_text(0)

	assert(!world_name.is_empty())
	server.launch(world_name)

func play_online() -> void:
	login = ui.login_field.get_text()
	if login.is_empty():
		ui.error_placeholder.set_text("Enter your login please")
		print("No login")
		ui.play_button.set_disabled(false)
		return

	var host_str = ui.host_field.get_text()
	if host_str.is_empty():
		host_str = "localhost"

	var port_str = ui.port_field.get_text()
	if port_str.is_empty():
		port_str = "2567"

	var protocol_str = "wss" if ui.encrypted_switch.is_pressed() else "ws"

	network.connect_to_server("%s://%s" % [protocol_str, host_str], int(port_str))
