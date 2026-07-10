extends Node2D

var mp: WebRTCMultiplayerPeer
var ss: WebRtcSignallingServer
var sc: WebRtcSignallingClient

var self_id: int = -1
var host_id: int = -1

const WEBRTC_CONFIGURATION = {
  "iceServers": [
    { 
      "urls": [
        "stun.l.google.com:19302",
        "stun1.l.google.com:19302",
        "stun2.l.google.com:19302",
        "stun3.l.google.com:19302",
        "stun4.l.google.com:19302",
      ]
    }
  ]
}


func _ready():
  $CanvasLayer/Control/VBoxContainer/WebRtcSignallingServer.pressed.connect(_on_webrtc_signalling_server_pressed)
  $CanvasLayer/Control/VBoxContainer/Host.pressed.connect(_on_host_pressed)
  $CanvasLayer/Control/VBoxContainer/Join.pressed.connect(_on_join_pressed)

func _process(_delta) -> void:
  if !mp:
    return

  for peer_id in mp.get_peers():
    mp.get_peer(peer_id).connection.poll()

func _on_webrtc_signalling_server_pressed():
  $CanvasLayer/Control/VBoxContainer/WebRtcSignallingServer.disabled = true
  ss = WebRtcSignallingServer.new()
  add_child(ss)

func _on_host_pressed():
  $CanvasLayer/Control/VBoxContainer/Host  .disabled = true
  $CanvasLayer/Control/VBoxContainer/Join  .disabled = true
  $CanvasLayer/Control/VBoxContainer/RoomId.editable = false

  sc = WebRtcSignallingClient.new()
  add_child(sc)

  sc.available.connect(_host_available)

func _on_join_pressed():
  $CanvasLayer/Control/VBoxContainer/Host.disabled   = true
  $CanvasLayer/Control/VBoxContainer/Join.disabled   = true
  $CanvasLayer/Control/VBoxContainer/RoomId.editable = false

  sc = WebRtcSignallingClient.new()
  add_child(sc)

  sc.available.connect(_join_available)

func _host_available():
  sc.host_room_response.connect(_on_host_room_response)
  sc.host_room()

func _join_available():
  var room_id = $CanvasLayer/Control/VBoxContainer/RoomId.text
  sc.join_room_response.connect(_on_join_room_response)
  sc.join_room(room_id)

func _on_host_room_response(message: Dictionary):
  if !message.ok:
    print("[Game] Error hosting room: %s" % message.error)
    $CanvasLayer/Control/VBoxContainer/Host.disabled   = false
    $CanvasLayer/Control/VBoxContainer/Join.disabled   = false
    $CanvasLayer/Control/VBoxContainer/RoomId.editable = true
    sc.queue_free()
    sc = null
    return

  $CanvasLayer/Control/VBoxContainer/RoomId.text = message.room_id
  mp = WebRTCMultiplayerPeer.new()
  mp.create_server()

  multiplayer.multiplayer_peer = mp

  mp.peer_connected   .connect(_on_peer_connected   )
  mp.peer_disconnected.connect(_on_peer_disconnected)

  self_id = message.peer_id
  host_id = message.peer_id

  sc.webrtc_offer        .connect(_on_webrtc_offer        )
  sc.webrtc_ice_candidate.connect(_on_webrtc_ice_candidate)

  spawn_player(1)

func _on_join_room_response(message: Dictionary):
  if !message.ok:
    print("[Game] Error joining room: %s" % message.error)
    $CanvasLayer/Control/VBoxContainer/Host.disabled   = false
    $CanvasLayer/Control/VBoxContainer/Join.disabled   = false
    $CanvasLayer/Control/VBoxContainer/RoomId.editable = true
    sc.queue_free()
    sc = null
    return

  self_id = message.peer_id
  host_id = message.host_id

  mp = WebRTCMultiplayerPeer.new( )
  mp.create_client(self_id)

  multiplayer.multiplayer_peer = mp
  mp.peer_connected   .connect(_on_peer_connected   )
  mp.peer_disconnected.connect(_on_peer_disconnected)

  var cx = WebRTCPeerConnection.new()
  cx.initialize(WEBRTC_CONFIGURATION)
  mp.add_peer(cx, 1)

  cx.create_data_channel("data", { "id": 1, "negotiated": true })

  var _on_session_description_created = func(type: String, sdp: String):
    cx.set_local_description(type, sdp)
    sc.send_message(WebRtcSignalling.WebRtcOffer(
      self_id,
      host_id,
      type,
      sdp
    ))

  var _on_ice_candidate_created       = func(media: String, index: int, name_: String):
    sc.send_message(WebRtcSignalling.WebRtcIceCandidate(
      self_id,
      host_id,
      media,
      index,
      name_
    ))

  cx.session_description_created.connect(_on_session_description_created)
  cx.      ice_candidate_created.connect(      _on_ice_candidate_created)
  sc.webrtc_answer       .connect(_on_webrtc_answer       )
  sc.webrtc_ice_candidate.connect(_on_webrtc_ice_candidate)
  cx.create_offer()

func _on_webrtc_offer        (webrtc_offer : Dictionary):
  var peer_id = webrtc_offer.from

  var cx = WebRTCPeerConnection.new()
  cx.initialize(WEBRTC_CONFIGURATION)
  mp.add_peer(cx, peer_id)

  cx.create_data_channel("data", { "id": 1, "negotiated": true })
  cx.set_remote_description(
    webrtc_offer.type, 
    webrtc_offer.sdp
  )

  var _on_session_description_created = func(type: String, sdp: String):
    cx.set_local_description(type, sdp)
    sc.send_message(WebRtcSignalling.WebRtcAnswer(
      self_id,
      peer_id,
      type,
      sdp
    ))

  var _on_ice_candidate_created       = func(media: String, index: int, name_: String):
    sc.send_message(WebRtcSignalling.WebRtcIceCandidate(
      self_id,
      peer_id,
      media, 
      index, 
      name_
    ))

  cx.session_description_created.connect(_on_session_description_created)
  cx.      ice_candidate_created.connect(      _on_ice_candidate_created)  

func _on_webrtc_answer       (webrtc_answer: Dictionary):
  var peer_id = webrtc_answer.from
  if peer_id == host_id:
    peer_id = 1

  var peer = mp.get_peer(peer_id)
  if !peer:
    return

  var cx = peer.connection
  cx.set_remote_description(
    webrtc_answer.type, 
    webrtc_answer.sdp
  )

func _on_webrtc_ice_candidate(webrtc_ice_candidate: Dictionary):
  var peer_id = webrtc_ice_candidate.from
  if peer_id == host_id:
    peer_id = 1

  var peer = mp.get_peer(peer_id)
  if !peer:
    return

  var cx = peer.connection
  cx.add_ice_candidate(
    webrtc_ice_candidate.media, 
    webrtc_ice_candidate.index, 
    webrtc_ice_candidate.name
  )

func _on_peer_connected   (peer_id: int):
  print("[Game] Peer with id %d connected." % peer_id)
  spawn_player(peer_id)

func _on_peer_disconnected(peer_id: int):
  print("[Game] Peer with id %d disconnected." % peer_id)

const PLAYER = preload("res://player.tscn")
func spawn_player(peer_id: int):
  if !multiplayer.is_server():
    return

  var player = PLAYER.instantiate()
  player.name = str(peer_id)

  call_deferred("add_child", player)