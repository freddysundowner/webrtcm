import 'package:flutter_webrtc/flutter_webrtc.dart';

class IceCandidateData {
  String? userId;
  String? name;
  RTCIceCandidate? candidate;

  IceCandidateData({this.userId, this.name, this.candidate});

  factory IceCandidateData.fromJson(dynamic json) {
    return IceCandidateData(
      candidate: RTCIceCandidate(
        json['candidate'],
        json['sdpMid'],
        json['sdpMLineIndex'],
      ),
    );
  }
}

class MessagePayload {
  String? type;
  dynamic data;

  MessagePayload({this.type, this.data});

  factory MessagePayload.fromJson(dynamic json) {
    return MessagePayload(type: json['type'], data: json['data']);
  }
}

class OfferSdpData {
  String? userId;
  String? name;
  RTCSessionDescription? sdp;

  OfferSdpData({this.userId, this.name, this.sdp});

  factory OfferSdpData.fromJson(dynamic json) {
    return OfferSdpData(
      sdp: RTCSessionDescription(json['sdp'], json['type']),
    );
  }
}

class VideoToggleData {
  String? userId;
  bool? videoEnabled;

  VideoToggleData({this.userId, this.videoEnabled});

  factory VideoToggleData.fromJson(dynamic json) {
    return VideoToggleData(
      userId: json['userId'],
      videoEnabled: json['videoEnabled'],
    );
  }
}

class AudioToggleData {
  String? userId;
  bool? audioEnabled;

  AudioToggleData({this.userId, this.audioEnabled});

  factory AudioToggleData.fromJson(dynamic json) {
    return AudioToggleData(
      userId: json['userId'],
      audioEnabled: json['audioEnabled'],
    );
  }
}
