class_name Server extends Node

enum State {NOT_RUNNING, WAITING_PORT, RUNNING}

var state: State = State.NOT_RUNNING
var process = null
var regex = RegEx.new()
var mutex: Mutex = Mutex.new()
var port = 0
var server_logs_out_thread: Thread
var server_logs_err_thread: Thread
var server_url: String = ""
var stop_timer = 0
@onready var core = get_tree().get_first_node_in_group("core")
@onready var server_logs = get_tree().get_first_node_in_group("server_logs")
@onready var ui = get_tree().get_first_node_in_group("ui")
@onready var network = get_tree().get_first_node_in_group("network")

func quit():
	if state != State.NOT_RUNNING:
		print("Waiting threads")
		server_logs_err_thread.wait_to_finish()
		server_logs_out_thread.wait_to_finish()

func _ready():
	regex.compile("^.*Server loop starts, listenning on (\\d+)$")

func _server_logs(key):
	var pipe = process[key] as FileAccess
	var line_empty_cnt = 0

	while state == State.RUNNING:
		var line = pipe.get_line()
		if pipe.eof_reached():
			break

		if line.is_empty():
			line_empty_cnt += 1
			if line_empty_cnt == 10:
				print("Got %d empty lines, reader thread (%s) quitting now..." % [line_empty_cnt, key])
				break

		if key == "stderr":
			var search_result = regex.search(line)
			if search_result:
				var port_str = search_result.get_string(1)
				assert(!port_str.is_empty())
				print("Found port: %s" % port_str)
				mutex.lock()
				port = int(port_str)
				mutex.unlock()
		if !line.is_empty():
			print("> %s" % line)
		if !OS.has_feature("release"):
			server_logs.call_deferred("append_text", line)
			server_logs.call_deferred("newline")

	print("Server log (%s) thread quitting now!" % key)


func launch(world_name):
	if !OS.has_feature("release"):
		#OS.set_environment("RUST_LOG", "TRACE")
		var server_path = ProjectSettings.globalize_path("res://server")
		var instance_path = ProjectSettings.globalize_path("user://%s.sbdb" % world_name)
		var ret
		if OS.has_feature("windows"):
			ret = OS.execute("powershell.exe", ["-Command", "Get-Process -Name spacebuild-server | Stop-Process"])
		else:
			ret = OS.execute("bash", ["-c", "killall spacebuild-server"])

		if ret == -1:
			print("Cleaner failed to execute")
		elif ret == 0:
			print("Had to clean remaining server instances")

		# var args = ["run", "--manifest-path", manifest_path, "--bin", "spacebuild-server", "--", "0",
		# 	"--instance", ProjectSettings.globalize_path("user://%s.sbdb" % world_text), "--trace-level", "INFO"]
		var args = ["0",
			"--instance", instance_path, "--trace-level", "INFO"]
		process = OS.execute_with_pipe(server_path, args)
	else:
		#OS.set_environment("RUST_LOG", "INFO")
		var args = ["0", "--instance", ProjectSettings.globalize_path("user://%s.sbdb" % world_name), "--trace-level", "INFO"]
		process = OS.execute_with_pipe("./spacebuild-server", args)

	if process.is_empty():
		printerr("Failed to run server")
		ui.error_placeholder.set_text("Local server not found or could not be executed")
		ui.play_button.set_disabled(false)
		return

	state = State.RUNNING
	port = 0
	if server_logs_err_thread && server_logs_err_thread.is_started():
		server_logs_err_thread.wait_to_finish()
	server_logs_err_thread = Thread.new()
	server_logs_err_thread.start(_server_logs.bind("stderr"))
	if server_logs_out_thread && server_logs_out_thread.is_started():
		server_logs_out_thread.wait_to_finish()
	server_logs_out_thread = Thread.new()
	server_logs_out_thread.start(_server_logs.bind("stdio"))
	server_url = "ws://localhost"

func stop_server():
	print("Stopping server gracefully...")
	(process["stdio"] as FileAccess).store_line("stop")
	(process["stdio"] as FileAccess).flush()
	core.state = Core.State.STOPPING_GAME

func _process(delta):
	if state == State.WAITING_PORT:
		mutex.lock()
		var locked_port = port
		mutex.unlock()

		if !locked_port:
			return

		server_url += ":%d" % locked_port
		print("Connecting to %s..." % server_url)
		network.connect_to_server()

	if core.state == Core.State.STOPPING_GAME || core.state == Core.State.QUITTING:
		stop_timer += delta;

		if !OS.is_process_running(process["pid"]):
			if core.state == Core.State.QUITTING:
				core.quit_now(true);
			else:
				process = Dictionary()
				state = State.NOT_RUNNING
				#refresh(State.WELCOME, network_state)
				stop_timer = 0
				return

		if stop_timer < 10:
			return ;

		stop_timer = 0

		print("Killing server!")
		OS.kill(process["pid"])
		state = State.NOT_RUNNING

		if core.state == Core.State.QUITTING:
			core.quit_now(true)

		process = Dictionary()
		#refresh(State.WELCOME, network_state)
		return

	if state == State.RUNNING:
		if !process.is_empty() && !OS.is_process_running(process["pid"]):
			state = State.NOT_RUNNING
			#refresh(State.WELCOME, network_state)
			server_logs_err_thread.wait_to_finish()
			server_logs_out_thread.wait_to_finish()
