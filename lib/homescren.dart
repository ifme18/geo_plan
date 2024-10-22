import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clientdetailscreen.dart';
import 'dashboard.dart'; // Import your DashboardScreen

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Geoplan Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Navigation Container
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard, size: 36, color: Colors.white),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View overall stats and reports',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Total Pending Balance and Paid Balance
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('clients').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading data"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  double totalPending = 0;
                  double totalPaid = 0;

                  // Calculate total pending and paid balance from clients
                  snapshot.data!.docs.forEach((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final pendingBalance = data?['pendingBalance'] ?? 0.0;
                    final paidBalance = data?['paidBalance'] ?? 0.0;
                    totalPending += pendingBalance;
                    totalPaid += paidBalance;
                  });

                  return Column(
                    children: [
                      BalanceContainer(
                        title: 'Total Pending Balance',
                        amount: totalPending,
                        color: Colors.redAccent,
                        icon: Icons.pending_actions,
                      ),
                      SizedBox(height: 16),
                      BalanceContainer(
                        title: 'Total Paid Balance',
                        amount: totalPaid,
                        color: Colors.greenAccent,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              // Clients Section
              Text(
                'Clients',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              // Client List
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('clients').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading data"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final clients = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      final data = client.data() as Map<String, dynamic>?;
                      final paymentStages = data?['paymentStages'] ?? {};

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            data?.containsKey('name') == true ? data!['name'] : 'No Name',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text('LR No: ${data?.containsKey('lrNo') == true ? data!['lrNo'] : 'N/A'}'),
                              SizedBox(height: 4),
                              // Safely display payment stages
                              Text('Downpayment: \$${(paymentStages['Downpayment']?['amount'] ?? 0).toStringAsFixed(2)}'),
                              Text('County Approval: \$${(paymentStages['County Approvals']?['amount'] ?? 0).toStringAsFixed(2)}'),
                              Text('Land Approval: \$${(paymentStages['Land Approvals']?['amount'] ?? 0).toStringAsFixed(2)}'),
                              Text('Title Payment: \$${(paymentStages['Title Payments']?['amount'] ?? 0).toStringAsFixed(2)}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pending: \$${(data?['pendingBalance'] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClientDetailScreen(clientId: client.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              Text(
                'Expenses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              // Expenses List
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading data"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data!.docs;

                  return Column(
                    children: expenses.map((expense) {
                      final expenseData = expense.data() as Map<String, dynamic>?;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            expenseData?.containsKey('name') == true ? expenseData!['name'] : 'Unnamed Expense',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          trailing: Text(
                            '\$${(expenseData?['amount'] ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: (expenseData?['isPaid'] ?? false) ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// BalanceContainer widget used above for displaying balance details
class BalanceContainer extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  BalanceContainer({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: Colors.white),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

