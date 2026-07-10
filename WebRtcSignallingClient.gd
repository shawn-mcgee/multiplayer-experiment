class_name WebRtcSignallingClient 
extends Node



@export var url: String = "ws://localhost:8080"

signal available()

signal host_room_response(message: Dictionary)
signal join_room_response(message: Dictionary)
signal webrtc_offer        (message: Dictionary)
signal webrtc_answer       (message: Dictionary)
signal webrtc_ice_candidate(message: Dictionary)

var is_available: bool = false
var ws = WebSocketPeer.new()

func _ready():
  var error = ws.connect_to_url(url)
  if error != OK:
    print("[WebRTCSignallingClient] Error connecting to '%s': %s" % [url, ws.get_error_string(error)])
  else:
    print("[WebRTCSignallingClient] Connected to '%s'." % url)

func host_room():
  print("[WebRTCSignallingClient] Sending %s to signalling server." % WebRtcSignalling.HOST_ROOM)
  send_message(WebRtcSignalling.HostRoom())

func join_room(room_id: String):
  print("[WebRTCSignallingClient] Sending %s to signalling server." % WebRtcSignalling.JOIN_ROOM)
  send_message(WebRtcSignalling.JoinRoom(room_id))

func _process(_delta) -> void:
  ws.poll()

  match ws.get_ready_state():
    WebSocketPeer.STATE_OPEN  :
      if !is_available:
        is_available = true
        available . emit( )
        
      if ws.get_available_packet_count() > 0:
        var incoming_bytes   = ws.get_packet()
        var incoming_string  = incoming_bytes.get_string_from_utf8()
        var incoming_message = JSON.parse_string(incoming_string)

        _handle_incoming_message(incoming_message)

    WebSocketPeer.STATE_CLOSED:
      pass

func _handle_incoming_message(message: Dictionary) -> void:
  match message.is:
    WebRtcSignalling.HOST_ROOM_RESPONSE:
      print("[WebRTCSignallingClient] Received %s from signalling server." % WebRtcSignalling.HOST_ROOM_RESPONSE)
      host_room_response.emit(message)
    WebRtcSignalling.JOIN_ROOM_RESPONSE:
      print("[WebRTCSignallingClient] Received %s from signalling server." % WebRtcSignalling.JOIN_ROOM_RESPONSE)
      join_room_response.emit(message)
    WebRtcSignalling.WEBRTC_OFFER:
      print("[WebRTCSignallingClient] Received %s from signalling server." % WebRtcSignalling.WEBRTC_OFFER)
      webrtc_offer.emit(message)
    WebRtcSignalling.WEBRTC_ANSWER:
      print("[WebRTCSignallingClient] Received %s from signalling server." % WebRtcSignalling.WEBRTC_ANSWER)
      webrtc_answer.emit(message)
    WebRtcSignalling.WEBRTC_ICE_CANDIDATE:
      print("[WebRTCSignallingClient] Received %s from signalling server." % WebRtcSignalling.WEBRTC_ICE_CANDIDATE)
      webrtc_ice_candidate.emit(message)

func send_message(message: Dictionary) -> void:
  var outgoing_string = JSON.stringify(message)
  var outgoing_bytes  = outgoing_string.to_utf8_buffer()
  ws.put_packet(outgoing_bytes)

