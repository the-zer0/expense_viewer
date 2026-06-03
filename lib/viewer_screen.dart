import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  String filterType = 'All';
  String filterCategory = 'All';

  final indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  final List<String> categories = [
    'All', 'Food', 'Travel', 'Stay', 'Shopping', 'Entertainment', 'Other'
  ];
  final List<String> types = ['All', 'Income', 'Expense'];

  List<QueryDocumentSnapshot> applyFilters(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final docType = data['type']?.toString() ?? 'expense';

      final matchType = filterType == 'All' ||
          (filterType == 'Income' && docType == 'income') ||
          (filterType == 'Expense' && docType == 'expense');

      final matchCategory = filterCategory == 'All' ||
          data['category']?.toString() == filterCategory;

      return matchType && matchCategory;
    }).toList();
  }

  double getTotalBalance(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
      return data['type'] == 'income' ? sum + amount : sum - amount;
    });
  }

  double getTotalIncome(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['type'] != 'income') return sum;
      return sum + (double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0);
    });
  }

  double getTotalExpense(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['type'] != 'expense') return sum;
      return sum + (double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Viewer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.hasData
              ? snapshot.data!.docs
              : <QueryDocumentSnapshot>[];
          final filtered = applyFilters(allDocs);
          final balance = getTotalBalance(allDocs);
          final totalIncome = getTotalIncome(allDocs);
          final totalExpense = getTotalExpense(allDocs);

          return Column(
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primary,
                child: Column(
                  children: [
                    Text(
                      indianFormat.format(balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        color: Colors.greenAccent, size: 16),
                                    SizedBox(width: 4),
                                    Text('Income',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  indianFormat.format(totalIncome),
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_upward,
                                        color: Colors.redAccent, size: 16),
                                    SizedBox(width: 4),
                                    Text('Expenses',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  indianFormat.format(totalExpense),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filters
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filterType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: types
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => filterType = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filterCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => filterCategory = val!),
                      ),
                    ),
                  ],
                ),
              ),

              // Count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No transactions found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index].data()
                              as Map<String, dynamic>? ?? {};
                          final isIncome = data['type'] == 'income';
                          final ts = data['timestamp'] as Timestamp?;
                          final formatted = ts != null
                              ? DateFormat('dd MMM yyyy, h:mm a')
                                  .format(ts.toDate())
                              : 'Saving...';
                          final amount = double.tryParse(
                                  data['amount']?.toString() ?? '0') ??
                              0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isIncome
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isIncome
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color:
                                      isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                data['title']?.toString() ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isIncome)
                                    Text(
                                        'Given by: ${data['givenBy']?.toString() ?? ''}')
                                  else
                                    Text(
                                        'Category: ${data['category']?.toString() ?? ''}'),
                                  Text(
                                    formatted,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${indianFormat.format(amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color:
                                      isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}