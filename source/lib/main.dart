import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:async/async.dart';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:dementia/Mysql.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dementia/stats.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dementia',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      required this.title,
      required this.hospital,
      required this.patientID});

  final String title;
  final String hospital;
  final String patientID;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool light = false;

  var db = Mysql();
  static int _counter = 0;
  int _images = 1;

  final List<String> _imageAddresses = [];

  var rotator;

  @override
  void initState() {
    super.initState();
    platformBrightness();
    _imagedownload();

    //Basic version so far
    rotator = new RestartableTimer(new Duration(minutes: 15), _incrementCounter);
  }

  void _incrementCounter() {
    //counter that resets to 0 if it reaches 3
    rotator.reset();
    _counter++;
    _counter %= _images;
    setState(() {});
  }

  void _imagedownload() {
    db.getConnection().then((conn) async {
      var result1 = await conn.query(
          'call dementiaPatientApp.PatientPhotoSelect(?, ?);',
          [widget.patientID, widget.hospital]);

      int imagefilen = 0;

      for (var row in result1) {
        String tostr = row[0].toString();

        final Directory dir = await getApplicationDocumentsDirectory();

        String direct = dir.path + '/images';
        Directory(direct).create();
        File('$direct/pic$imagefilen.jpg').writeAsBytes(base64Decode(tostr));
        _imageAddresses.add('$direct/pic$imagefilen.jpg');
        imagefilen++;
      }
      _images = _imageAddresses.length;
      setState(() {});
    });
  }

  //Romain
  Future<void> platformBrightness() async {
    double bright;

    FlutterScreenWake.keepOn(true);

    if (!mounted) return;

    if (!light) {
      FlutterScreenWake.setBrightness(1.0);
      light = true;
    } else {
      FlutterScreenWake.setBrightness(0.05);
      light = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var now = DateTime.now();
    var formattedTime = DateFormat('h:mm a').format(now);
    var formattedDate = DateFormat('EEE, d MMM').format(now);

    double screenwidth = MediaQuery.of(context).size.width;
    double screenheight = MediaQuery.of(context).size.height;

    double margin = 20;

    //Easier to preload images this way
    Image image;
    if (_imageAddresses.isEmpty) {
      image = Image.asset('images/pic0.jpg');
    } else {
      image = Image.file(
        File(_imageAddresses[_counter]),
        fit: BoxFit.contain,
      );
    }

    Container imageContainer = Container(
      width: screenwidth,
      height: screenheight * 0.73,
      child: image,
    );

    //rot.cancel();
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: <Widget>[
            Container(
                margin: EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(formattedTime, style: const TextStyle(fontSize: 32)),
                    Text(formattedDate, style: const TextStyle(fontSize: 24)),
                  ],
                )),
            Container(
                margin: EdgeInsets.all(margin),
                child: InkWell(
                  onTap: () => _incrementCounter(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      imageContainer
                      //  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                      //[_imageAddresses[_counter]],
                    ],
                  ),
                )),
          ],
        ),
        floatingActionButton:
            SpeedDial(icon: Icons.add, backgroundColor: Colors.blue, children: [
          SpeedDialChild(
            child: const Icon(Icons.logout, color: Colors.white),
            label: 'Logout',
            backgroundColor: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.query_stats, color: Colors.white),
            label: 'Stats Page',
            backgroundColor: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StatsScreen(
                          patientID: widget.patientID,
                          hospital: widget.hospital,
                        )),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.light_mode, color: Colors.white),
            label: 'Dim Screen',
            backgroundColor: Colors.blueAccent,
            onTap: platformBrightness,
          ),
        ]),
      ),
    );
  }
}

//The following code is all for the login screen portion of the code. is is made of a
// simple centered column with padding that contains textboxes and a button with some
//sizedboxes as padding in between
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String hospital = "";
  String id = "";
  String password = "";
  var db = Mysql();

  //If there is not a network connection when trying to login, return this as invalid.
  void _checkConectionAndLogin() async {
    var result = await (Connectivity().checkConnectivity());
    if (result != ConnectivityResult.wifi &&
        result != ConnectivityResult.mobile) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content:
                const Text('Exiting the App, try connecting and try again'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      _loginFunction();
    }
  }

//Checks the user credentials and lets them into the app if they have valid credentials
  void _loginFunction() async {
    int loginAnswer = 0;
    db.getConnection().then((conn) async {
      var temp = await conn.query(
          "select dementiaPatientApp.PWDLogin(?, ?, ?);",
          [hospital, password, id]);

      for (var rows in temp) {
        loginAnswer = rows[0];
      }
      //If the login answer is 1, its a sucess
      //If the answer is a 3, it is an invalid username
      //if the answer is a 2 means that the user is valid, but there is not a valid password
      if (loginAnswer == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              title: 'Photo View',
              hospital: hospital,
              patientID: id,
            ),
          ),
        );
      } else if (loginAnswer == 2) {
        //Wait to show the dialogue box that shows that you have inputted your password incorrectly
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Incorrect Password'),
              content: const Text('Try checking your password and try again'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('User Does not Exist'),
              content: const Text('Pleasee Check Hospital and ID number'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Patient Terminal'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //Text field for the user name
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Hospital Name',
                  hintText: 'Enter The Hospitals Name',
                ),
                onChanged: (String text) {
                  hospital = text;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              //Text field for the password
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter Your Password',
                ),
                onChanged: (String text) {
                  password = text;
                },
              ),

              const SizedBox(
                height: 20,
              ),
              //Text field for the user name
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Patient ID',
                  hintText: 'Enter The Patients ID number',
                ),
                onChanged: (String text) {
                  id = text;
                },
              ),
              //Text button for transitioning to the next screen of the app
              //Row contains the two buttons, one for login, and the other is for the creation of an account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //New Account Button
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreateAccountScreen()),
                        );
                      },
                      child: const Text(
                        "Create Account",
                        style: TextStyle(fontSize: 20),
                      )),

                  const SizedBox(
                    width: 40,
                  ),
                  //Login Button
                  TextButton(
                      onPressed: () {
                        //Call function to check login
                        _checkConectionAndLogin();
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(fontSize: 20),
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

//Statefull widget contains the screen for creating a new account for the user
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  String fName = "";
  String lName = "";
  String patientID = "";
  String hospital = "";
  String bdate = "";

  var db = Mysql();
  void _createAccount() async {
    int loginAnswer = 0;

    //Connect to DB and create account
    db.getConnection().then((conn) async {
      var temp = await conn.query(
          "select dementiaPatientApp.Create_Patient(?, ?, ?, ?, ?);",
          [patientID, hospital, fName, lName, bdate]);

      for (var rows in temp) {
        loginAnswer = rows[0];
      }
      //If the login answer is 1, the username is allready taken
      //If the answer is a 3, it is a sucess
      //if the answer is a 2 means that the patient does not exist
      if (loginAnswer == 0) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Account Created!'),
              content: const Text('Redirecting to Login Screen'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else if (loginAnswer == 1) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('User Allready Exists'),
              content: const Text('Try entering a new user'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create User Account"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // const Text(
              //   'Create User Account',
              //   style: TextStyle(fontSize: 30),
              // ),
              // const SizedBox(
              //   height: 30,
              // ),
              //First Name Field
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'First Name',
                  hintText: 'Enter Your Name',
                ),
                onChanged: (String text) {
                  fName = text;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              //Last name Field
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Last Name',
                  hintText: 'Enter Your Surname',
                ),
                onChanged: (String text) {
                  lName = text;
                },
              ),
              const SizedBox(
                height: 10,
              ),

              const SizedBox(
                height: 10,
              ),
              //Patients ID box
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Patient ID',
                  hintText: 'Enter The Patients ID',
                ),
                onChanged: (String text) {
                  patientID = text;
                },
              ),

              const SizedBox(
                height: 10,
              ),

              //enter the patients hospital
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Hospital',
                  hintText: 'Enter The Patients Hospital',
                ),
                onChanged: (String text) {
                  hospital = text;
                },
              ),
              TextButton(
                  onPressed: () {
                    DatePicker.showDatePicker(context,
                        showTitleActions: true,
                        theme: const DatePickerTheme(
                            headerColor: Colors.orange,
                            backgroundColor: Colors.blue,
                            itemStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                            doneStyle:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        onConfirm: (date) {
                      bdate = date.toString();
                    }, currentTime: DateTime.now(), locale: LocaleType.en);
                  },
                  child: const Text(
                    'Pick User Birth Date',
                    style: TextStyle(color: Colors.blue, fontSize: 30),
                  )),

              //Text button for creating account and transitioning to next page
              TextButton(
                  onPressed: () {
                    //Call function to check login
                    _createAccount();
                  },
                  child: const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 20),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
