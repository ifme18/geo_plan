import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:io'; // For mobile and desktop platforms
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QuotationScreen extends StatefulWidget {
  @override
  _QuotationScreenState createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _recipientController = TextEditingController();
  final _signatoryController = TextEditingController();
  final _paymentTermsController = TextEditingController();

  List<Map<String, dynamic>> items = [
    {'item': '', 'description': '', 'quantity': 1, 'unitCost': 0.0, 'amount': 0.0},
  ];

  DateTime _quotationDate = DateTime.now();
  double _totalAmount = 0.0;
  double _vatAmount = 0.0;
  double _totalAmountWithVat = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Quotation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[100],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        color: Colors.blueGrey[50],
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _paymentTermsController,
                decoration: InputDecoration(
                  labelText: 'Payment Terms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey[400]),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(),
              ),
              Divider(color: Colors.grey[400]),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: Ksh ${_totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'VAT (16%): Ksh ${_vatAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Total with VAT: Ksh ${_totalAmountWithVat.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addNewItem,
                child: Text('Add New Item'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400],
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _signatoryController,
                decoration: InputDecoration(
                  labelText: 'Signatory Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateAndSavePdf,
                child: Text('Save Quotation Locally'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sharePdf,
                child: Text('Share Quotation'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.teal[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      columns: [
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Unit Cost (Ksh)')),
        DataColumn(label: Text('Amount (Ksh)')),
      ],
      rows: items.map((item) {
        return DataRow(cells: [
          DataCell(TextFormField(
            onChanged: (value) {
              setState(() {
                item['item'] = value;
              });
            },
          )),
          DataCell(TextFormField(
            onChanged: (value) {
              setState(() {
                item['description'] = value;
              });
            },
          )),
          DataCell(TextFormField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                item['quantity'] = int.tryParse(value) ?? 1;
                _updateAmount(item);
              });
            },
          )),
          DataCell(TextFormField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                item['unitCost'] = double.tryParse(value) ?? 0.0;
                _updateAmount(item);
              });
            },
          )),
          DataCell(Text(item['amount'].toStringAsFixed(2))),
        ]);
      }).toList(),
    );
  }

  void _updateAmount(Map<String, dynamic> item) {
    setState(() {
      item['amount'] = item['quantity'] * item['unitCost'];
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    _totalAmount = items.fold(0.0, (sum, item) => sum + item['amount']);
    _vatAmount = _totalAmount * 0.16;
    _totalAmountWithVat = _totalAmount + _vatAmount;
  }

  void _addNewItem() {
    setState(() {
      items.add({'item': '', 'description': '', 'quantity': 1, 'unitCost': 0.0, 'amount': 0.0});
    });
  }

  Future<String> _generateAndSavePdf() async {
    final pdf = pw.Document();

    // Build the PDF with all the details
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildLetterHead(), // Call your letterhead builder

              pw.SizedBox(height: 20),

              pw.Text('Quotation', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Text('To: ${_recipientController.text}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Date: ${_quotationDate.toString().substring(0, 10)}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),

              pw.Text('Payment Terms: ${_paymentTermsController.text}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),

              pw.Text('Items:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _buildItemTable(), // Build the dynamic item table

              pw.SizedBox(height: 20),

              pw.Text('Total Amount: Ksh ${_totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('VAT (16%): Ksh ${_vatAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Total with VAT: Ksh ${_totalAmountWithVat.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),

              _buildFooter(), // Add your footer content

              pw.SizedBox(height: 20),

              pw.Text('Signatory: ${_signatoryController.text}', style: pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    if (kIsWeb) {
      // Web: Save and download the PDF
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'quotation_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      return ''; // No need for a file path on the web
    } else {
      // Mobile: Save the PDF locally
      final output = await getApplicationDocumentsDirectory();
      final filePath = "${output.path}/quotation_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    }
  }

  // Function to build the dynamic item table for the PDF
  pw.Widget _buildItemTable() {
    return pw.Table.fromTextArray(
      headers: ['Item', 'Description', 'Quantity', 'Unit Cost (Ksh)', 'Amount (Ksh)'],
      data: items.map((item) {
        return [
          item['item'],
          item['description'],
          item['quantity'].toString(),
          item['unitCost'].toStringAsFixed(2),
          item['amount'].toStringAsFixed(2),
        ];
      }).toList(),
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
      },
    );
  }

  Future<void> _sharePdf() async {
    final filePath = await _generateAndSavePdf();

    if (kIsWeb) {
      // Web: Share the PDF
      final bytes = await File(filePath).readAsBytes();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'quotation_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: Share the PDF using the share_plus package
      Share.shareFiles([filePath], text: 'Here is the quotation you requested.');
    }
  }

  pw.Widget _buildLetterHead() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'GEOPLAN KENYA LTD',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Kigio Plaza - Thika, 1st floor, No. K.1.16'),
        pw.Text('Uniafric House - Nairobi, 4th floor, No. 458'),
        pw.Text('P.O Box 522 - 00100 Thika'),
        pw.Text('Tel: +254 721 256 135 / +254 724 404 133'),
        pw.Text('Email: geoplankenya1@gmail.com, info@geoplankenya.co.ke'),
        pw.Text('www.geoplankenya.co.ke'),
      ],
    );
  }


  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
    );
  }
}




void main() {
  runApp(MaterialApp(home: QuotationScreen()));
}