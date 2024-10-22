import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddClientScreen extends StatefulWidget {
  @override
  _AddClientScreenState createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lrNoController = TextEditingController();

  // Payment stage controllers
  final TextEditingController _downpaymentController = TextEditingController();
  final TextEditingController _countyApprovalController = TextEditingController();
  final TextEditingController _landApprovalController = TextEditingController();
  final TextEditingController _titlePaymentController = TextEditingController();

  void _addClient() async {
    String name = _nameController.text;
    String lrNo = _lrNoController.text;

    // Payment stages
    Map<String, dynamic> paymentStages = {
      "Downpayment": {
        "amount": double.parse(_downpaymentController.text),
        "isPaid": false,
      },
      "County Approvals": {
        "amount": double.parse(_countyApprovalController.text),
        "isPaid": false,
      },
      "Land Approvals": {
        "amount": double.parse(_landApprovalController.text),
        "isPaid": false,
      },
      "Title Payments": {
        "amount": double.parse(_titlePaymentController.text),
        "isPaid": false,
      }
    };

    // Calculate total pending balance
    double totalPendingBalance = paymentStages.values.fold(0, (sum, stage) => sum + stage['amount']);

    // Save client data to Firestore
    await FirebaseFirestore.instance.collection('clients').add({
      'name': name,
      'lrNo': lrNo,
      'paymentStages': paymentStages,
      'pendingBalance': totalPendingBalance,
    });

    // Clear input fields
    _nameController.clear();
    _lrNoController.clear();
    _downpaymentController.clear();
    _countyApprovalController.clear();
    _landApprovalController.clear();
    _titlePaymentController.clear();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Client added successfully!")));

    // Optionally navigate back or clear fields
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Client'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Client Name',
              hintText: 'Enter client name',
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _lrNoController,
              label: 'LR No',
              hintText: 'Enter LR number',
            ),
            SizedBox(height: 24),
            Text(
              'Payment Stages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _downpaymentController,
              label: 'Downpayment Amount',
              hintText: 'Enter downpayment',
              isNumber: true,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _countyApprovalController,
              label: 'County Approval Amount',
              hintText: 'Enter county approval amount',
              isNumber: true,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _landApprovalController,
              label: 'Land Approval Amount',
              hintText: 'Enter land approval amount',
              isNumber: true,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _titlePaymentController,
              label: 'Title Payment Amount',
              hintText: 'Enter title payment amount',
              isNumber: true,
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _addClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Save Client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
    required String hintText,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}


