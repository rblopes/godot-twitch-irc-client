extends VBoxContainer


func add_user(username: String) -> void:
	$List.add_item(username)
	$List.sort_items_by_text()


func remove_user(username: String) -> void:
	var index := -1
	for i in $List.item_count:
		if $List.get_item_text(i) == username:
			index = i
			break
	if index >= 0:
		$List.remove_item(index)
