import 'dart:convert';
import 'dart:developer';
import 'package:uuid/uuid.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart';
final iceServers = [
  RTCIceServer(
      url: "stun:stun2.l.google.com:19302",
      username: "",
      credential: "")
];

final defaultIceServer = {
  "urls": "stun:stun2.l.google.com:19302",
  "username": "",
  "credential": "",
};

const constraints = {
  'audio': true,
  'video': false
};

var configuration = {
  'iceServers': [],
  'iceTransportPolicy': 'relay',
  'bundlePolicy': 'max-bundle',
  'rtcpMuxPolicy': 'require',
  'sdpSemantics': 'unified-plan'
};

class KrakenClient {
  late Uri url;
  RTCPeerConnection? pc;
  late Uuid uuid;
  late String ucid;
  late String room;
  late String user;
  late int userId;
  late Map<String, dynamic> trickleMap;
  KrakenClient(String host) {
    url = Uri.parse('http://${host}:7000');
    pc = null;
    uuid = Uuid();
    ucid = '';
  }

  Future<Map<String, dynamic>?> rpc(String method, dynamic params) async {
    try {
      var headers = {
        'Content-Type': 'application/json'
      };
      var body = {
        'id': uuid.v1(),
        'method': method,
        'params': params,
      };
      var json = jsonEncode(body);
      final result = await post(url, headers: headers, body: json);
      log('RPC method: ${method} params: ${jsonEncode(params)} result: ${result.body}');
      return jsonDecode(result.body);
    } catch (err) {
      log('RPC method: ${method} params: ${jsonEncode(params)} Error: ${err.toString()}');
      return null;
    }
  } 

  close() {
    pc!.close();
  }

  join(String room, String user, int userId) async {
    Map<String, dynamic> configuration = Map<String, dynamic>();
    try {
      var params = [user];
      final servers = await rpc('turn', params);
      if (servers?['data'] != null) {
        configuration['iceServers'] = servers?['data'];
      } else {
      }
      //configuration['iceServers'] = [ defaultIceServer ];
    } catch (err) {
      log('failed to get server ${err.toString}');
      configuration['iceServers'] = [ defaultIceServer ];
    }
    configuration.putIfAbsent('sdpSemantics', () => 'unified-plan');
    pc = await createPeerConnection(configuration, {});
    assert(pc != null);
    log('RTC: created peer connection');

    pc!.onTrack = (RTCTrackEvent event) async {
      log('RTC: Track: ${event.toString()}');
        //if (event.streams == null || event.transceiver == null) return;
      var mid = event.transceiver == null ? event.transceiver!.mid : event.track.id;
      final stream = event.streams[0];
      final sid = stream.id;
      final toks = sid.split(':');
      final id = int.parse(toks[0]);
      final name = toks[1];
      if (id == userId) {
        // current user
        return;
      }
      if (event.track.onEnded == null) return;
        event.track.onEnded = () async {
          log('Track $name ended');
        };
        event.track.onMute = () async {
          log('Track $name muted');
          // handle on mute
          // remove the track
        };
      };
    pc!.onConnectionState = (state) {
      log('RTC: Connection state: ${state.toString()}');
    };

    pc!.onIceCandidate = (RTCIceCandidate candidate) async {
      log('RTC: onIceCandidate start ucid: $ucid');
      final candidateMap = candidate.toMap();
      trickleMap = candidateMap;
      final json = jsonEncode(candidateMap);
      if (ucid == '') {
        log('***** trickle track id is not found');
      } else {
        final result = await rpc('trickle', [room, user, ucid, json]);
        log('RTC: trickle response: ${jsonEncode(result)}');
        log('***** trickle result: ${jsonEncode(result)}');
      }
      log('RTC: onIceCandidate end');
    };
    log('RTC: attaching user media');
    // get user media and connect
    final localStream = await navigator.mediaDevices.getUserMedia(constraints);
    late MediaStreamTrack audioTrack;
    audioTrack = localStream.getAudioTracks()[0];
    for(final track in localStream.getTracks()) {
      audioTrack = track;
      //pc!.addTrack(track, localStream);
    }
    addTracks(audioTrack);
    final offer = await pc!.createOffer({
      'audio': true,
      'video': false
    });
    await pc!.setLocalDescription(offer);
    final localDesc = await pc!.getLocalDescription();
    final localDescMap = jsonEncode(localDesc!.toMap());
    log('RTC: publishing user media local: ${localDescMap}');
    final res = await rpc('publish', [room, user, localDescMap]);
    log('RTC: publishing user media done');
    log('publish result: ${res.toString()}');

    this.room = room;
    this.user = user;
    this.userId = userId;
    if (res!.containsKey('data')) { 
      // restart connection
      final String jesp = res['data']['jsep'];
      if(res['data']['sdp']['type'] == 'answer') {
        final sdp = res['data']['sdp']['sdp'];
        final type = res['data']['sdp']['type'];
        RTCSessionDescription sessionDescription = RTCSessionDescription(sdp, type);
        await pc!.setRemoteDescription(sessionDescription);

        ucid = res['data']['track'];
        addTracks(audioTrack);
        log('RTC: media is attached');

        final json = jsonEncode(trickleMap);
        final result = await rpc('trickle', [room, user, ucid, json]);
        log('RTC: trickle response: ${jsonEncode(result)}');

        // restart the connection
        // final restartRes = await rpc('restart', [room, user, ucid, jesp]);
        // log('RTC: restartRes: ${jsonEncode(restartRes)}');

        log('RTC: subscribing to the connection');
        // subscribe(pc!);
      }
    }
  }

  addTracks(MediaStreamTrack audioTrack) async {
    RTCRtpTransceiver? audioTransceiver;
    final transceivers = await pc!.transceivers;
    for(final t in transceivers) {
      if (t.sender != null && t.receiver != null) {
        if (t.sender.track?.kind == 'audio' ||
            t.receiver.track?.kind == 'audio') {
          audioTransceiver = t;
          break;
        }
      }
    }
    if (audioTransceiver != null) {
      pc!.addTransceiver(
          track: audioTrack,
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(
              direction: TransceiverDirection.SendRecv,
              streams: []));
    }
  }

  subscribe (RTCPeerConnection pc) async {
    final res = await rpc('subscribe', [room, user, ucid]);
    if (res != null) {
      if (res.containsKey('error')) {
        // try to reconnect to the server
        Future.delayed(Duration(milliseconds: 3000), () {
          subscribe(pc);
        });
      } else if (res.containsKey('offer')) {
        log('subscribe offer ${res["data"]}');
        final sdp = res['data']['sdp']['sdp'];
        final type = res['data']['sdp']['type'];

        RTCSessionDescription sessionDescription = RTCSessionDescription(sdp, type);
        await pc.setRemoteDescription(sessionDescription);
        final offer = await pc.createAnswer({
          "audio": true,
          "video": false
        });
        await pc.setLocalDescription(offer);
        await rpc('answer', [room, user, ucid, jsonEncode(offer.toMap())]);
      } else {
        // Future.delayed(Duration(milliseconds: 3000), () {
        //   subscribe(pc);
        // });
      }
    } 
  }
}


class RTCIceServer {
  String username;
  String credential;
  String url;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  RTCIceServer({
    required this.username,
    required this.credential,
    required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RTCIceServer &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          credential == other.credential &&
          url == other.url);

  @override
  int get hashCode => username.hashCode ^ credential.hashCode ^ url.hashCode;

  @override
  String toString() {
    return 'RTCIceServer{' +
        ' username: $username,' +
        ' credential: $credential,' +
        ' url: $url,' +
        '}';
  }

  RTCIceServer copyWith({
    required String username,
    required String credential,
    required String url,
  }) {
    return new RTCIceServer(
      username: username,
      credential: credential,
      url: url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': this.username,
      'credential': this.credential,
      'url': this.url,
    };
  }

  factory RTCIceServer.fromMap(Map<String, dynamic> map) {
    return new RTCIceServer(
      username: map['username'] as String,
      credential: map['credential'] as String,
      url: map['url'] as String,
    );
  }

//</editor-fold>
}
