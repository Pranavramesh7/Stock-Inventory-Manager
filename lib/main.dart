
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'stock_item.dart';
import 'firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StockInventoryApp());
}

class StockInventoryApp extends StatelessWidget {
  const StockInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Inventory Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const InventoryScreen(),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService service = FirestoreService();
  final TextEditingController searchController = TextEditingController();

  String keyword = '';
  String selectedCategory = 'All';
  bool lowStockOnly = false;
  bool ascending = true;

  final List<String> categories = [
    'All',
    'Electronics',
    'Stationery',
    'Hardware',
    'Grocery',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> openAddForm() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const StockFormDialog(),
    );

    if (!mounted) return;

    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock item saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  List<StockItem> filterItems(List<StockItem> items) {
    final search = keyword.trim().toLowerCase();

    final filtered = items.where((item) {
      final matchesKeyword = search.isEmpty ||
          item.itemName.toLowerCase().contains(search) ||
          item.sku.toLowerCase().contains(search);

      final matchesCategory = selectedCategory == 'All' ||
          item.category == selectedCategory;

      final matchesLowStock =
          !lowStockOnly || item.quantity <= item.reorderLevel;

      return matchesKeyword && matchesCategory && matchesLowStock;
    }).toList();

    filtered.sort((a, b) {
      return ascending
          ? a.quantity.compareTo(b.quantity)
          : b.quantity.compareTo(a.quantity);
    });

    return filtered;
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      keyword = '';
      selectedCategory = 'All';
      lowStockOnly = false;
      ascending = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Inventory Manager',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            Text(
              'Manage your store inventory',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
      body: StreamBuilder<List<StockItem>>(
        stream: service.getStockItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load inventory:\n${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data ?? [];
          final visibleItems = filterItems(allItems);

          final lowCount = allItems
              .where((item) => item.quantity <= item.reorderLevel)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Total Items',
                      '${allItems.length}',
                      Icons.inventory_2_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Low Stock',
                      '$lowCount',
                      Icons.warning_amber_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Inventory Search',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: searchController,
                onChanged: (value) => setState(() => keyword = value),
                decoration: InputDecoration(
                  hintText: 'Search item name or SKU...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCategory = value ?? 'All');
                },
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show low-stock items only'),
                subtitle: const Text('Quantity less than or equal to reorder level'),
                value: lowStockOnly,
                onChanged: (value) {
                  setState(() => lowStockOnly = value);
                },
              ),

              Row(
                children: [
                  const Text(
                    'Sort quantity:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Ascending'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Descending'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {ascending},
                      onSelectionChanged: (value) {
                        setState(() => ascending = value.first);
                      },
                    ),
                  ),
                ],
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: clearFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ),

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock Inventory',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  Text('${visibleItems.length} records'),
                ],
              ),
              const SizedBox(height: 12),

              if (allItems.isEmpty)
                const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No stock items yet',
                  message: 'Tap Add Stock to create your first inventory record.',
                )
              else if (visibleItems.isEmpty)
                const _EmptyState(
                  icon: Icons.search_off,
                  title: 'No matching items',
                  message: 'Try changing your search or clearing the filters.',
                )
              else
                ...visibleItems.map((item) => _stockCard(item)),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _stockCard(StockItem item) {
    final isLow = item.quantity <= item.reorderLevel;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 11),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isLow)
                  const Chip(
                    label: Text('LOW STOCK'),
                    backgroundColor: Color(0xFFFFE0B2),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text('${item.sku}  •  ${item.category}',
                style: TextStyle(color: Colors.grey.shade600)),
            const Divider(height: 20),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _detail('Quantity', '${item.quantity}'),
                _detail('Price', 'RM ${item.unitPrice.toStringAsFixed(2)}'),
                _detail('Reorder Level', '${item.reorderLevel}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Column(
        children: [
          Icon(icon, size: 55, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 5),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class StockFormDialog extends StatefulWidget {
  const StockFormDialog({super.key});

  @override
  State<StockFormDialog> createState() => _StockFormDialogState();
}

class _StockFormDialogState extends State<StockFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _reorder = TextEditingController();

  final FirestoreService service = FirestoreService();

  String? category;
  bool saving = false;

  @override
  void dispose() {
    _sku.dispose();
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _reorder.dispose();
    super.dispose();
  }

  String? validateInteger(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) {
      return '$field must be a non-negative whole number';
    }
    return null;
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    final item = StockItem(
      id: '',
      sku: _sku.text.trim().toUpperCase(),
      itemName: _name.text.trim(),
      category: category!,
      quantity: int.parse(_quantity.text.trim()),
      unitPrice: double.parse(_price.text.trim()),
      reorderLevel: int.parse(_reorder.text.trim()),
    );

    try {
      await service.addStock(item);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e')),
      );
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Stock Item'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  controller: _sku,
                  label: 'SKU',
                  hint: 'STK-101',
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^STK-\d{3}$').hasMatch(value.trim())) {
                      return 'Enter SKU in format STK-101';
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _name,
                  label: 'Item Name',
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Item name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'Electronics',
                    'Stationery',
                    'Hardware',
                    'Grocery',
                  ].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                  onChanged: (value) => setState(() => category = value),
                ),
                const SizedBox(height: 13),
                _field(
                  controller: _quantity,
                  label: 'Quantity',
                  keyboard: TextInputType.number,
                  validator: (value) => validateInteger(value, 'quantity'),
                ),
                _field(
                  controller: _price,
                  label: 'Unit Price (RM)',
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter unit price';
                    }
                    final number = double.tryParse(value.trim());
                    if (number == null ||
                        !number.isFinite ||
                        number <= 0) {
                      return 'Price must be greater than RM 0';
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _reorder,
                  label: 'Reorder Level',
                  keyboard: TextInputType.number,
                  validator: (value) =>
                      validateInteger(value, 'reorder level'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : saveItem,
          icon: saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(saving ? 'Saving...' : 'Save Item'),
        ),
      ],
    );
  }
}
