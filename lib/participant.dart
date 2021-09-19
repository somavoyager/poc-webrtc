import 'package:flutter_ion/flutter_ion.dart' as ion;

class Participant {
  String? name;
  String? id;
  bool? isMuted;
  bool? isTalking;
  bool? isSelfMute;
  late ion.RemoteStream ionStream;
  late ion.LocalStream? localStream;
  bool me = false;
  
  Participant({
    this.name,
    this.id,
    this.isMuted = false,
    this.isTalking = false,
    this.isSelfMute = false,
  });
}
