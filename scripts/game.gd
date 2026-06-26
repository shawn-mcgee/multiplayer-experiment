extends Node2D

@onready var multiplayer_ui = $MultiplayerUI

var peer = ENetMultiplayerPeer.new()

const PLAYER = preload("res://scenes/player.tscn")



func _on_join_pressed() -> void:
  multiplayer_ui.hide()
  peer.create_client("localhost", 42069)
  multiplayer.multiplayer_peer = peer

func _on_host_pressed() -> void:
  multiplayer_ui.hide()
  peer.create_server(42069)
  multiplayer.multiplayer_peer = peer

  multiplayer.peer_connected.connect(
    func(pid):
      add_player(pid)
  )

  add_player(multiplayer.get_unique_id())

func add_player(pid: int):
  var player = PLAYER.instantiate()

  player.name = str(pid)

  add_child(player)
