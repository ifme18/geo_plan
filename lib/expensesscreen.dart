import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _expenseTypeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  double totalExpenses = 0.0;

  void _addExpense() async {
    String expenseType = _expenseTypeController.text;
    double amount = double.parse(_amountController.text);
    String description = _descriptionController.text;

    // Save expense to Firestore
    await FirebaseFirestore.instance.collection('expenses').add({
      'type': expenseType,
      'amount': amount,
      'description': description,
      'date': Timestamp.now(),
    });

    // Clear input fields
    _expenseTypeController.clear();
    _amountController.clear();
    _descriptionController.clear();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Expense added successfully!")));

    // Recalculate total expenses
    _calculateTotalExpenses();
  }

  void _calculateTotalExpenses() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('expenses').get();
    totalExpenses = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as double));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _calculateTotalExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Expenses'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView( // Makes the entire screen scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Expense:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              // Expense Type Input
              _buildInputField(
                  controller: _expenseTypeController,
                  label: 'Expense Type',
                  icon: Icons.category
              ),

              SizedBox(height: 16),

              // Amount Input
              _buildInputField(
                  controller: _amountController,
                  label: 'Amount',
                  icon: Icons.attach_money,
                  inputType: TextInputType.number
              ),

              SizedBox(height: 16),

              // Description Input
              _buildInputField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description
              ),

              SizedBox(height: 24),

              // Save Expense Button
              Center(
                child: ElevatedButton(
                  onPressed: _addExpense,
                  child: Text('Save Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Total Expenses Display
              Center(
                child: Text(
                  'Total Expenses: KES ${totalExpenses.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),

              SizedBox(height: 16),

              // Expenses List
              _buildExpensesList(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.green[50],
      ),
    );
  }

  // Helper function to build expenses list from Firestore
  Widget _buildExpensesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading expenses"));
        }

        return ListView.builder(
          shrinkWrap: true, // Ensures the ListView works well inside a ScrollView
          physics: NeverScrollableScrollPhysics(), // Disables ListView's own scroll
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.attach_money, color: Colors.white),
                ),
                title: Text(doc['type'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Amount: KES ${doc['amount'].toStringAsFixed(2)}\nDescription: ${doc['description']}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

