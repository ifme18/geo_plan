import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'homescren.dart'; // Your HomeScreen file
import 'addclientscreen.dart'; // Your Add Client Screen file
import 'expensesscreen.dart'; // Your Add Expense Screen file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBdj0apmOp6lTlf7sMpBDldFp8WB70iRkg",
      authDomain: "test-2618d.firebaseapp.com",
      databaseURL: "https://test-2618d-default-rtdb.firebaseio.com",
      projectId: "test-2618d",
      storageBucket: "test-2618d.appspot.com",
      messagingSenderId: "347431242639",
      appId: "1:347431242639:web:e2f1ba1f4584fd8bfed9fa"
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geoplan Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.green, // Matches your theme preference
      ),
      home: HomeScreen(),
      routes: {
        '/add-client': (context) => AddClientScreen(),
        '/add-expense': (context) =>  ExpensesScreen(),
      },
    );
  }
}
