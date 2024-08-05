import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  AddEditScreen({required this.initialData});

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialData.isNotEmpty) {
      nameController.text = widget.initialData['name'];
      amountController.text = widget.initialData['total']?.toString() ?? '';
      noteController.text = widget.initialData['note'] ?? '';
      selectedDate = DateFormat('yyyy-MM-dd HH:mm').parse(widget.initialData['date']);
    }
  }

  Future<void> _saveToFirebase(Map<String, dynamic> data) async {
    final docRef = FirebaseFirestore.instance.collection('items').doc();
    await docRef.set(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add/Edit Item'),
        backgroundColor: Colors.teal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Total',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a total amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    double total = double.tryParse(amountController.text) ?? 0;
                    double previousDebt = widget.initialData.containsKey('previousDebt')
                        ? widget.initialData['previousDebt']
                        : 0;

                    final data = {
                      'name': nameController.text,
                      'date': DateFormat('yyyy-MM-dd HH:mm').format(selectedDate),
                      'total': total + previousDebt,
                      'previousDebt': previousDebt,
                      'note': noteController.text,
                    };

                    await _saveToFirebase(data);
                    Navigator.pop(context, data);
                  }
                },
                child: Text('Calculate & Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
