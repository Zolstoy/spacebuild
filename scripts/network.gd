extends Node


var login_hash = {
	"Login": {
		"nickname": ""
	}
}

@onready var core = get_tree().get_first_node_in_group("core")

var state = State.Network.IDLE
var socket: WebSocketPeer = null
var close_timer: float = 0
var galactics = []

func _ready():
	set_process(false)

func _process(delta):
	var new_network_state = null
	var new_state = null
	socket.poll()

	var socket_state = socket.get_ready_state()
	if socket_state == WebSocketPeer.STATE_CLOSING:
		if core.state == State.Core.LEAVING:
			if close_timer == 0:
				print("Closing")
				new_network_state = State.Network.CLOSING
			if close_timer >= 0.5:
				socket = WebSocketPeer.new()
				set_process(false)
				if core.ui.welcome_state == core.ui.WelcomeState.SOLO && !OS.has_feature("web"):
					core.server.stop_server()
				else:
					new_state = State.Core.WELCOME
				close_timer = 0
			else:
				close_timer += delta

	elif socket_state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		socket = WebSocketPeer.new()
		new_network_state = State.Network.IDLE
		#if state == Core.State.PLAYING_SOLO:
			#stop_server()
		#else:
			#new_state = State.WELCOME
		close_timer = 0
		set_process(false)

	if socket_state == WebSocketPeer.STATE_OPEN:
		if state == State.Network.CONNECTING:
			print("Authenticating...")
			if core.ui.state == State.UI.MODAL_ONLINE:
				login_hash["Login"]["nickname"] = core.ui.login_field.get_text()
			else:
				login_hash["Login"]["nickname"] = "Player"
			if socket.send_text(JSON.stringify(login_hash)) != OK:
				print("Send error")
			else:
				new_network_state = State.Network.AUTHENTICATING

		elif state == State.Network.AUTHENTICATING:
			if socket.get_available_packet_count():
				var variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if variant["success"] == false:
					print("Login failure: %s" % variant["message"])
					core.ui.error_placeholder.set_text("Authentication failed: %s" % variant["message"])
					core.leave()
				else:
					print("Login success, id is %s" % variant["message"])
					core.spawner.set_process(true)
					core.player.set_process(true)
					core.player.set_process_input(true)
					core.ui.connecting.visible = false
					#core.player.reticle.visible = true
					core.player.visible = true
					core.ui.title.visible = false
					new_network_state = State.Network.WAITING_GAMEINFO
					if core.server.state == State.Server.RUNNING:
						new_state = State.Core.PLAYING_SOLO
					else:
						new_state = State.Core.PLAYING_ONLINE
		elif state == State.Network.WAITING_GAMEINFO:
			while socket.get_available_packet_count():
				var variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if variant.has("Player"):
					var coords = variant["Player"]["coords"]
					core.player.position = Vector3(coords[0], coords[1], coords[2])
				elif variant.has("BodiesInSystem"):
					var elements = variant["BodiesInSystem"] as Array
					for element in elements:
						var id = int(element["id"])
						assert(id > 0)
						if core.spawner.bodies_infos.has(id):
							var galactic = core.spawner.bodies_info[id]
							galactic["new_coords"] = Vector3(element["coords"][0], element["coords"][1], element["coords"][2])
						else:
							core.spawner.to_instantiate.push_back({
								"id": id,
								"type": element["element_type"],
								"coords": Vector3(element["coords"][0], element["coords"][1], element["coords"][2]),
								})
	if new_network_state:
		state = new_network_state
	if new_state:
		core.state = new_state

func connect_to_server(host: String, port: int, secure: bool):
	socket = WebSocketPeer.new()

	var url: String
	if secure:
		url = "wss://"
	else:
		url = "ws://"
	url += "%s:%s" % [host, port]

	if socket.connect_to_url(url, null) != OK:
		printerr("Could not connect")
		core.ui.error_placeholder.set_text("Could not connect")
		core.ui.play_button.set_disabled(false)
		return

	print("Connecting to %s" % url)
	core.ui.loading.visible = false
	core.ui.connecting.visible = true
	state = State.Network.CONNECTING
	set_process(true)
