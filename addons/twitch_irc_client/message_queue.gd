extends Node

signal dispatch_requested(message: String)

const CRLF := "\r\n"

# To avoid flooding and, consequently, temporary suspensions, messages are
# queued and dispatched at regular intervals.
var _outgoing_messages: Array[String] = []


func _on_dispatch_timeout() -> void:
	if not _outgoing_messages.is_empty():
		dispatch_requested.emit(_outgoing_messages.pop_front() + CRLF)


func add(message: String) -> void:
	if not $Dispatch.is_stopped():
		_outgoing_messages.push_back(message)


func clear() -> void:
	_outgoing_messages.clear()


func start() -> void:
	$Dispatch.start()


func stop() -> void:
	$Dispatch.stop()
