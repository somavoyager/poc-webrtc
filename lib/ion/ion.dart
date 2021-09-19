
import 'dart:developer';

import 'package:flutter_ion/flutter_ion.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../participant.dart';

class Ion {
  late String host;
  late String url;
  late Signal signal;

  late String room;
  late String user;
  late ion.Client? client;
  late ion.LocalStream? localStream;
  List<Participant> participants = [];
  late Function confChanged;
  Ion(String host, {Function? confChanged}) {
    this.host = host;
    this.url = 'http://$host:9090';
    confChanged = confChanged;
  }

  void connect() {
    this.signal = ion.GRPCWebSignal(this.url);
  }

  void close() {
    this.client!.close();
  }

  Future<void> join(String room, String user) async {
    this.room = room;
    this.user = user;
    this.client = await ion.Client.create(sid: room, uid: user, signal: this.signal);
    this.client!.ontrack = onTrack;
    this.client!.onspeaker = onTalking;
    this.client!.ondatachannel = onData;
    
    // create get user camera stream
    final constraints = Constraints(audio: true, video: false);
    localStream = await ion.LocalStream.getUserMedia(constraints: constraints);
    await this.client!.publish(localStream!);

    // localStream!.mute('audio');
    // localStream!.unmute('audio');
    
    final participant = Participant(name: user);
    participant.me = true;
    participant.localStream = localStream;
    participant.id = user;
    participants.add(participant);

    return;
  }

  void onTrack(track, ion.RemoteStream remoteStream) async {
    log('ION: User: ${remoteStream.id} joined the conference');
    if (remoteStream.id == user) {
      // continue
    }
    // remoteStream.mute!.call('audio');
    // remoteStream.unmute!.call('audio');

    final participant = Participant(name: remoteStream.id);
    participant.stream = remoteStream;
    participant.id = remoteStream.id;
    participants.add(participant);
    if (confChanged != null) {
      confChanged.call();
    }
    //userStreams[remoteStream.id] = participant;
  }

  void onTalking(Map<String, dynamic> speakers) {

  }

  void onData(RTCDataChannel channel) {
    
  }

  Participant? getParticipant(String user) {
    return participants.firstWhere((element) => element.name == user);
  }

  // void muteUser(String id) {
  //   final user = getParticipant(id);
  //   if (user?.mediaStream.mute != null) {
  //     user?.isMuted = true;
  //     user?.mediaStream.mute?.call('audio');
  //   }
  // }

  // void unmuteUser(String id) {
  //   final user = getParticipant(id);
  //   if (user?.ionStream.unmute != null) {
  //     user?.isMuted = false;
  //     user?.ionStream.unmute?.call('audio');
  //   }
  // }
}
