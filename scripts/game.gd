extends Node2D

@onready var webrtc_start_ui = $WebRTC/Start
@onready var webrtc_host_ui  = $WebRTC/Host
@onready var webrtc_join_ui  = $WebRTC/Join

func _ready():
  webrtc_start_ui.show()
  webrtc_host_ui .hide()
  webrtc_join_ui .hide()

  

func _on_host_button_pressed() -> void:
  webrtc_start_ui.hide()
  webrtc_host_ui .show()
  _setup_host()

func _on_join_button_pressed() -> void:
  webrtc_start_ui.hide()
  webrtc_join_ui .show()
  _setup_join()


# HOST
var peer = WebRTCMultiplayerPeer.new()
var cx   = WebRTCPeerConnection .new()

func _process(_delta: float) -> void:
  cx.poll()

func _setup_host() -> void:
  print("Setting up host...")

  peer.create_server()
  peer.add_peer(cx, 2)

  cx.session_description_created.connect(
    func(type: String, sdp: String):
      cx.set_local_description(type, sdp)
      $WebRTC/Host/CenterContainer/VBoxContainer/OfferText.text = sdp
  )
  cx.ice_candidate_created.connect(
    func(media: String, index: int, name: String):
      var candidates_text = $WebRTC/Host/CenterContainer/VBoxContainer/OutgoingCandidates.text

      if candidates_text == "":
        candidates_text = "[]"

      var candidates = JSON.parse_string(candidates_text)

      candidates.push_back({
        "media": media,
        "index": index,
        "name": name
      })

      candidates_text = JSON.stringify(candidates)
      $WebRTC/Host/CenterContainer/VBoxContainer/OutgoingCandidates.text = candidates_text
  )

  print("Setting up host... done")

func _on_host_generate_offer_pressed() -> void:
  print("Generating offer...")
  var result = cx.create_offer()

  if result != OK:
    print("Generating offer... fail")
  else:
    print("Generating offer... done")

  # disable offer generation button to prevent multiple offers being generated
  $WebRTC/Host/CenterContainer/VBoxContainer/GenerateOffer.disabled = true

func _on_host_copy_offer_pressed() -> void:
  print("Copying offer...")
  var offer_text = $WebRTC/Host/CenterContainer/VBoxContainer/OfferText.text
  DisplayServer.clipboard_set(offer_text)
  print("Copying offer... done")

func _on_host_paste_answer_pressed() -> void:
  print("Pasting answer...")
  var answer_text = DisplayServer.clipboard_get()
  $WebRTC/Host/CenterContainer/VBoxContainer/AnswerText.text = answer_text
  print("Pasting answer... done")

func _on_host_generate_outgoing_candidates_pressed() -> void:
  print("Generating outgoing candidates...")

  var answer_text = $WebRTC/Host/CenterContainer/VBoxContainer/AnswerText.text
  cx.set_remote_description("answer", answer_text)

  print("Generating outgoing candidates... done")

  # disable answer generation button to prevent multiple answers being generated
  $WebRTC/Host/CenterContainer/VBoxContainer/GenerateOutgoingCandidates.disabled = true

func _on_host_copy_outgoing_candidates_pressed() -> void:
  print("Copying outgoing candidates...")
  var candidates_text = $WebRTC/Host/CenterContainer/VBoxContainer/OutgoingCandidates.text
  DisplayServer.clipboard_set(candidates_text)
  print("Copying outgoing candidates... done")

func _on_host_paste_candidates_pressed() -> void:
  print("Pasting incoming candidates...")
  var candidates_text = DisplayServer.clipboard_get()
  $WebRTC/Host/CenterContainer/VBoxContainer/IncomingCandidates.text = candidates_text
  print("Pasting incoming candidates... done")
  
func _on_host_connect_pressed() -> void:
  print("Connecting...")
  var candidates_text = $WebRTC/Host/CenterContainer/VBoxContainer/IncomingCandidates.text

  if candidates_text == "":
    candidates_text = "[]"

  var candidates = JSON.parse_string(candidates_text)

  for candidate in candidates:
    cx.add_ice_candidate(candidate["media"], candidate["index"], candidate["name"])

  print("Connecting... done")

  # disable connect button to prevent multiple connections being made
  $WebRTC/Host/CenterContainer/VBoxContainer/Connect.disabled = true

  multiplayer.multiplayer_peer = peer
  multiplayer.peer_connected.connect(spawn_player)
  spawn_player(multiplayer.get_unique_id())

  $WebRTC.hide()

# JOIN

func _setup_join() -> void:
  print("Setting up join...")

  peer.create_client(2)
  peer.add_peer(cx , 1)

  cx.session_description_created.connect(
    func(type: String, sdp: String):
      cx.set_local_description(type, sdp)
      $WebRTC/Join/CenterContainer/VBoxContainer/AnswerText.text = sdp
  )

  cx.ice_candidate_created.connect(
    func(media: String, index: int, name: String):
      var candidates_text = $WebRTC/Join/CenterContainer/VBoxContainer/OutgoingCandidates.text

      if candidates_text == "":
        candidates_text = "[]"

      var candidates = JSON.parse_string(candidates_text)

      candidates.push_back({
        "media": media,
        "index": index,
        "name": name
      })

      candidates_text = JSON.stringify(candidates)
      $WebRTC/Join/CenterContainer/VBoxContainer/OutgoingCandidates.text = candidates_text
  )

  print("Setting up join... done")

func _on_join_paste_offer_pressed() -> void:
  print("Pasting offer...")
  var offer_text = DisplayServer.clipboard_get()
  $WebRTC/Join/CenterContainer/VBoxContainer/OfferText.text = offer_text
  print("Pasting offer... done")

func _on_join_generate_answer_pressed() -> void:
  print("Generating answer...")

  var offer_text = $WebRTC/Join/CenterContainer/VBoxContainer/OfferText.text
  cx.set_remote_description("offer", offer_text)

  print("Generating answer... done")

  # disable answer generation button to prevent multiple answers being generated
  $WebRTC/Join/CenterContainer/VBoxContainer/GenerateAnswer.disabled = true

func _on_join_copy_answer_pressed() -> void:
  print("Copying answer...")
  var answer_text = $WebRTC/Join/CenterContainer/VBoxContainer/AnswerText.text
  DisplayServer.clipboard_set(answer_text)
  print("Copying answer... done")

func _on_join_generate_outgoing_candidates_pressed() -> void:
  pass

func _on_join_copy_outgoing_candidates_pressed() -> void:
  print("Copying outgoing candidates...")
  var candidates_text = $WebRTC/Join/CenterContainer/VBoxContainer/OutgoingCandidates.text
  DisplayServer.clipboard_set(candidates_text)
  print("Copying outgoing candidates... done")
  
func _on_join_paste_candidates_pressed() -> void:
  print("Pasting incoming candidates...")
  var candidates_text = DisplayServer.clipboard_get()
  $WebRTC/Join/CenterContainer/VBoxContainer/IncomingCandidates.text = candidates_text
  print("Pasting incoming candidates... done")

func _on_join_connect_pressed() -> void:
  print("Connecting...")
  var candidates_text = $WebRTC/Join/CenterContainer/VBoxContainer/IncomingCandidates.text

  if candidates_text == "":
    candidates_text = "[]"

  var candidates = JSON.parse_string(candidates_text)

  for candidate in candidates:
    cx.add_ice_candidate(candidate["media"], candidate["index"], candidate["name"])

  print("Connecting... done")

  # disable connect button to prevent multiple connections being made
  $WebRTC/Join/CenterContainer/VBoxContainer/Connect.disabled = true

  multiplayer.multiplayer_peer = peer

  $WebRTC.hide()

const PLAYER = preload("res://scenes/player.tscn")

func spawn_player(pid: int) -> void:
  var player = PLAYER.instantiate()
  player.name = str(pid)
  add_child(player)
