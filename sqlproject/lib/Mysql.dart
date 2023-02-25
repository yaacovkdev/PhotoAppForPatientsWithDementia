//File to make the methods used to set up and connect the database to the application
import 'package:mysql1/mysql1.dart';

class Mysql {
  //Static settings for the database
  //removed login credentials, change these for your database
  static String host =
          'databaseaddress',
      user = 'user',
      db = "database",
      password = 'password';
  static int port = 8888;

  Mysql();

  //Define the getConneciton method which connects to the database for file transfer
  Future<MySqlConnection> getConnection() async {
    var settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );
    return await MySqlConnection.connect(settings);
  }
}
