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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('clients').doc(widget.clientId).get(),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'LR No: $clientLRNo',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Remaining Balance: kes ${remainingBalance.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 24),

                // Payment Stages List
                Text(
                  'Payment Stages:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
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
                              FirebaseFirestore.instance.collection('clients').doc(widget.clientId).update({
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
              // Watermark in the background
              pw.Positioned(
                top: 200,
                left: 100,
                child: pw.Opacity(
                  opacity: 0.1,
                  child: pw.Text(
                    'Proforma Invoice',
                    style: pw.TextStyle(
                      fontSize: 60,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ),

              // Main content of the invoice
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header Section
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(logoImage, width: 80), // Company Logo
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('GEOPLAN KENYA LTD', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Kigio Plaza - Thika, 1st floor, No. K.1.16'),
                          pw.Text('P.O Box 522 - 00100 Thika'),
                          pw.Text('Tel: +254 721 256 135 / +254 724 404 133'),
                          pw.Text('Email: geoplankenya1@gmail.com'),
                          pw.Text('www.geoplankenya.co.ke'),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Invoice Title, Invoice Number, and Invoice Date
                  pw.Text('Proforma Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Invoice No: ${DateTime.now().millisecondsSinceEpoch}', style: pw.TextStyle(fontSize: 16)),
                      pw.Text('Invoice Date: $formattedDate', style: pw.TextStyle(fontSize: 16)), // Invoice Date
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Client Information
                  pw.Text('Client: $clientName', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('LR No: $clientLRNo', style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 20),

                  // Payment Summary
                  pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Remaining Balance: KES ${remainingBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 20),

                  // Payment Stages Table
                  pw.Text('Payment Stages:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Table.fromTextArray(
                    headers: ['Stage', 'Amount', 'Status'],
                    data: paymentStages.keys.map((stageName) {
                      final stageAmount = paymentStages[stageName]['amount'];
                      final isPaid = paymentStages[stageName]['isPaid'];

                      return [
                        stageName,
                        'KES ${stageAmount.toStringAsFixed(2)}',
                        isPaid ? 'Paid' : 'Unpaid',
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 30),

                  // Footer (Signature, Notes)
                  pw.Text('Authorized Signature:', style: pw.TextStyle(fontSize: 16)),
                  pw.Container(
                    width: 150,
                    height: 40,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    child: pw.Text('Signature here', textAlign: pw.TextAlign.center),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }


  // Method to load the image
  Future<pw.ImageProvider> _loadImage(String path) async {
    final ByteData bytes = await rootBundle.load(path);
    final Uint8List imageData = bytes.buffer.asUint8List();
    return pw.MemoryImage(imageData);
  }
}

