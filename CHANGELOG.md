# CHANGELOG

## HEAD

- BREAKING CHANGE: Remove `connection_refused` signal
- BREAKING CHANGE: Remove `ping` and `pong` signals
- BREAKING CHANGE: Remove `username_list_received` signal
- Change `open_connection` to return error value
- Update message handler

## 2023-09-28 - v0.2.0

- BREAKING CHANGE: Remove `enable_log` property
- BREAKING CHANGE: Remove `is_within_rate_limit` property
- Add `is_within_rate_limit()` method
- Add `logger` signal
- Add `TwitchIRCClient#is_connection_open` method
- Fix a potential issue sending message tags

## 2023-02-01 - v0.1.1

- Fix broken WebSocket code due Godot's API changes

## 2023-01-25 - v0.1.0

- First public release
