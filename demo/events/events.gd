extends VBoxContainer

@export_range(100, 2000)
var max_events: int = 100


func _create_label(text: String) -> Label:
	var result := Label.new()
	result.text = text
	result.clip_text = true
	return result


func _on_list_child_entered_tree(node: Node) -> void:
	await get_tree().process_frame
	if %List.get_child_count() > max_events:
		%List.get_child(0).queue_free()
	$Contents.ensure_control_visible(node)


func add_event(message: String) -> void:
	%List.add_child(_create_label(str(Time.get_time_string_from_system(), ": ", message)))
