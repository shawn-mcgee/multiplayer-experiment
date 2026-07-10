class_name WebRtcSignalling

const HOST_ROOM          = "v1-host-room"
const HOST_ROOM_RESPONSE = "v1-host-room-response"

const JOIN_ROOM          = "v1-join-room"
const JOIN_ROOM_RESPONSE = "v1-join-room-response"

const WEBRTC_OFFER         = "v1-webrtc-offer"
const WEBRTC_ANSWER        = "v1-webrtc-answer"
const WEBRTC_ICE_CANDIDATE = "v1-webrtc-ice-candidate"

static func HostRoom():
  return {
    "is": HOST_ROOM
  }

static func HostRoomOk(peer_id: int, room_id: String):
  return {
    "is": HOST_ROOM_RESPONSE,
    "ok": true,
    "peer_id": peer_id,
    "room_id": room_id,
  }

static func JoinRoom(room_id: String):
  return {
    "is"      : JOIN_ROOM,
    "room_id": room_id
  }

static func JoinRoomOk(peer_id: int, host_id: int):
  return {
    "is": JOIN_ROOM_RESPONSE,
    "ok": true,
    "peer_id": peer_id,
    "host_id": host_id,
  }

static func JoinRoomError(error: String):
  return {
    "is": JOIN_ROOM_RESPONSE,
    "ok": false,
    "error": error
  }

static func WebRtcOffer (from: int, to: int, type: String, sdp: String):
  return {
    "is": WEBRTC_OFFER,
    "from": from,
    "to"  : to  ,
    "type": type,
    "sdp" : sdp
  }

static func WebRtcAnswer(from: int, to: int, type: String, sdp: String):
  return {
    "is": WEBRTC_ANSWER,
    "from": from,
    "to"  : to  ,
    "type": type,
    "sdp" : sdp
  }

static func WebRtcIceCandidate(from: int, to: int, media: String, index: int, name: String):
  return {
    "is": WEBRTC_ICE_CANDIDATE,
    "from" : from ,
    "to"   : to   ,
    "media": media,
    "index": index,
    "name" : name
  }

