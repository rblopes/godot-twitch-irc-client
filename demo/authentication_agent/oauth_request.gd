extends Node

signal access_token_failed(reason: String, status: int)
signal access_token_received()
signal _result()

const EMPTY_TOKEN: String = ""
const AUTHORIZATION_URL: String = "https://id.twitch.tv/oauth2/authorize"
const TOKEN_REQUEST_URL: String = "https://id.twitch.tv/oauth2/token"
const TOKEN_VALIDATION_URL: String = "https://id.twitch.tv/oauth2/validate"

var _oauth_access_token: OAuthAccessToken


func get_access_token() -> String:
	return _oauth_access_token.access_token if is_access_token_ready() else EMPTY_TOKEN


func get_refresh_token() -> String:
	return _oauth_access_token.refresh_token if is_access_token_ready() else EMPTY_TOKEN


func is_access_token_ready() -> bool:
	return is_instance_valid(_oauth_access_token)


func is_access_token_valid() -> bool:
	if is_access_token_ready():
		var request_headers := ["Authorization: OAuth " + get_access_token()]
		if $ValidationRequest.request(TOKEN_VALIDATION_URL, request_headers) == OK:
			var response: Array = await $ValidationRequest.request_completed
			var response_code: int = response[1]
			return response_code == HTTPClient.RESPONSE_OK
	return false


func load_oauth_access_token(path: String) -> bool:
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				_oauth_access_token = OAuthAccessToken.from_dict(json.data)
	return is_instance_valid(_oauth_access_token)


func refresh_access_token(client_id: String, client_secret: String) -> Error:
	var request_headers := ["Content-Type: application/x-www-form-urlencoded"]
	var request_parameters := _encode_query_parameters({
		"client_id": client_id,
		"client_secret": client_secret,
		"grant_type": "refresh_token",
		"refresh_token": get_refresh_token(),
	})
	if $AccessTokenRequest.request(TOKEN_REQUEST_URL, request_headers, HTTPClient.METHOD_POST, request_parameters) == OK:
		return await _result
	return FAILED


func request_access_token(client_id: String, client_secret: String, code: String, redirect_url: String) -> Error:
	var request_headers := ["Content-Type: application/x-www-form-urlencoded"]
	var request_parameters := _encode_query_parameters({
		"client_id": client_id,
		"client_secret": client_secret,
		"code": code,
		"grant_type": "authorization_code",
		"redirect_uri": redirect_url,
	})
	if $AccessTokenRequest.request(TOKEN_REQUEST_URL, request_headers, HTTPClient.METHOD_POST, request_parameters) == OK:
		return await _result
	return FAILED


func request_user_authorization(client_id: String, scopes: PackedStringArray, redirect_url: String) -> void:
	var request_parameters := _encode_query_parameters({
		"client_id": client_id,
		"redirect_uri": redirect_url,
		"response_type": "code",
		"scope": " ".join(scopes),
	})
	OS.shell_open(AUTHORIZATION_URL + "?" + request_parameters)


func save_oauth_access_token(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		file.store_string(JSON.stringify(_oauth_access_token.to_dict()))


func _encode_query_parameters(parameters: Dictionary) -> String:
	var result := PackedStringArray()
	for key in parameters:
		result.append(key + "=" + str(parameters[key]).uri_encode())
	return "&".join(result).strip_edges()


func _on_access_token_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var data: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	match response_code:
		HTTPClient.RESPONSE_OK:
			_oauth_access_token = OAuthAccessToken.from_dict(data)
			access_token_received.emit()
			_result.emit(OK)
		_:
			var message: String = data.get("message", "")
			var status: int = int(data.get("status", 0))
			access_token_failed.emit(message, status)
			_result.emit(FAILED)


class OAuthAccessToken extends RefCounted:
	var access_token: String
	var expires_in: int
	var refresh_token: String
	var scope: PackedStringArray
	var token_type: String

	static func from_dict(data: Dictionary) -> OAuthAccessToken:
		var result := new()
		for key in data:
			var value = data[key]
			match key:
				"access_token":
					if value is String:
						result.access_token = value.strip_edges()
				"expires_in":
					if value is float:
						result.expires_in = int(value)
				"refresh_token":
					if value is String:
						result.refresh_token = value.strip_edges()
				"scope":
					if value is Array:
						result.scope = value
				"token_type":
					if value is String:
						result.token_type = value.strip_edges()
		return result

	func to_dict() -> Dictionary:
		return {
			"access_token": access_token,
			"expires_in": expires_in,
			"refresh_token": refresh_token,
			"scope": scope,
			"token_type": token_type,
		}
