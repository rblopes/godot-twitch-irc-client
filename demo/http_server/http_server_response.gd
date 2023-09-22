class_name HTTPServerResponse
extends Node

const CRLF: String = "\r\n"

var headers: Dictionary
var response_code: HTTPClient.ResponseCode
var body: PackedByteArray


func _get_formatted_header() -> PackedByteArray:
	var result := PackedStringArray()
	result.append("HTTP/1.1 %d %s" % [response_code, _get_response_code_name()])
	for key in headers:
		result.append(key + ": " + headers[key] + "")
	result.append("Content-Length: %d" % [len(body)])
	result.append("Content-Type: text/plain; charset=UTF-8")
	result.append(CRLF)
	return CRLF.join(result).to_utf8_buffer()


func _get_response_code_name() -> String:
	match response_code:
		HTTPClient.RESPONSE_OK:
			return "OK"
		HTTPClient.RESPONSE_BAD_REQUEST:
			return "Bad Request"
		HTTPClient.RESPONSE_UNAUTHORIZED:
			return "Unauthorized"
		HTTPClient.RESPONSE_NOT_FOUND:
			return "Not Found"
	return ""


func _init(p_response_code: HTTPClient.ResponseCode, p_headers: Dictionary, p_body: PackedByteArray) -> void:
	response_code = p_response_code
	headers = p_headers
	body = p_body


func to_buffer() -> PackedByteArray:
	return _get_formatted_header() + body


static func ok(p_headers: Dictionary, p_body: PackedByteArray) -> HTTPServerResponse:
	return HTTPServerResponse.new(HTTPClient.RESPONSE_OK, p_headers, p_body)


static func bad_request(p_headers: Dictionary, p_body: PackedByteArray) -> HTTPServerResponse:
	return HTTPServerResponse.new(HTTPClient.RESPONSE_BAD_REQUEST, p_headers, p_body)


static func unauthorized(p_headers: Dictionary, p_body: PackedByteArray) -> HTTPServerResponse:
	return HTTPServerResponse.new(HTTPClient.RESPONSE_UNAUTHORIZED, p_headers, p_body)


static func not_found(p_headers: Dictionary, p_body: PackedByteArray) -> HTTPServerResponse:
	return HTTPServerResponse.new(HTTPClient.RESPONSE_NOT_FOUND, p_headers, p_body)
