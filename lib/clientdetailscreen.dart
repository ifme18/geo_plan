import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailScreen({Key? key, required this.clientId}) : super(key: key);

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  double remainingBalance = 0.0;
  Map<String, dynamic> paymentStages = {};
  String clientName = '';
  String clientLRNo = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Client Details'),
        backgroundColor: Colors.green,
        elevation: 0, // Removes shadow under AppBar
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('clients')
                  .doc(widget.clientId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading client data",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                final clientData =
                snapshot.data!.data() as Map<String, dynamic>;
                remainingBalance = clientData['pendingBalance'];
                paymentStages =
                clientData['paymentStages'] as Map<String, dynamic>;
                clientName = clientData['name'];
                clientLRNo = clientData['lrNo'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Information',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border:
                        Border.all(color: Colors.green, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: $clientName',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'LR No: $clientLRNo',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Overall Remaining Balance: KES ${remainingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Payment Stages',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: ListView.builder(
                        itemCount: paymentStages.length,
                        itemBuilder: (context, index) {
                          final stageName =
                          paymentStages.keys.elementAt(index);
                          final stageData =
                          paymentStages[stageName];
                          final stageAmount =
                          stageData['amount'];
                          final paidAmount =
                              stageData['paidAmount'] ?? 0.0;
                          final remainingStageBalance =
                              stageAmount - paidAmount;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                vertical: 4.0),
                            child: ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                stageName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount: KES ${stageAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.black54),
                                  ),
                                  Text(
                                    'Paid Amount: KES ${paidAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.green),
                                  ),
                                  Text(
                                    'Remaining Balance: KES ${remainingStageBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.attach_money),
                                color: Colors.green,
                                onPressed: () => _showDepositDialog(
                                    stageName,
                                    remainingStageBalance),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: _generateAndShareInvoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Generate and Share Invoice',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDepositDialog(
      String stageName, double remainingStageBalance) async {
    final TextEditingController _amountController =
    TextEditingController();
    final TextEditingController _dateController =
    TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Make a Deposit for $stageName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Deposit Date',
                ),
                keyboardType: TextInputType.datetime,
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate =
                  await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _dateController.text =
                    "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                double depositAmount =
                    double.tryParse(
                        _amountController.text) ??
                        0.0;
                if (depositAmount > 0 &&
                    depositAmount <=
                        remainingStageBalance) {
                  setState(() {
                    paymentStages[stageName]['paidAmount'] =
                        (paymentStages[stageName]
                        ['paidAmount'] ??
                            0.0) +
                            depositAmount;
                    remainingBalance -= depositAmount;
                  });

                  await FirebaseFirestore.instance
                      .collection('clients')
                      .doc(widget.clientId)
                      .update({
                    'paymentStages.$stageName.paidAmount':
                    paymentStages[stageName]
                    ['paidAmount'],
                    'paymentStages.$stageName.depositDate':
                    _dateController.text,
                    'pendingBalance': remainingBalance,
                  });

                  Navigator.of(context).pop();
                } else {
                  // Optionally, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Invalid deposit amount.'),
                    ),
                  );
                }
              },
              child: const Text('Deposit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAndShareInvoice() async {
    final pdf = await _createInvoicePdf();

    // Save PDF to a temporary directory
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/Invoice.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Share the PDF file using share_plus
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Here is your invoice.',
    );
  }

  Future<pw.Document> _createInvoicePdf() async {
    final pdf = pw.Document();
    final logoImage =
    await _loadImage('assets/images/Untitled design.jpg');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.stretch,
            children: [
              // Header with Logo and Company Information
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                color: PdfColors.green600,
                child: pw.Row(
                  mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage,
                          width: 80, height: 80),
                    pw.Column(
                      crossAxisAlignment:
                      pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Your Company Name',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight:
                            pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          '1234 Street Address',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'City, Country',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Phone: +123 456 7890',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Invoice Title
              pw.Center(
                child: pw.Text(
                  'Invoice',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green600,
                  ),
                ),
              ),
              pw.Divider(
                  thickness: 1.5,
                  color: PdfColors.green),
              pw.SizedBox(height: 16),

              // Client Information Section
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColors.green, width: 1),
                  borderRadius:
                  pw.BorderRadius.circular(4),
                  color: PdfColors.green50,
                ),
                child: pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Client Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight:
                        pw.FontWeight.bold,
                        color: PdfColors.green600,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Client Name: $clientName',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'LR No: $clientLRNo',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Payment Stages Header
              pw.Text(
                'Payment Stages',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green600,
                ),
              ),
              pw.SizedBox(height: 8),

              // Payment Stages List
              ...paymentStages.entries.map((entry) {
                final stageName = entry.key;
                final stageData = entry.value;
                final stageAmount = stageData['amount'];
                final paidAmount =
                    stageData['paidAmount'] ?? 0.0;
                final remainingStageBalance =
                    stageAmount - paidAmount;
                final depositDate =
                    stageData['depositDate'] ?? 'N/A';

                return pw.Container(
                  padding:
                  const pw.EdgeInsets.all(8),
                  margin: const pw.EdgeInsets.symmetric(
                      vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: PdfColors.grey300,
                        width: 0.5),
                    borderRadius:
                    pw.BorderRadius.circular(4),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Column(
                    crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        stageName,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight:
                          pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Amount: KES ${stageAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            color: PdfColors.black),
                      ),
                      pw.Text(
                        'Paid Amount: KES ${paidAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            color: PdfColors.green600),
                      ),
                      pw.Text(
                        'Remaining Balance: KES ${remainingStageBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            color: PdfColors.red),
                      ),
                      pw.Text(
                        'Deposit Date: $depositDate',
                        style: pw.TextStyle(
                            color: PdfColors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Spacer to push footer to bottom
              pw.Spacer(),

              // Footer with Thank You Note
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green600,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'If you have any questions, feel free to contact us.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<pw.MemoryImage?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }
}
