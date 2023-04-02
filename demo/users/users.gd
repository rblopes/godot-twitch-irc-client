extends VBoxContainer


func _find_index(username: String) -> int:
	for i in $List.item_count:
		if $List.get_item_text(i) == username:
			return i
	return -1


func add_user(username: String) -> void:
	if _find_index(username) < 0:
		$List.add_item(username)
		$List.sort_items_by_text()


func remove_user(username: String) -> void:
	var index := _find_index(username)
	if index >= 0:
		$List.remove_item(index)
