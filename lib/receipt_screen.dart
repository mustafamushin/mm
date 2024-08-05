import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  ReceiptScreen({required this.item});

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late TextEditingController _noteController;
  TextEditingController amountController = TextEditingController();
  double previousDebt = 0;
  double newTotal = 0;
  double total = 0;
  List<Map<String, dynamic>> payments = [];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item['note'] ?? '');
    previousDebt = widget.item['previousDebt'] ?? 0;
    newTotal = widget.item['total'] ?? 0;
    total = previousDebt + newTotal;
    payments = widget.item.containsKey('payments') ? List<Map<String, dynamic>>.from(widget.item['payments']) : [];
    amountController.text = '';
  }

  Future<void> _updateFirebase(Map<String, dynamic> data) async {
    final docRef = FirebaseFirestore.instance.collection('items').doc(widget.item['id']);
    await docRef.update(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              final updatedItem = {
                ...widget.item,
                'total': newTotal,
                'payments': payments,
                'note': _noteController.text,
              };
              await _updateFirebase(updatedItem);
              Navigator.pop(context, updatedItem);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item['name'] ?? '',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            SizedBox(height: 16),
            Text('Date: ${widget.item['date'] ?? ''}'),
            SizedBox(height: 8),
            Text('Total: \$${total.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _updateTotal(-1), // Withdraw
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _updateTotal(1), // Add
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '+',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              'Payments:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8),
                      title: Text('Amount: ${payment['amount'].toStringAsFixed(2)}'),
                      subtitle: Text('Date: ${payment['date']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateTotal(double amount) {
    setState(() {
      double amountValue = double.tryParse(amountController.text) ?? 0;
      if (amountValue != 0) {
        if (amount > 0) {
          // Adding amount
          newTotal += amountValue;
        } else {
          // Withdrawing amount
          newTotal -= amountValue;
          if (newTotal < 0) newTotal = 0; // Ensure total doesn't go negative
        }
        payments.add({
          'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          'amount': amountValue,
        });
        amountController.clear();
      }
    });
  }
}
