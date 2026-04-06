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
            return const Center(child: Text('No items found. Tap + to add.'));
          }

          // Enhanced Feature 2: Total Inventory Value Calculation
          final totalValue = items.fold<double>(
              0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              // Summary Snapshot
              Card(
                margin: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Inventory Value:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '\$${totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 1. Display Items using ListView.builder
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    // Enhanced Feature 1: Swipe to delete using Dismissible
                    return Dismissible(
                      key: Key(item.id!),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _service.deleteItem(item.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.name} deleted')),
                        );
                      },
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'Qty: ${item.quantity}  |  Price: \$${item.price.toStringAsFixed(2)}\n'
                          '${item.description ?? "No description"}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showItemForm(item),
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