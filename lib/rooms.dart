import 'package:flutter/material.dart';
import 'package:webrtc/room_page.dart';

class Rooms extends StatefulWidget {
  const Rooms({Key? key}) : super(key: key);

  @override
  State<Rooms> createState() => _RoomsState();
}

class _RoomsState extends State<Rooms> {
  List rooms = [
    {
      "title": "test",
      "hostId": "cc5b9ca8-23a8-444e-a7a3-1e3b27c7f026",
      "owner": "phone"
    },
    {
      "title": "test",
      "hostId": "cc5b9ca8-23a8-444e-a7a3-1e3b27c7f026",
      "owner": "phone"
    },
    {
      "title": "test",
      "hostId": "cc5b9ca8-23a8-444e-a7a3-1e3b27c7f026",
      "owner": "phone"
    },
    {
      "title": "test",
      "hostId": "cc5b9ca8-23a8-444e-a7a3-1e3b27c7f026",
      "owner": "phone"
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (BuildContext context, int i) {
            return InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RoomPage(room: rooms[i], id: i)));
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), color: Colors.grey),
                margin: EdgeInsets.only(bottom: 30, top: 20),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [Text(rooms[i]["title"]), Text(rooms[i]["owner"])],
                ),
              ),
            );
          }),
    );
  }
}
