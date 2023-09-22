## An ad hoc HTTP server to handle the OAuth authorization code.
extends Node

const CRLF: String = "\r\n"
const HTTP_QUERY_PARAMETERS_REGEX: String = "(?<=^|&)(?<key>\\S+?)=(?<value>\\S*?)(?=&|$)"
const HTTP_REQUEST_METHOD_REGEX: String = "^(?<method>[A-Z]+) /(?:(?<path>\\S*?)(?:\\?(?<query_parameters>\\S+))?) HTTP\\/1.1$"

var _http_query_parameters_regex := RegEx.create_from_string(HTTP_QUERY_PARAMETERS_REGEX)
var _http_request_method_regex := RegEx.create_from_string(HTTP_REQUEST_METHOD_REGEX)
var _routes := {}
var _server := TCPServer.new()


func _init() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if _server.is_connection_available():
		var peer := _server.take_connection()
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var bytes := peer.get_available_bytes()
			if bytes > 0:
				peer.put_data(_handle_request(peer, peer.get_string(bytes)))
			peer.disconnect_from_host()


func add_request_handler(route: String, callable: Callable) -> void:
	_routes[route] = callable


func get_route_url(route: String) -> String:
	if route in _routes:
		return str("http://localhost:", _server.get_local_port(), "/", route)
	return ""


func is_listening() -> bool:
	return _server.is_listening()


func start(port: int) -> void:
	match _server.listen(port):
		Error.OK:
			set_process(true)
		Error.ERR_ALREADY_IN_USE:
			push_error("Error starting server process: port ", port, " is already in use.")
			stop()


func stop() -> void:
	_server.stop()
	set_process(false)


func _get_query_parameters(query_string: String) -> Dictionary:
	var result := {}
	for m in _http_query_parameters_regex.search_all(query_string):
		var key := m.get_string("key").uri_decode()
		var value = m.get_string("value").uri_decode()
		if value.is_valid_int():
			value = int(value)
		elif value.is_valid_float():
			value = float(value)
		result[key] = value
	return result


func _handle_request(peer: StreamPeerTCP, message: String) -> PackedByteArray:
	# We're only concerned with the request method.
	var regex_match := _http_request_method_regex.search(message.split(CRLF, false, 1)[0])
	if is_instance_valid(regex_match):
		var method := regex_match.get_string("method")
		var path := regex_match.get_string("path")
		var query_parameters := _get_query_parameters(regex_match.get_string("query_parameters"))
		var response := _perform_current_request(method, path, query_parameters)
		return response.to_buffer()
	return PackedByteArray()


func _perform_current_request(method: String, path: String, query_parameters: Dictionary) -> HTTPServerResponse:
	if method == "GET" and path in _routes:
		return _routes[path].call(query_parameters)
	return HTTPServerResponse.not_found({}, "Not Found".to_utf8_buffer())
