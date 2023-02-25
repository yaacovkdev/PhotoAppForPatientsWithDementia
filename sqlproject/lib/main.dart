import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlproject/Mysql.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const MyHomePage(title: 'Database Connection Portion Of Project'),
      home: const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.username});

  final String title;
  final String username;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var db = Mysql();
  final ImagePicker _picker = ImagePicker();

  //method to select the imnage and upload to the database
  void _imageSelector(var uploadMethod) async {
    //Way to decide on weather to upload from the gallery or camera
    final XFile? image;
    if (uploadMethod == 1) {
      image = await _picker.pickImage(source: ImageSource.camera);
    } else {
      image = await _picker.pickImage(source: ImageSource.gallery);
    }

    //Return if no image is given
    if (image == null) return;

    //Read the bytes, and then encode into base64
    Uint8List bytes = await image.readAsBytes();
    String base64 = base64Encode(bytes);

    //Wait for connection to the database, then use the stored procedure to push the base64 image to the database
    db.getConnection().then((conn) async {
      await conn.query("call dementiaPatientApp.modifiedInsertPhoto(?, ?)",
          [widget.username, base64]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Gallery or Camera Upload',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            //Camera Uploading icon button
            TextButton.icon(
                onPressed: () {
                  _imageSelector(1);
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("Camera Upload")),
            //box for spacing
            const SizedBox(height: 20),
            //Gallery uploading icon
            TextButton.icon(
                onPressed: () {
                  _imageSelector(0);
                },
                icon: const Icon(Icons.photo_album_outlined),
                label: const Text("Gallery Upload")),
            const SizedBox(height: 30),
          ],
        ),
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
  String username = "";
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
          "select dementiaPatientApp.FamilyLogin(?, ?);", [username, password]);

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
                  title: 'Database Connection Portion Of Project', username: username,)),
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
              title: const Text('Incorrect Username'),
              content: const Text('Please enter a valid username'),
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
        title: const Text("Dimentia Upload Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Login To Upload',
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(
                height: 40,
              ),
              //Text field for the user name
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'User Name',
                  hintText: 'Enter Your Name',
                ),
                onChanged: (String text) {
                  username = text;
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
  String username = "";
  String password = "";
  String confirmedPassword = "";
  String fName = "";
  String lName = "";
  String patientID = "";
  String hospital = "";
  var db = Mysql();
  void _createAccount() async {
    int loginAnswer = 0;

    //First Check if the accounts are the same
    if (password != confirmedPassword) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Passwords Do Not Match'),
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
    }

    //Connect to DB and create account
    db.getConnection().then((conn) async {
      var temp = await conn.query(
          "select dementiaPatientApp.Create_Family_Member(?,?,?,?,?,?);",
          [username, fName, lName, patientID, password, hospital]);

      for (var rows in temp) {
        loginAnswer = rows[0];
      }
      //If the login answer is 1, the username is allready taken
      //If the answer is a 3, it is a sucess
      //if the answer is a 2 means that the patient does not exist
      if (loginAnswer == 3) {
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
      } else if (loginAnswer == 2) {
        //Wait to show the dialogue box that shows that you have inputted your password incorrectly
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Invalid Patient Information'),
              content: const Text(
                  'Make Sure the Patients ID and Hospital Name are correct'),
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
      } else if (loginAnswer == 1) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Invalid Username'),
              content: const Text(
                  'Username is allready taken, please choose another one'),
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

              //Username Field
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  hintText: 'Enter Your Username',
                ),
                onChanged: (String text) {
                  username = text;
                },
              ),
              const SizedBox(
                height: 10,
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
                height: 10,
              ),
              // Confirmation of password
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Confirm Password',
                  hintText: 'Enter Your Password',
                ),
                onChanged: (String text) {
                  confirmedPassword = text;
                },
              ),

              const SizedBox(
                height: 10,
              ),
              //Patients ID box
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Patient ID',
                  hintText: 'Enter The Patients IS',
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
