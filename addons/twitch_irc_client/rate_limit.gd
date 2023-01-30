extends Timer

# How many messages have been sent within the current time frame.
var _messages_sent_count: int = 0


func _on_timeout() -> void:
	_messages_sent_count = 0


func count() -> void:
	_messages_sent_count += 1
	if is_stopped():
		start()


func is_within_limit(rate_limit: int) -> bool:
	return _messages_sent_count < rate_limit
