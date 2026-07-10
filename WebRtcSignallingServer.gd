class_name WebRtcSignallingServer
extends Node

@export var port: int = 8080

var tcp = TCPServer.new()

class Peer:
  var channel: WebSocketPeer
  var peer_id: int

  func _init(
    peer_id_: int,
    channel_: WebSocketPeer, 
  ):
    channel = channel_
    peer_id = peer_id_

class Room:
  var host_id: int
  var room_id: String

  func _init(
    room_id_: String,
    host_id_: int,
  ):
    host_id = host_id_
    room_id = room_id_

var peers: Array[Peer] = [ ]
var rooms: Array[Room] = [ ]

func _ready():
  var error = tcp.listen(port)
  if error != OK:
    print("[WebRTCSignallingServer] Error listening on port %d: %s" % [port, tcp.get_error_string(error)])
  else:
    print("[WebRTCSignallingServer] Listening on port %d." % port)

func _process(_delta) -> void:
  while tcp.is_connection_available():
    var cx = tcp.take_connection()

    var ws = WebSocketPeer.new()
    ws.accept_stream(cx)
    
    var peer_id = create_peer(ws)

    print("[WebRTCSignallingServer] Peer with id %d connected." % peer_id)

  for peer in peers:
    peer.channel.poll()

    match peer.channel.get_ready_state():
      WebSocketPeer.STATE_OPEN  :
        if peer.channel.get_available_packet_count() > 0:
          var incoming_bytes   = peer.channel.get_packet()
          var incoming_string  = incoming_bytes.get_string_from_utf8()
          var incoming_message = JSON.parse_string(incoming_string)

          _handle_incoming_message(peer, incoming_message)

      WebSocketPeer.STATE_CLOSED:
        print("[WebRTCSignallingServer] Peer with id %d disconnected." % peer.peer_id)
        delete_peer             (peer        )
        delete_room_with_host_id(peer.peer_id)

func _handle_incoming_message(peer: Peer, message: Dictionary) -> void:
  match message.is:
    WebRtcSignalling.HOST_ROOM:
      _try_host_room(peer, message)
    WebRtcSignalling.JOIN_ROOM:
      _try_join_room(peer, message)
    WebRtcSignalling.WEBRTC_OFFER:
      _fwd_webrtc_offer(peer, message)
    WebRtcSignalling.WEBRTC_ANSWER:
      _fwd_webrtc_answer(peer, message)
    WebRtcSignalling.WEBRTC_ICE_CANDIDATE:
      _fwd_webrtc_ice_candidate(peer, message)

func _try_host_room(peer: Peer, message: Dictionary) -> void:
  print("[WebRTCSignallingServer] Peer with id %d is trying to host a room." % peer.peer_id)

  var room_id = create_room(peer.peer_id)

  print("[WebRTCSignallingServer] Peer with id %d is hosting room with id '%s'." % [peer.peer_id, room_id])

  send_message_to_peer(
    peer,
    WebRtcSignalling.HostRoomOk(
      peer.peer_id,
           room_id
    )
  )

func _try_join_room(peer: Peer, message: Dictionary) -> void:
  print("[WebRTCSignallingServer] Peer with id %d is trying to resolve room with id '%s'." % [peer.peer_id, message.room_id])

  var room = _get_room_with_id(message.room_id)

  if !room:
    print("[WebRTCSignallingServer] Peer with id %d tried to resolve room with id '%s', but room does not exist." % [peer.peer_id, message.room_id])
    send_message_to_peer(
      peer,
      WebRtcSignalling.JoinRoomError(
        "Room with id '%s' does not exist." % message.room_id
      )
    )
    return

  print("[WebRTCSignallingServer] Peer with id %d resolved room with id '%s'." % [peer.peer_id, message.room_id])
  send_message_to_peer(
    peer,
    WebRtcSignalling.JoinRoomOk(
      peer.peer_id,
      room.host_id,
    )
  )

func _fwd_webrtc_offer (peer: Peer, message: Dictionary) -> void:
  print("[WebRTCSignallingServer] Peer with id %d is forwarding webrtc offer to peer with id %d." % [peer.peer_id, message.to])
  var message_ = WebRtcSignalling.WebRtcOffer(
    peer.peer_id, 
    message.to  , 
    message.type, 
    message.sdp
  )
  send_message_to_peer_with_id(message.to, message_)

func _fwd_webrtc_answer(peer: Peer, message: Dictionary) -> void:
  print("[WebRTCSignallingServer] Peer with id %d is forwarding webrtc answer to peer with id %d." % [peer.peer_id, message.to])
  var message_ = WebRtcSignalling.WebRtcAnswer(
    peer.peer_id, 
    message.to  , 
    message.type, 
    message.sdp
  )
  send_message_to_peer_with_id(message.to, message_)

func _fwd_webrtc_ice_candidate(peer: Peer, message: Dictionary) -> void:
  print("[WebRTCSignallingServer] Peer with id %d is forwarding webrtc ice candidate to peer with id %d." % [peer.peer_id, message.to])
  var message_ = WebRtcSignalling.WebRtcIceCandidate(
    peer.peer_id, 
    message.to  , 
    message.media, 
    message.index, 
    message.name
  )
  send_message_to_peer_with_id(message.to, message_)


func create_peer(channel: WebSocketPeer) -> int:
  var peer_id = _unique_peer_id()
  peers.append(Peer.new(
    peer_id,
    channel,
  ))
  print("[WebRTCSignallingServer] Created peer with id %d." % peer_id)
  return peer_id

func create_room(host_id: int) -> String:
  var room_id = _unique_room_id()
  rooms.append(Room.new(
    room_id,
    host_id,
  ))
  print("[WebRTCSignallingServer] Created room with id '%s'." % room_id)
  return room_id

func delete_peer(peer: Peer) -> void:
  if peers.has(peer):
    peers.erase(peer)
    print("[WebRTCSignallingServer] Deleted peer with id %d." % peer.peer_id)

func delete_peer_with_id(peer_id: int) -> void:
  var peer = _get_peer_with_id(peer_id)
  if peer: 
    delete_peer(peer)

func delete_room(room: Room) -> void:
  if rooms.has(room):
    rooms.erase(room)
    print("[WebRTCSignallingServer] Deleted room with id '%s'." % room.room_id)

func delete_room_with_id(room_id: String) -> void:
  var room = _get_room_with_id(room_id)
  if room: 
    delete_room(room)

func delete_room_with_host_id(host_id: int) -> void:
  var room = _get_room_with_host_id(host_id)
  if room: 
    delete_room(room)

func delete_room_with_peer_id(peer_id: int) -> void:
  var room = _get_room_with_peer_id(peer_id)
  if room: 
    delete_room(room)

func send_message_to_peer(peer: Peer, message: Dictionary) -> void:
  var outgoing_string = JSON.stringify(message)
  var outgoing_bytes  = outgoing_string.to_utf8_buffer()
  peer.channel.put_packet(outgoing_bytes)

func send_message_to_peer_with_id(peer_id: int, message: Dictionary) -> void:
  var peer = _get_peer_with_id(peer_id)
  if peer:
    send_message_to_peer(peer, message)

func _random_peer_id(n: int = 6, pool="abcdef0123456789") -> int:
  var peer_id = ""
  for i in range(n):
    var random_i = randi() % pool.length()
    var random_c = pool[random_i]
    peer_id += random_c

  return peer_id.hex_to_int()

func _random_room_id(n: int = 6, pool="abcdefghijklmnopqrstuvwxyz0123456789") -> String:
  var room_id = ""
  for i in range(n):
    var random_i = randi() % pool.length()
    var random_c = pool[random_i]
    room_id += random_c
    
  return room_id

func _get_peer_with_id(peer_id: int   ) -> Peer:
  for peer in peers:
    if peer.peer_id == peer_id:
      return peer
  return null

func _get_room_with_id(room_id: String) -> Room:
  for room in rooms:
    if room.room_id == room_id:
      return room
  return null

func _get_room_with_peer_id(peer_id: int) -> Room:
  return null

func _get_room_with_host_id(host_id: int) -> Room:
  for room in rooms:
    if room.host_id == host_id:
      return room
  return null

func _unique_peer_id() -> int:
  var peer_id = _random_peer_id()
  while _get_peer_with_id(peer_id):
    peer_id   = _random_peer_id()
  return peer_id

func _unique_room_id() -> String:
  var room_id = _random_room_id()
  while _get_room_with_id(room_id):
    room_id   = _random_room_id()
  return room_id