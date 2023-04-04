import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uuid/uuid.dart';

import 'models/models.dart';

class RoomPage extends StatefulWidget {
  dynamic room;
  dynamic id;
  RoomPage({super.key, this.room, this.id});

  @override
  State<RoomPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<RoomPage> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  String server = "http://192.168.0.103:3030";
  IO.Socket? socket;
  RTCPeerConnection? _peerConnection;

  var uuid = Uuid();
  String userid = '';
  MediaStream? _localStream;

  joinRoom(String room) {
    initRenderers();
    _getUserMedia().then((value) async {
      _peerConnection = await createConnection(value);
      if (_peerConnection != null) {
        initSocket();
      }
    });
  }

  Map<String, dynamic> configuration = {
    "sdpSemantics": "plan-b",
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
    ]
  };

  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  void initRenderers() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    joinRoom(widget.id.toString());
  }

  initSocket() async {
    userid = await loadUserId();
    print("server $server");
    try {
      socket = IO.io('$server?id=$userid&room=${widget.id}', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });
      socket!.connect();
      socket!.onConnect((data) => {print('Socket Connect: ${socket!.id}')});
      socket!.on("message", handleMessages);
      join();
    } catch (e) {
      print("error connecting");
      // initSocket();
    }
  }

  join() {
    var payload = {
      "type": "join-room",
      "data": {"userid": userid, "room": widget.id}
    };
    print(
      "sending $payload",
    );
    socket!.emit("message", payload);
  }

  void handleMessages(dynamic data) {
    var decodedData = jsonDecode(data);

    MessagePayload messagePayload = MessagePayload.fromJson(decodedData);
    if (messagePayload.type == "user-joined") {
      _createOffer();
    }
    if (messagePayload.type == "offer-sdp") {
      receivedOfferSdp(OfferSdpData.fromJson(messagePayload.data));
    }
    if (decodedData["type"] == "answer-sdp") {
      receivedAnserSdp(OfferSdpData.fromJson(messagePayload.data));
    }
    if (messagePayload.type == "icecandidate") {
      setCandidate(IceCandidateData.fromJson(messagePayload.data));
    }
    if (messagePayload.type == 'video-toggle') {
      listenVideoToggle(VideoToggleData.fromJson(messagePayload.data));
    }
    if (messagePayload.type == 'audio-toggle') {
      listenAudioToggle(AudioToggleData.fromJson(messagePayload.data));
    }
  }

  void listenVideoToggle(VideoToggleData data) {
    // final connection = getConnection(data.userId!);
    // _peerConnection.toggleVideo(data.videoEnabled!);
    // socket?.emit('connection-setting-changed');
  }

  void listenAudioToggle(AudioToggleData data) {
    // final connection = getConnection(data.userId!);
    // connection.toggleAudio(data.audioEnabled!);
    // socket?.emit('connection-setting-changed');
  }

  Future<void> setCandidate(IceCandidateData candidate) async {
    await _peerConnection!.addCandidate(candidate.candidate!);
  }

  void receivedAnserSdp(OfferSdpData data) async {
    if (_peerConnection != null) {
      await _peerConnection?.setRemoteDescription(data.sdp!);
    }
  }

  void receivedOfferSdp(OfferSdpData data) async {
    if (_peerConnection != null) {
      await _peerConnection?.setRemoteDescription(data.sdp!);
      await _createAnswer();
    }
  }

  Future<String> loadUserId() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var userId;
    if (preferences.containsKey("userId")) {
      userId = preferences.getString("userId");
    } else {
      userId = uuid.v4();
      preferences.setString("userId", userId);
    }
    return userId;
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    super.dispose();
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localVideoRenderer.srcObject = stream;
    _localStream = stream;
    setState(() {});
    return stream;
  }

  createConnection(MediaStream stream) async {
    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(stream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        socket!.emit("message", {
          "type": "icecandidate",
          "data": {
            "room": widget.id,
            'candidate': e.candidate,
            'sdpMid': e.sdpMid,
            'sdpMlineIndex': e.sdpMLineIndex
          }
        });
      }
    };

    pc.onIceConnectionState = (e) {
      RTCIceConnectionState connectionState = e;
      if (connectionState.name == "RTCIceConnectionStateDisconnected") {
        print("onIceConnectionState ${e.name}");

        _remoteVideoRenderer.srcObject = null;

        setState(() {});
      }
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
      setState(() {});
    };

    return pc;
  }

  void _createOffer() async {
    await _getUserMedia();
    _peerConnection = await createConnection(_localStream!);
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    socket!.emit("message",
        {"type": "offer-sdp", "room": widget.id, "data": description.toMap()});
    _peerConnection!.setLocalDescription(description);
  }

  Future _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
    socket!.emit("message",
        {"type": "answer-sdp", "room": widget.id, "data": description.toMap()});

    _peerConnection!.setLocalDescription(description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.room["title"]),
        ),
        body: Column(
          children: [
            videoRenderers(),
            ElevatedButton(
              onPressed: () {
                endRoom(widget.id);
                Navigator.pop(context);
              },
              child: const Text("End room"),
            ),
          ],
        ));
  }

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Row(children: [
          Flexible(
            child: Container(
              key: Key('local'),
              margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
          ),
          Flexible(
            child: Container(
              key: Key('remote'),
              margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteVideoRenderer),
            ),
          ),
        ]),
      );

  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();
    endRoom(widget.id);
  }

  void endRoom(id) {
    var payload = {
      "type": "leave-meeting",
      "data": {"userid": userid, "room": id}
    };
    if (socket != null) {
      socket!.emit("message", payload);
    }
    if (_localStream != null) {
      _localStream?.dispose();
      _localStream = null;
    }
    if (_peerConnection != null) {
      _peerConnection!.close();
      _peerConnection = null;
    }
  }
}
