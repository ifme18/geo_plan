import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'AddClientScreen.dart';
import 'ExpensesScreen.dart';

class DashboardScreen extends StatelessWidget {
  Future<int> _getTotalClients() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('clients').get();
    return snapshot.docs.length;
  }

  Future<double> _getTotalExpenses() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('expenses').get();
    return snapshot.docs.fold<double>(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>?;
      // Safely cast amount to double if it exists and is numeric
      final amount = data != null && data.containsKey('amount')
          ? (data['amount'] is double ? data['amount'] as double : (data['amount'] as int).toDouble())
          : 0.0;
      return sum + amount;
    });
  }

  Future<double> _getPendingPayments() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('clients').get();
    double totalPending = 0.0;

    for (var doc in snapshot.docs) {
      final Map<String, dynamic> paymentStages = doc['paymentStages'] as Map<String, dynamic>;
      double clientPending = 0.0;

      // Iterate through the payment stages to find unpaid amounts
      paymentStages.forEach((stageName, stageData) {
        if (stageData['isPaid'] == false) {
          clientPending += stageData['amount'] is double
              ? stageData['amount'] as double
              : (stageData['amount'] as int).toDouble();
        }
      });

      totalPending += clientPending;
    }

    return totalPending;
  }

  // Method to calculate Total Paid Balance
  Future<double> _getTotalPaidBalance() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('clients').get();
    double totalPaid = 0.0;

    for (var doc in snapshot.docs) {
      final Map<String, dynamic> paymentStages = doc['paymentStages'] as Map<String, dynamic>;
      double clientPaid = 0.0;

      // Sum up all the payments that are marked as paid
      paymentStages.forEach((stageName, stageData) {
        if (stageData['isPaid'] == true) {
          clientPaid += stageData['amount'] is double
              ? stageData['amount'] as double
              : (stageData['amount'] as int).toDouble();
        }
      });

      totalPaid += clientPaid;
    }

    return totalPaid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Overview',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 24),
            FutureBuilder<int>(
              future: _getTotalClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error loading clients");
                }
                return _buildStyledCard(
                  title: 'Total Clients',
                  subtitle: '${snapshot.data}',
                  icon: Icons.group,
                  color: Colors.blueAccent,
                );
              },
            ),
            FutureBuilder<double>(
              future: _getTotalExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error loading expenses");
                }
                return _buildStyledCard(
                  title: 'Total Expenses',
                  subtitle: 'KES ${snapshot.data!.toStringAsFixed(2)}', // Changed to KES
                  icon: Icons.money_off,
                  color: Colors.redAccent,
                );
              },
            ),
            FutureBuilder<double>(
              future: _getPendingPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error loading pending payments");
                }
                return _buildStyledCard(
                  title: 'Pending Payments',
                  subtitle: 'KES ${snapshot.data!.toStringAsFixed(2)}', // Changed to KES
                  icon: Icons.pending,
                  color: Colors.orangeAccent,
                );
              },
            ),
            FutureBuilder<double>(
              future: _getTotalPaidBalance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error loading paid balance");
                }
                return _buildStyledCard(
                  title: 'Total Paid Balance',
                  subtitle: 'KES ${snapshot.data!.toStringAsFixed(2)}', // Changed to KES
                  icon: Icons.check_circle_outline,
                  color: Colors.greenAccent,
                );
              },
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildStyledButton(
                    context: context,
                    label: 'Add New Client',
                    icon: Icons.add,
                    color: Colors.green,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddClientScreen()));
                    },
                  ),
                ),
                SizedBox(width: 16), // Space between the buttons
                Expanded(
                  child: _buildStyledButton(
                    context: context,
                    label: 'Manage Expenses',
                    icon: Icons.receipt_long,
                    color: Colors.green,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ExpensesScreen()));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: color,
        elevation: 5,
      ),
    );
  }
}



