extends Node2D

const WEBRTC_COORDINATOR   = "wss://webrtc-coordinator.s-mcgeek07.workers.dev"
const WEBRTC_CONFIGURATION = {
  "iceServers": [
      {
        "urls": "stun:stun.relay.metered.ca:80",
      },
      {
        "urls": "turn:standard.relay.metered.ca:80",
        "username": "1e7fc80a14bceb79f35cc27a",
        "credential": "EXkiKkQYhUdelWg1",
      },
      {
        "urls": "turn:standard.relay.metered.ca:80?transport=tcp",
        "username": "1e7fc80a14bceb79f35cc27a",
        "credential": "EXkiKkQYhUdelWg1",
      },
      {
        "urls": "turn:standard.relay.metered.ca:443",
        "username": "1e7fc80a14bceb79f35cc27a",
        "credential": "EXkiKkQYhUdelWg1",
      },
      {
        "urls": "turns:standard.relay.metered.ca:443?transport=tcp",
        "username": "1e7fc80a14bceb79f35cc27a",
        "credential": "EXkiKkQYhUdelWg1",
      },
  ],
}

# const WEBRTC_COORDINATOR = "ws://127.0.0.1:8787"

var mp: WebRTCMultiplayerPeer
var ws: WebSocketPeer

signal host_room_response(message: Dictionary)
signal join_room_response(message: Dictionary)
signal webrtc_offer        (message: Dictionary)
signal webrtc_answer       (message: Dictionary)
signal webrtc_ice_candidate(message: Dictionary)

var self_id: int
var host_id: int
var room_id: String

func _ready():
  $CanvasLayer/Control/VBoxContainer/Host.pressed.connect(host)
  $CanvasLayer/Control/VBoxContainer/Join.pressed.connect(join)

func host():
  $CanvasLayer/Control/VBoxContainer/Host.disabled   = true
  $CanvasLayer/Control/VBoxContainer/Join.disabled   = true
  $CanvasLayer/Control/VBoxContainer/RoomId.editable = false

  host_room_response.connect(self._on_host_room_response)

  ws = WebSocketPeer.new()
  ws.connect_to_url("%s/host" % WEBRTC_COORDINATOR)

func join():
  $CanvasLayer/Control/VBoxContainer/Host.disabled   = true
  $CanvasLayer/Control/VBoxContainer/Join.disabled   = true
  $CanvasLayer/Control/VBoxContainer/RoomId.editable = false

  join_room_response.connect(self._on_join_room_response)

  var room_id = $CanvasLayer/Control/VBoxContainer/RoomId.text

  ws = WebSocketPeer.new()
  ws.connect_to_url("%s/join/%s" % [WEBRTC_COORDINATOR, room_id])

func _process(_delta: float) -> void:
  if ws:
    ws.poll()

    match ws.get_ready_state():
      WebSocketPeer.STATE_OPEN:
        if ws.get_available_packet_count() > 0:
          var incoming_bytes   = ws.get_packet()
          var incoming_string  = incoming_bytes.get_string_from_utf8()
          var incoming_message = JSON.parse_string(incoming_string)

          _handle_incoming_message(incoming_message)

      WebSocketPeer.STATE_CLOSED:
        var code   = ws.get_close_code  ()
        var reason = ws.get_close_reason()
        print("WebSocket closed with code %d: %s" % [code, reason])
        set_process(false)

func _handle_incoming_message(message: Dictionary) -> void:
  match message.is:
    Protocol.HOST_ROOM:
      host_room_response  .emit(message)
    Protocol.JOIN_ROOM:
      join_room_response  .emit(message)
    Protocol.WEBRTC_OFFER:
      webrtc_offer        .emit(message)
    Protocol.WEBRTC_ANSWER:
      webrtc_answer       .emit(message)
    Protocol.WEBRTC_ICE_CANDIDATE:
      webrtc_ice_candidate.emit(message)

func _on_host_room_response(message: Dictionary):
  if (!message.ok):
    print(message.error)
    return

  room_id = message.room_id
  self_id = message.host_id
  host_id = message.host_id

  $CanvasLayer/Control/VBoxContainer/RoomId.text = str(room_id)

  mp = WebRTCMultiplayerPeer.new()
  mp.create_server()

  multiplayer.multiplayer_peer = mp
  mp.peer_connected   .connect(_on_peer_connected   )
  mp.peer_disconnected.connect(_on_peer_disconnected)

  webrtc_offer        .connect(self._on_webrtc_offer        )
  webrtc_ice_candidate.connect(self._on_webrtc_ice_candidate)

  spawn_player(1)

func _on_join_room_response(message: Dictionary):
  if (!message.ok):
    print(message.error)
    return

  room_id = message.room_id
  self_id = message.peer_id
  host_id = message.host_id

  mp = WebRTCMultiplayerPeer.new()
  mp.create_client(self_id)

  multiplayer.multiplayer_peer = mp
  mp.peer_connected   .connect(_on_peer_connected   )
  mp.peer_disconnected.connect(_on_peer_disconnected)

  var peer = WebRTCPeerConnection.new()
  peer.initialize(WEBRTC_CONFIGURATION)
  mp.add_peer(peer, 1)

  var _on_session_description_created = func(type: String, sdp: String):
    peer.set_local_description(type, sdp)
    ws.send_text(Protocol.WebRtcOffer(
      self_id,
      host_id,
      type,
      sdp
    ))

  var _on_ice_candidate_created = func(media: String, index: int, name: String):
    ws.send_text(Protocol.WebRtcIceCandidate(
      self_id,
      host_id,
      media,
      index,
      name
    ))

  peer.session_description_created.connect(_on_session_description_created)
  peer.      ice_candidate_created.connect(      _on_ice_candidate_created)
  webrtc_answer       .connect(self._on_webrtc_answer       )
  webrtc_ice_candidate.connect(self._on_webrtc_ice_candidate)

  # peer.create_data_channel("data", { "id": 1, "negotiated": true })
  peer.create_offer()

func _on_webrtc_offer        (message: Dictionary):
  var peer_id = message.from_id

  var peer = WebRTCPeerConnection.new()
  peer.initialize(WEBRTC_CONFIGURATION)
  mp.add_peer(peer, peer_id)

  var _on_session_description_created = func(type: String, sdp: String):
    peer.set_local_description(type, sdp)
    ws.send_text(Protocol.WebRtcAnswer(
      self_id,
      peer_id,
      type,
      sdp
    ))

  var _on_ice_candidate_created = func(media: String, index: int, name: String):
    ws.send_text(Protocol.WebRtcIceCandidate(
      self_id,
      peer_id,
      media, 
      index, 
      name
    ))

  peer.session_description_created.connect(_on_session_description_created)
  peer.      ice_candidate_created.connect(      _on_ice_candidate_created)

  # peer.create_data_channel("data", { "id": 1, "negotiated": true })
  peer.set_remote_description(
    message.type, 
    message.sdp
  )

func _on_webrtc_answer       (message: Dictionary):
  mp.get_peer(message.from_id).connection.set_remote_description(
    message.type, 
    message.sdp
  )

func _on_webrtc_ice_candidate(message: Dictionary):
  mp.get_peer(message.from_id).connection.add_ice_candidate(
    message.media, 
    message.index, 
    message.name
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

class Protocol:
  const HOST_ROOM = "v1-host-room"
  const JOIN_ROOM = "v1-join-room"

  const WEBRTC_OFFER         = "v1-webrtc-offer"
  const WEBRTC_ANSWER        = "v1-webrtc-answer"
  const WEBRTC_ICE_CANDIDATE = "v1-webrtc-ice-candidate"

  static func WebRtcOffer(from_id: int, to_id: int, type: String, sdp: String):
    return JSON.stringify({
      "is": WEBRTC_OFFER,
      "from_id": from_id,
      "to_id"  : to_id  ,
      "type"   : type   ,
      "sdp"    : sdp
    })

  static func WebRtcAnswer(from_id: int, to_id: int, type: String, sdp: String):
    return JSON.stringify({
      "is": WEBRTC_ANSWER,
      "from_id": from_id,
      "to_id"  : to_id  ,
      "type"   : type   ,
      "sdp"    : sdp
    })

  static func WebRtcIceCandidate(from_id: int, to_id: int, media: String, index: int, name: String):
    return JSON.stringify({
      "is": WEBRTC_ICE_CANDIDATE,
      "from_id" : from_id ,
      "to_id"   : to_id   ,
      "media"   : media   ,
      "index"   : index   ,
      "name"    : name
    })


