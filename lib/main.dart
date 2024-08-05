import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_edit_screen.dart';
import 'receipt_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontFamily: 'NRT'),
          displayMedium: TextStyle(fontFamily: 'NRT'),
          bodyLarge: TextStyle(fontFamily: 'NRT'),
          bodyMedium: TextStyle(fontFamily: 'NRT'),
        ),
        fontFamily: 'NRT', // Set default font
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('items').get();
    setState(() {
      items = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      filteredItems = items;
    });
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = items.where((item) {
        return item['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  double _calculateTotal(Map<String, dynamic> item) {
    double previousDebt = item.containsKey('previousDebt') ? item['previousDebt'] ?? 0 : 0;
    double newTotal = item.containsKey('total') ? item['total'] ?? 0 : 0;
    return previousDebt + newTotal;
  }

  double _calculateMonthlyDebtAdded() {
    DateTime now = DateTime.now();
    return items
        .where((item) {
          String? date = item['date'];
          return date != null && DateFormat('yyyy-MM').format(DateFormat('yyyy-MM-dd HH:mm').parse(date)) == DateFormat('yyyy-MM').format(now);
        })
        .map((item) => item['total'] ?? 0)
        .fold(0.0, (previousValue, element) => previousValue + element);
  }

  double _calculateMonthlyDebtReceived() {
    DateTime now = DateTime.now();
    return items
        .where((item) {
          String? date = item['date'];
          return date != null && DateFormat('yyyy-MM').format(DateFormat('yyyy-MM-dd HH:mm').parse(date)) == DateFormat('yyyy-MM').format(now);
        })
        .map((item) {
          List<dynamic>? payments = item['payments'];
          return payments?.fold(0.0, (prev, payment) => prev + (payment['amount'] ?? 0)) ?? 0;
        })
        .fold(0.0, (previousValue, element) => previousValue + element);
  }

  Future<void> _saveItem(Map<String, dynamic> item) async {
    await FirebaseFirestore.instance.collection('items').doc(item['id']).set(item);
    _fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 40,
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '....گەڕان',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.blue),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.blue),
                      onPressed: () {
                        _searchController.clear();
                        _filterItems('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterItems,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Items'),
            Tab(text: 'Monthly Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(),
          _buildMonthlyStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditScreen(initialData: {})),
          );
          if (result != null) {
            await _saveItem(result);
            _filterItems(_searchController.text);
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        elevation: 8,
        tooltip: 'Add New Item',
      ),
    );
  }

  Widget _buildItemsTab() {
    return Container(
      color: Colors.white, // Background color for the main content
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            double total = _calculateTotal(item);

            return Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    item['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    'Date: ${item['date'] ?? ''}\nTotal: ${total.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiptScreen(item: item),
                        ),
                      );
                      if (result != null) {
                        await _saveItem(result);
                        _filterItems(_searchController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text('Edit', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthlyStatsTab() {
    double monthlyDebtAdded = _calculateMonthlyDebtAdded();
    double monthlyDebtReceived = _calculateMonthlyDebtReceived();
    return Container(
      color: Colors.white, // Background color for the main content
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'NRT'),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Debt Added:', style: TextStyle(fontSize: 18, fontFamily: 'NRT')),
                Text('\$${monthlyDebtAdded.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontFamily: 'NRT')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Debt Received:', style: TextStyle(fontSize: 18, fontFamily: 'NRT')),
                Text('\$${monthlyDebtReceived.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontFamily: 'NRT')),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Debt Change:', style: TextStyle(fontSize: 18, fontFamily: 'NRT')),
                Text('\$${(monthlyDebtAdded - monthlyDebtReceived).toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontFamily: 'NRT')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
