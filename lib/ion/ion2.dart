import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../participant.dart';
// go build ./cmd/signal/grpc/main.go && ./main -c config.toml -a 67.205.136.63:7000
class Config {
  static bool simulcast = true;
  static String resolution = 'hd';
  static String codec = 'vp8';
  static String host = '192.168.0.107';
  static String get ion_cluster_url => 'http://' + host + ':5551';
  static String get ion_sfu_url => 'http://' + host + ':7000';
  static ion.Constraints get defaultConstraints => ion.Constraints(
    audio: true,
    video: false
  );
}

class Ion2 {
  late ion.IonBaseConnector _connector;
  ion.IonSDKSFU? _rtc;
  final String _uid = Uuid().v4();
  late String room;
  late String name;
  late Function? onConfChange;
  final List<Participant> participants = [];
  void init() {
    _connector = ion.IonBaseConnector(Config.ion_sfu_url);
  }

  Future<void> join(String room, String name) async {
    if (_rtc == null) {
      this.room = room;
      this.name = name;
      _rtc = new ion.IonSDKSFU(_connector);
      _rtc!.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == 'audio') {
          print('ontrack: remote stream => ${remoteStream.id}');
          participants.add(Participant(name: remoteStream.id, id: remoteStream.id, stream: remoteStream, remote: true)..initialize());
          this.onConfChange?.call();
        }
      };
      await _rtc!.connect();
      await _rtc!.join(room, _uid);
      var localStream = await ion.LocalStream.getUserMedia(
          constraints: Config.defaultConstraints);
      await _rtc!.publish(localStream);
      participants.add(Participant(id: name, name: name, stream: localStream, remote: false)..initialize());
      return;
    } else {
      _rtc?.close();

      participants.forEach((element) {
        element.dispose();
      });

      participants.clear();
      _rtc = null;
    }
  }

  void leave() {
    if (participants.length == 0) {
      return;
    }
    // find me 
    final me = participants.firstWhere((element) => element.id == name);
    if (me != null) {
      for(int i = 0; i < participants.length; i++) {
        if (participants[i].id == me.id) {
          participants.removeAt(i);
          break;
        }
      }
      me.dispose();
    }
  }

  void close() {
    leave();
  }
}