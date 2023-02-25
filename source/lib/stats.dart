import 'package:dementia/Mysql.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen(
      {super.key, required this.patientID, required this.hospital});
  final String patientID;
  final String hospital;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String mostRecentPhoto = "";
  String minFamilyUploader = "";
  String maxFamilyUploader = "";

  var db = Mysql();
  void _downloadStats() async {
    //Connect to DB and search for most recent photo
    db.getConnection().then((conn) async {
      var temp = await conn.query(
          "call dementiaPatientApp.MostRecentPhoto(?,?);",
          [widget.patientID, widget.hospital]);
      for (var rows in temp) {
        mostRecentPhoto = rows[0];
      }
    });
    //connect to the DB and search for the maximum uploader
    db.getConnection().then((conn) async {
      var temp = await conn.query(
          "call dementiaPatientApp.countMaxFamilyMemberPhotoUploads(?,?);",
          [widget.patientID, widget.hospital]);
      for (var rows in temp) {
        maxFamilyUploader = rows[0].toString();
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    _downloadStats();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stats Screen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Some User Statisitics',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(
                height: 40,
              ),
              Text(
                'Latest Upload: $mostRecentPhoto',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(
                height: 40,
              ),
              Text(
                'Most Uploading Family Member: $maxFamilyUploader',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
