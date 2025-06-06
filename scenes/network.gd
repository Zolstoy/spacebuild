class_name Network extends Node

enum State {IDLE, CONNECTING, AUTHENTICATING, WAITING_GAMEINFO, CLOSING}

var state: State = State.IDLE
var socket = null
var close_timer = 0
@onready var core = get_tree().get_first_node_in_group("core")
@onready var ui = get_tree().get_first_node_in_group("ui")
@onready var server = get_tree().get_first_node_in_group("server")
@onready var spawner = get_tree().get_first_node_in_group("spawner")



var login_hash = {
	"Login": {
		"nickname": ""
	}
}


func connect_to_server(host, port):
	socket = WebSocketPeer.new()

	var options = TLSOptions.client()
	if ui.welcome_state == ui.WelcomeState.ONLINE && ui.encrypted_switch.is_pressed():
		var cert = X509Certificate.new()
		if cert.load("ca_cert.pem") == OK:
			options = TLSOptions.client(cert)

	if socket.connect_to_url(host, options) != OK:
		printerr("Could not connect")
		ui.error_placeholder.set_text("Could not connect")
		ui.play_button.set_disabled(false)
		#refresh(State.WELCOME, network_state)
		return

	#refresh(State.LOADING, NetworkState.CONNECTING)

func _process(delta):
	if state != State.IDLE:

		var new_network_state: State
		var new_state: Core.State
		socket.poll()

		var socket_state = socket.get_ready_state()
		if socket_state == WebSocketPeer.STATE_CLOSING:
			if core.state == core.State.LEAVING:
				if close_timer == 0:
					print("Closing")
					new_network_state = State.CLOSING
				if close_timer >= 0.5:
					socket = WebSocketPeer.new()
					new_network_state = State.IDLE
					if ui.welcome_state == ui.WelcomeState.SOLO && !OS.has_feature("web"):
						server.stop_server()
					else:
						new_state = Core.State.WELCOME
					close_timer = 0
				else:
					close_timer += delta


		elif socket_state == WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			socket = WebSocketPeer.new()
			new_network_state = State.IDLE
			#if state == Core.State.PLAYING_SOLO:
				#stop_server()
			#else:
				#new_state = State.WELCOME
			close_timer = 0


		elif state == State.CONNECTING && socket_state == WebSocketPeer.STATE_OPEN:
			if ui.welcome_state == ui.WelcomeState.ONLINE:
				login_hash["Login"]["nickname"] = ui.login_field.get_text()
			else:
				login_hash["Login"]["nickname"] = "Player"
			if socket.send_text(JSON.stringify(login_hash)) != OK:
				print("Send error")
			else:
				new_network_state = State.AUTHENTICATING

		elif state == State.AUTHENTICATING:
			if socket.get_available_packet_count():
				var variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if variant["success"] == false:
					print("Login failure: %s" % variant["message"])
					ui.error_placeholder.set_text("Authentication failed: %s" % variant["message"])
					core.leave()
				else:
					print("Login success, id is %s" % variant["message"])
					new_network_state = State.WAITING_GAMEINFO
					if server.state == Server.State.RUNNING:
						new_state = Core.State.PLAYING_SOLO
					else:
						new_state = Core.State.PLAYING_ONLINE

		elif state == State.WAITING_GAMEINFO:
			while socket.get_available_packet_count():
				var variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				#print("Received: %s" % variant)
				#var galactics = container.get_children()
				if variant.has("Player"):
					var coords = variant["Player"]["coords"]
					#print(coords)
					core.player.position = Vector3(coords[0], coords[1], coords[2])

				#elif variant.has("PlayersInSystem"):
					#var elements = variant["PlayersInSystem"] as Array
					#
					#for galactic in galactics:
						#var found = false
						#for element in elements:
							#if element["id"] == galactic.get_name():
								#found = true
								#break
						#if !found:
							#container.remove_child(galactic)
							#
					#
					#for element in elements:
						#var found = false
						#for galactic in galactics:
							#if galactic.get_name() == element["id"]:
								#galactic.position = Vector3(element["coords"][0], element["coords"][1], element["coords"][2])
								#found = true
								#break
						#if !found:
							#to_instantiate.push_back({
								#"id": element["id"],
								#"type": "Player",
								#"coords": Vector3(element["coords"][0], element["coords"][1], element["coords"][2])})

				elif variant.has("BodiesInSystem"):
					var elements = variant["BodiesInSystem"] as Array

					for element in elements:
						var galactic = spawner.get_node_or_null(str(int(element["id"])))
						if galactic:
							var body_info = spawner.bodies_infos[int(element["id"])]

							body_info["new_coords"] = Vector3(element["coords"][0], element["coords"][1], element["coords"][2])
							#galactic.position = Vector3(element["coords"][0], element["coords"][1], element["coords"][2])
						else:
							spawner.to_instantiate.push_back({
								"id": int(element["id"]),
								"type": element["element_type"],
								"coords": Vector3(element["coords"][0], element["coords"][1], element["coords"][2]),
								"gravity_center": int(element["gravity_center"]),
								"rotating_speed": element["rotating_speed"],
								})
