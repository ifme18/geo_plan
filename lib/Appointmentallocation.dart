import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DiaryScreen extends StatefulWidget {
  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedReminder = 0;
  List<Map<String, dynamic>> _events = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchEvents(); // Fetch events from Firestore when the screen initializes
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _fetchEvents() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('events').get();
    setState(() {
      _events = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'title': data['title'],
          'notes': data['notes'],
          'dateTime': (data['dateTime'] as Timestamp).toDate(),
          'phone': data['phone'],
          'completed': data['completed'] ?? false,
          'id': doc.id, // Add event ID for updates
        };
      }).toList();
    });
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _sendWhatsAppNotification(String phone, String message) async {
    const String accountSID = 'YOUR_TWILIO_ACCOUNT_SID';
    const String authToken = 'YOUR_TWILIO_AUTH_TOKEN';
    const String twilioNumber = 'whatsapp:+YOUR_TWILIO_WHATSAPP_NUMBER';

    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$accountSID:$authToken'))}';

    final response = await http.post(
      Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/$accountSID/Messages.json'),
      headers: <String, String>{
        'Authorization': basicAuth,
      },
      body: {
        'From': twilioNumber,
        'To': 'whatsapp:$phone',
        'Body': message,
      },
    );

    if (response.statusCode == 201) {
      print('WhatsApp message sent successfully.');
    } else {
      print('Failed to send WhatsApp message: ${response.statusCode}');
    }
  }

  void _addEvent() {
    if (_titleController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please complete all fields.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    DateTime eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    _scheduleNotification(eventDateTime, _titleController.text);

    if (_selectedReminder > 0) {
      DateTime reminderTime =
      eventDateTime.subtract(Duration(minutes: _selectedReminder));
      _scheduleNotification(reminderTime, 'Reminder: ${_titleController.text}');
      _sendWhatsAppNotification(
          _phoneController.text,
          'Reminder: ${_titleController.text} scheduled for ${DateFormat('yMMMd jm').format(reminderTime)}');
    }

    FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'notes': _notesController.text,
      'dateTime': eventDateTime,
      'phone': _phoneController.text,
      'completed': false,
    }).then((value) {
      _fetchEvents(); // Fetch events again to update the list
    });

    setState(() {
      _titleController.clear();
      _notesController.clear();
      _phoneController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _selectedReminder = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Event added successfully!'),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> _scheduleNotification(
      DateTime eventDateTime, String title) async {
    final tz.TZDateTime scheduledDate =
    tz.TZDateTime.from(eventDateTime, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      _generateNotificationId(),
      'Event Reminder: $title',
      'Your event is scheduled for ${DateFormat('jm').format(eventDateTime)}.',
      scheduledDate,
      platformChannelSpecifics,
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    DateTime eventTime = event['dateTime'];
    bool isCompleted = event['completed'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isCompleted ? Colors.orangeAccent : Colors.greenAccent,
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          event['title'],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          '${event['notes']}\n${DateFormat('yMMMd').format(eventTime)} - ${DateFormat('jm').format(eventTime)}',
        ),
        trailing: Checkbox(
          value: isCompleted,
          onChanged: (bool? value) {
            setState(() {
              _events[index]['completed'] = value; // Update local state
              // Update Firestore to reflect the completed status
              FirebaseFirestore.instance.collection('events').doc(event['id']).update({'completed': value});
            });
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Diary'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Event Title',
              icon: Icons.title,
            ),
            SizedBox(height: 10),
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              icon: Icons.notes,
            ),
            SizedBox(height: 10),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateTimeButton(
                    'Select Date',
                    _pickDate,
                    _selectedDate != null
                        ? DateFormat('yMMMd').format(_selectedDate!)
                        : 'Select Date'),
                _buildDateTimeButton(
                    'Select Time',
                    _pickTime,
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select Time'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addEvent,
              child: Text('Add Event'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_events[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimeButton(String label, VoidCallback onPressed, String display) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(display),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.grey[300], padding: EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}



