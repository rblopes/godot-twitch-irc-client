extends Node

signal connection_closed()
signal connected_to_server()
signal message_received(message: Variant)

@export
var handshake_headers: PackedStringArray

@export
var supported_protocols: PackedStringArray

@export
var tls_trusted_certificate: X509Certificate

var _last_state := WebSocketPeer.STATE_CLOSED
var _socket := WebSocketPeer.new()


func _process(delta: float) -> void:
	if _socket.get_ready_state() != _socket.STATE_CLOSED:
		_socket.poll()
	var state := _socket.get_ready_state()
	if _last_state != state:
		_last_state = state
		if _last_state == _socket.STATE_OPEN:
			connected_to_server.emit()
		if _last_state == _socket.STATE_CLOSED:
			connection_closed.emit()
	while _socket.get_ready_state() == _socket.STATE_OPEN and _socket.get_available_packet_count() > 0:
		message_received.emit(get_message())


func clear() -> void:
	_socket = WebSocketPeer.new()
	_last_state = _socket.get_ready_state()


func close(code: int = 1000, reason: String = "") -> void:
	_socket.close(code, reason)
	_last_state = _socket.get_ready_state()


func connect_to_url(url: String) -> int:
	_socket.handshake_headers = handshake_headers
	_socket.supported_protocols = supported_protocols
	var error := _socket.connect_to_url(url, TLSOptions.client(tls_trusted_certificate))
	if error == OK:
		_last_state = _socket.get_ready_state()
	return error


func get_message() -> Variant:
	if _socket.get_available_packet_count() > 0:
		var packet := _socket.get_packet()
		if _socket.was_string_packet():
			return packet.get_string_from_utf8()
		return bytes_to_var(packet)
	return null


func send(message: Variant) -> int:
	if message is String:
		return _socket.send_text(message)
	return _socket.send(var_to_bytes(message))


# Based on Fabio Alessandrelli's 'gd-websocket-nodes' plugin.
#
# ==============================================================================
#
# MIT License
#
# Copyright (c) 2022 Fabio Alessandrelli
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
