import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // For web downloading
import 'package:printing/printing.dart'; // For mobile/desktop printing
import 'package:flutter/services.dart'; // For loading assets

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  ClientDetailScreen({required this.clientId});

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
      appBar: AppBar(
        title: Text('Client Details'),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final padding = screenWidth * 0.05;
          final fontSizeTitle = screenWidth * 0.05;
          final fontSizeBody = screenWidth * 0.04;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('clients')
                  .doc(widget.clientId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading client data"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Extracting data
                final clientData = snapshot.data!.data() as Map<String, dynamic>;
                remainingBalance = clientData['pendingBalance'];
                paymentStages = clientData['paymentStages'] as Map<String, dynamic>;
                clientName = clientData['name'];
                clientLRNo = clientData['lrNo'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Information
                    Text(
                      'Client: $clientName',
                      style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: padding / 2),
                    Text(
                      'LR No: $clientLRNo',
                      style: TextStyle(fontSize: fontSizeBody),
                    ),
                    SizedBox(height: padding),
                    Text(
                      'Remaining Balance: KES ${remainingBalance.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: fontSizeTitle, color: Colors.redAccent),
                    ),
                    SizedBox(height: padding),

                    // Payment Stages List
                    Text(
                      'Payment Stages:',
                      style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: padding / 2),
                    Expanded(
                      child: ListView.builder(
                        itemCount: paymentStages.length,
                        itemBuilder: (context, index) {
                          final stageName = paymentStages.keys.elementAt(index);
                          final stageAmount = paymentStages[stageName]['amount'];
                          final isPaid = paymentStages[stageName]['isPaid'];

                          return ListTile(
                            title: Text(stageName),
                            subtitle: Text('Amount: KES ${stageAmount.toStringAsFixed(2)}'),
                            trailing: Checkbox(
                              value: isPaid,
                              onChanged: (value) {
                                setState(() {
                                  // Update payment status locally first
                                  paymentStages[stageName]['isPaid'] = value;

                                  // Adjust remaining balance
                                  if (value == true) {
                                    remainingBalance -= stageAmount;
                                  } else {
                                    remainingBalance += stageAmount;
                                  }

                                  // Update Firestore with new data
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
                          );
                        },
                      ),
                    ),

                    // Generate Invoice Button
                    ElevatedButton(
                      onPressed: _generateInvoice,
                      child: Text('Generate Invoice'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Method to generate the PDF Invoice and handle platform-specific behavior
  void _generateInvoice() async {
    final pdf = await _createInvoicePdf();

    if (kIsWeb) {
      // For Web: Save as a Blob and provide a download link
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'invoice.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For Mobile/Desktop: Use printing package to preview/print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  // Method to create the PDF content
  Future<pw.Document> _createInvoicePdf() async {
    final pdf = pw.Document();

    // Load the logo image
    final logoImage = await _loadImage('assets/images/Untitled design.png');

    // Current date for the invoice
    final invoiceDate = DateTime.now();
    final formattedDate = '${invoiceDate.day}-${invoiceDate.month}-${invoiceDate.year}';

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
                  // Header Section
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green, width: 2),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(logoImage, width: 150, height: 150), // Company Logo
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('GEOPLAN KENYA LTD', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                            pw.Text('Kigio Plaza - Thika, 1st floor, No. K.1.16', style: pw.TextStyle(color: PdfColors.grey700)),
                            pw.Text('P.O Box 522 - 00100 Thika', style: pw.TextStyle(color: PdfColors.grey700)),
                            pw.Text('Tel: +254 721 256 135 / +254 724 404 133', style: pw.TextStyle(color: PdfColors.grey700)),
                            pw.Text('Email: geoplankenya1@gmail.com', style: pw.TextStyle(color: PdfColors.grey700)),
                            pw.Text('www.geoplankenya.co.ke', style: pw.TextStyle(color: PdfColors.grey700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Invoice Title, Invoice Number, and Invoice Date
                  pw.Text('Proforma Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Invoice No: ${DateTime.now().millisecondsSinceEpoch}', style: pw.TextStyle(fontSize: 16)),
                      pw.Text('Invoice Date: $formattedDate', style: pw.TextStyle(fontSize: 16)), // Invoice Date
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Client Information
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
                        pw.Text('Client: $clientName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text('LR No: $clientLRNo', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Payment Summary
                  pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headers: ['Stage', 'Amount (KES)', 'Status'],
                    data: paymentStages.entries.map((entry) {
                      final stageName = entry.key;
                      final stageData = entry.value as Map<String, dynamic>;
                      final amount = stageData['amount'].toStringAsFixed(2);
                      final isPaid = stageData['isPaid'] == true ? 'Paid' : 'Pending';

                      return [stageName, amount, isPaid];
                    }).toList(),
                    border: pw.TableBorder.all(color: PdfColors.green, width: 1),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.green100),
                    cellPadding: pw.EdgeInsets.all(5),
                  ),
                  pw.SizedBox(height: 20),

                  // Remaining Balance
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      border: pw.Border.all(color: PdfColors.red, width: 1),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text('Remaining Balance: KES ${remainingBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, color: PdfColors.red)),
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

  // Helper function to load image
  Future<pw.ImageProvider> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  }
}

