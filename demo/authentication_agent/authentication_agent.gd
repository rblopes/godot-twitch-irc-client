extends Node
## Obtain and manage OAuth access tokens for use with Twitch applications.

## Emitted when obtaining an access token fails.
signal access_token_failed(reason: String, status: int)

## Emitted when an access token is not found.
signal access_token_missing()

## Emitted when an access token is available.
signal access_token_ready()

## Where the access token should be stored in the file system.
@export_global_file("*.json")
var access_token_path: String = "user://access_token.json"

## The application client ID. Required.
@export
var client_id: String

## The application client secret code. Required.
@export
var client_secret: String

## OAuth redirect URL, as specified in the application console. Required.
@export_placeholder("https://example.com/callback")
var oauth_redirect_url: String = ""

## The scopes requested for the access token.
@export
var scopes: PackedStringArray = ["chat:edit", "chat:read"]

## If this agent should check de validity of the access token periodically.
@export
var should_auto_validate_access_token: bool

## How long, if enabled, the agent will wait to verify the current access token validity.
@export_range(1800, 10800, 1800)
var validation_interval: int = 3600


## Convenience method to get the OAuth access token string.
func get_access_token() -> String:
	return $OAuthRequest.get_access_token()


## Checks whether an access token is loaded and ready.
func is_access_token_ready() -> bool:
	return $OAuthRequest.is_access_token_ready()


## Checks whether the current access token is valid.
func is_access_token_valid() -> bool:
	return await $OAuthRequest.is_access_token_valid()


## Forces the renewal of the current access token.
func refresh_access_token() -> Error:
	assert(not client_id.is_empty(), "Required app client id is missing.")
	assert(not client_secret.is_empty(), "Required app client secret is missing.")
	return await $OAuthRequest.refresh_access_token(client_id, client_secret)


## Request a new access token, with the given [member scopes].
func request_access_token(authorization_code: String) -> Error:
	assert(not authorization_code.is_empty(), "Authorization code cannot be empty.")
	assert(not client_id.is_empty(), "Required app client id is missing.")
	assert(not client_secret.is_empty(), "Required app client secret is missing.")
	assert(not oauth_redirect_url.is_empty(), "Required OAuth redirect URL is missing.")
	return await $OAuthRequest.request_access_token(client_id, client_secret, authorization_code, oauth_redirect_url)


## Prompts the user to authorize the application.
func request_user_authorization() -> void:
	assert(not client_id.is_empty(), "Required app client id is missing.")
	assert(not oauth_redirect_url.is_empty(), "Required OAuth redirect URL is missing.")
	$OAuthRequest.request_user_authorization(client_id, scopes, oauth_redirect_url)


## Tries to load, validate and refresh a previously obtained access token.
func restore_access_token() -> void:
	assert(not client_id.is_empty(), "Required app client id is missing.")
	assert(not client_secret.is_empty(), "Required app client secret is missing.")
	if $OAuthRequest.load_oauth_access_token(access_token_path):
		if await $OAuthRequest.is_access_token_valid() or await $OAuthRequest.refresh_access_token(client_id, client_secret) == OK:
			if should_auto_validate_access_token:
				$Refresh.start(validation_interval)
			access_token_ready.emit()
			return
	access_token_missing.emit()


func _on_oauth_request_access_token_failed(reason: String, status: int) -> void:
	access_token_failed.emit(reason, status)


func _on_oauth_request_access_token_received() -> void:
	$OAuthRequest.save_oauth_access_token(access_token_path)
	access_token_ready.emit()
	if should_auto_validate_access_token:
		$Refresh.start()


func _on_refresh_timeout() -> void:
	if not await $OAuthRequest.is_access_token_valid():
		$OAuthRequest.refresh_access_token(client_id, client_secret)
