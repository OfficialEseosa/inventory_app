import 'package:flutter/material.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/services/firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _service = FirestoreService();

  void _showItemForm([Item? existingItem]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Takes up full screen if form is long
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ItemForm(
          item: existingItem,
          onSubmit: (item) {
            if (existingItem == null) {
              _service.addItem(item);
            } else {
              _service.updateItem(existingItem.id!, item);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
            onPressed: () => _showItemForm(),
          ),
        ],
      ),
      // 1. Display Items using StreamBuilder
      body: StreamBuilder<List<Item>>(
        stream: _service.getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No items found.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + icon to add an item.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Enhanced Feature 2: Total Inventory Value Calculation
          final totalValue = items.fold<double>(
              0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              // Summary Snapshot
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.tertiaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Value',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} Items Total',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\$${totalValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.swipe_left, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe item left to delete',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // 1. Display Items using ListView.builder
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    // Enhanced Feature 1: Swipe to delete using Dismissible
                    return Dismissible(
                      key: Key(item.id!),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
                      ),
                      onDismissed: (direction) {
                        _service.deleteItem(item.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} deleted'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            radius: 24,
                            child: Text(
                              item.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text('Qty: ${item.quantity}', style: TextStyle(color: Colors.grey.shade800)),
                                    const SizedBox(width: 16),
                                    Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
                                    Text(item.price.toStringAsFixed(2), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                if (item.description != null && item.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description!,
                                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ]
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                            onPressed: () => _showItemForm(item),
                          ),
                        ),
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

// Separate Component for the Form to handle its state cleanly
class ItemForm extends StatefulWidget {
  final Item? item;
  final Function(Item) onSubmit;

  const ItemForm({super.key, this.item, required this.onSubmit});

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(
        text: widget.item?.quantity.toString() ?? '');
    _priceController = TextEditingController(
        text: widget.item?.price.toString() ?? '');
    _descController =
        TextEditingController(text: widget.item?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    // Triggers all validators in the form
    if (_formKey.currentState!.validate()) {
      final newItem = Item(
        id: widget.item?.id, // Keep the old ID if editing
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      widget.onSubmit(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item == null ? 'Add New Item' : 'Edit Item',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              // 2. Validate form fields for empty value
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              // 2. Validate numeric and invalid values
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quantity';
                }
                final qty = int.tryParse(value.trim());
                if (qty == null) {
                  return 'Please enter a valid whole number';
                }
                if (qty < 0) {
                  return 'Quantity cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              // 2. Validate numeric and invalid values
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value.trim());
                if (price == null) {
                  return 'Please enter a valid decimal number';
                }
                if (price < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.item == null ? 'Add Item' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}