extends VBoxContainer

var _list := {}


func _create_label(text: String) -> Label:
	var result := Label.new()
	result.text = text
	return result


func add_user(username: String) -> void:
	if not username in _list:
		_list[username] = %List.add_item(username)
		%List.sort_items_by_text()


func remove_user(username: String) -> void:
	if username in _list:
		%List.remove_item(_list[username])
		_list.erase(username)
