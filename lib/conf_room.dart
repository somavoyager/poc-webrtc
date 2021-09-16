import 'dart:developer';

import 'package:flutter/material.dart';

class ConferenceRoom extends StatefulWidget {
  const ConferenceRoom({Key? key, String? username}) : super(key: key);

  @override
  _ConferenceRoomState createState() => _ConferenceRoomState();
}

class _ConferenceRoomState extends State<ConferenceRoom> {
  bool _allMuted = false;
  List<Participant> list = [
    Participant(
      id: "1",
      name: "Roger",
    ),
    Participant(
      id: "2",
      name: "Novak",
    ),
    Participant(
      id: "3",
      name: "Zverev",
    ),
    Participant(
      id: "4",
      name: "Rafael",
    ),
    Participant(
      id: "5",
      name: "Daniel",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Conference Room"),
        ),
        body: _buildListOfParticipants(context),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              _muteAll();
            },
            child: Icon(_allMuted ? Icons.mic_off : Icons.mic)),
      ),
    );
  }

  _muteAll() {
    for (Participant p in list) {
      p.isMuted = !_allMuted;
    }
    _allMuted = !_allMuted;
    setState(() {});
  }

  _buildListOfParticipants(BuildContext context) {
    return GridView.builder(
      itemCount: list.length,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: (context, index) =>
          _buildOneParticipant(list[index], context),
    );
  }

  _buildOneParticipant(Participant participant, BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.lightBlueAccent.shade100,
            Colors.lightGreenAccent.shade100,
          ],
        ),
        border: Border.all(
          color: Colors.grey,
        ),
        color: Colors.black.withOpacity(0.1),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              "${participant.name}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Positioned(
            child: Text("${participant.id}"),
            bottom: 8,
            left: 8,
          ),
          Positioned(
            child: IconButton(
              onPressed: () {
                log("MIC TAPPED");
                participant.isMuted = !(participant.isMuted ?? false);
                setState(() {});
              },
              icon: participant.isMuted ?? false
                  ? Icon(Icons.mic_off)
                  : Icon(Icons.mic),
            ),
            top: 8,
            right: 8,
          ),
        ],
      ),
    );
  }
}

class Participant {
  String? name;
  String? id;
  bool? isMuted;
  bool? isTalking;
  bool? isSelfMute;

  Participant({
    this.name,
    this.id,
    this.isMuted = false,
    this.isTalking = false,
    this.isSelfMute = false,
  });
}
