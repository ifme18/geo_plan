import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                final clientData = snapshot.data!.data() as Map<String, dynamic>;
                remainingBalance = clientData['pendingBalance'];
                paymentStages = clientData['paymentStages'] as Map<String, dynamic>;
                clientName = clientData['name'];
                clientLRNo = clientData['lrNo'];

                return Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Information',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Remaining Balance: KES ${remainingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Payment Stages',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: ListView.builder(
                            itemCount: paymentStages.length,
                            itemBuilder: (context, index) {
                              final stageName = paymentStages.keys.elementAt(index);
                              final stageAmount = paymentStages[stageName]['amount'];
                              final isPaid = paymentStages[stageName]['isPaid'];

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
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
                                  subtitle: Text(
                                    'Amount: KES ${stageAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  trailing: Checkbox(
                                    value: isPaid,
                                    activeColor: Colors.green,
                                    onChanged: (value) {
                                      setState(() {
                                        paymentStages[stageName]['isPaid'] = value;
                                        remainingBalance +=
                                        value! ? -stageAmount : stageAmount;
                                        FirebaseFirestore.instance
                                            .collection('clients')
                                            .doc(widget.clientId)
                                            .update({
                                          'paymentStages.$stageName.isPaid': value,
                                          'pendingBalance': remainingBalance,
                                        });
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
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
                              borderRadius: BorderRadius.circular(8),
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndShareInvoice() async {
    final pdf = await _createInvoicePdf();

    final output = await pdf.save();
    final directory = await Directory.systemTemp.createTemp();
    final file = File('${directory.path}/invoice.pdf');
    await file.writeAsBytes(output);

    await Share.shareXFiles([XFile(file.path)], text: 'Here is the invoice.');
  }

  Future<pw.Document> _createInvoicePdf() async {
    final pdf = pw.Document();
    final logoImage = await _loadImage('assets/images/Untitled design.png');
    final invoiceDate = DateTime.now();
    final formattedDate =
        '${invoiceDate.day}-${invoiceDate.month}-${invoiceDate.year}';

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                top: 200,
                left: 100,
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Text(
                    'Geoplan LTD',
                    style: pw.TextStyle(
                      fontSize: 60,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green, width: 2),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(logoImage, width: 150, height: 150),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'GEOPLAN KENYA LTD',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green,
                              ),
                            ),
                            pw.Text(
                              'Kigio Plaza - Thika, 1st floor, No. K.1.16',
                              style: pw.TextStyle(color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'P.O Box 522 - 00100 Thika',
                              style: pw.TextStyle(color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'Tel: +254 721 256 135 / +254 724 404 133',
                              style: pw.TextStyle(color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'Email: geoplankenya1@gmail.com',
                              style: pw.TextStyle(color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'www.geoplankenya.co.ke',
                              style: pw.TextStyle(color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Proforma Invoice',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Invoice No: ${DateTime.now().millisecondsSinceEpoch}',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        'Invoice Date: $formattedDate',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      border: pw.Border.all(color: PdfColors.green, width: 1),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Client Name: $clientName',
                          style: pw.TextStyle(fontSize: 16),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'LR No: $clientLRNo',
                          style: pw.TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Payment Stages:',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Stage',
                              style: pw.TextStyle(fontSize: 16),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Amount (KES)',
                              style: pw.TextStyle(fontSize: 16),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Paid Status',
                              style: pw.TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      ...paymentStages.entries.map(
                            (entry) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(entry.key),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                entry.value['amount'].toStringAsFixed(2),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                entry.value['isPaid'] ? 'Paid' : 'Unpaid',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Remaining Balance: KES ${remainingBalance.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.redAccent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<pw.ImageProvider> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.MemoryImage(data.buffer.asUint8List());
  }
}
