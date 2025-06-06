class_name Core extends Node

enum State {INIT, WELCOME, WAITING_PORT, LOADING, PLAYING_SOLO, PLAYING_ONLINE, LEAVING, STOPPING_GAME, QUITTING}


enum PlaySoloMode {CREATION, JOIN}


var socket = WebSocketPeer.new()

var login = ""

var state = State.INIT

var server_process_state = Server.State.NOT_RUNNING



var stop_timer = 0
var close_timer = 0


var instantiate_timer = 0
var instantiate_limit = 0.01



var resync_timer = 0

@onready var asteroid_scene = load("res://scenes/asteroid.tscn")
@onready var planet_scene = load("res://scenes/planet.tscn")
@onready var moon_scene = load("res://scenes/moon.tscn")
@onready var star_scene = load("res://scenes/star.tscn")
@onready var player_scene = load("res://scenes/player.tscn")

@onready var server = get_tree().get_first_node_in_group("server")


@onready var container = get_tree().get_first_node_in_group("container") as Node3D
@onready var player = get_tree().get_first_node_in_group("player")

@onready var ui = get_tree().get_first_node_in_group("ui")


@onready var info = get_tree().get_first_node_in_group("info")

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
func _process(delta: float) -> void:
	if state == State.INIT:
		#refresh(State.WELCOME, network_state)
		return

	var sync_span = 1




			
func quit_now(wait_threads):
	server.quit()
	get_tree().quit()

func leave():
	if state == State.LEAVING || state == State.STOPPING_GAME:
		return
	assert(state != State.QUITTING && state != State.LOADING)
	print("Leaving...")
	socket.close()
	#refresh(State.LEAVING, network_state)


func quit() -> void:
	print("Quit called")
	if server.state == Server.State.RUNNING:
		server.stop_server()
		state = State.QUITTING
	else:
		print("Server not running, quitting now!")
		quit_now(false)

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
	
	server_uri = "%s://%s" % [protocol_str, host_str]
	server_port = int(port_str)

	connect_to_server()
