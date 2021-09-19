import 'dart:async';

import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Participant {
  String? name;
  String? id;
  bool? isMuted;
  bool? isTalking;
  bool? isSelfMute;
  late Object? stream;
  late ion.LocalStream? localStream;
  bool me = false;
  bool remote;

  String get streamId => remote
      ? (stream as ion.RemoteStream).stream.id
      : (stream as ion.LocalStream).stream.id;

  MediaStream get mediaStream => remote
      ? (stream as ion.RemoteStream).stream
      : (stream as ion.LocalStream).stream;

  String get title => (remote ? 'Remote' : 'Local') + ' ' + streamId.substring(0, 8);

  Participant({
    this.name,
    this.id,
    this.stream,
    this.isMuted = false,
    this.isTalking = false,
    this.isSelfMute = false,
    this.remote = false,
  });

  Future<void> initialize() async {
  }

  void dispose() async {
    if (!remote) {
      await (stream as ion.LocalStream).unpublish();
      mediaStream.getTracks().forEach((element) {
        element.stop();
      });
      await mediaStream.dispose();
    }
  }


  void preferLayer(ion.Layer layer) {
    if (remote) {
      (stream as ion.RemoteStream).preferLayer?.call(layer);
    }
  }

  void mute(String kind) {
    if (remote) {
      (stream as ion.RemoteStream).mute?.call(kind);
    }
  }

  void unmute(String kind) {
    if (remote) {
      (stream as ion.RemoteStream).unmute?.call(kind);
    }
  }

  void getStats(ion.Client client, MediaStreamTrack track) async {
    var bytesPrev;
    var timestampPrev;
    Timer.periodic(Duration(seconds: 1), (timer) async {
      var results = await client.getSubStats(track);
      results.forEach((report) {
        var now = report.timestamp;
        var bitrate;
        if ((report.type == 'ssrc' || report.type == 'inbound-rtp') &&
            report.values['mediaType'] == 'video') {
          var bytes = report.values['bytesReceived'];
          if (timestampPrev != null) {
            bitrate = (8 *
                    (WebRTC.platformIsWeb
                        ? bytes - bytesPrev
                        : (int.tryParse(bytes)! - int.tryParse(bytesPrev)!))) /
                (now - timestampPrev);
            bitrate = bitrate.floor();
          }
          bytesPrev = bytes;
          timestampPrev = now;
        }
        if (bitrate != null) {
          print('$bitrate kbps');
        }
      });
    });
  }
}
