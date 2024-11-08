import 'package:flutter/material.dart';  // Importing Flutter's material design library.
import 'package:provider/provider.dart';  // Importing Provider for state management.
import 'package:http/http.dart' as http;  // Importing http package for making API requests.
import 'dart:convert';  // Importing dart:convert for JSON decoding.

// Model for the shopping item
class ShoppingItem {
  final String name;  // Item name.
  final String? price;  // Item price as a string, optional.
  final String? imageUrl;  // URL of the item's image, optional.
  final String? expirationDate;  // Expiration date of the item, optional.
  final int quantity;  // Quantity of the item.
  final DateTime dateAdded;  // Date when item was added.
  bool isBought;  // Flag to indicate if the item is bought.
  final String? notes;  // Additional notes about the item, optional.

  ShoppingItem({
    required this.name,
    this.price,
    this.imageUrl,
    this.expirationDate,
    this.quantity = 1,  // Default quantity is 1.
    required this.dateAdded,
    this.isBought = false,  // Default value is not bought.
    this.notes,
  });

  double get totalPrice {  // Calculating total price based on quantity.
    return (double.tryParse(price ?? '') ?? 0) * quantity;
  }
}

// Provider to manage the shopping list and history
class ShoppingListProvider extends ChangeNotifier {
  List<ShoppingItem> _shoppingList = [];  // List to store active shopping items.
  List<ShoppingItem> _history = [];  // List to store all items ever added.
  ShoppingItem? _lastRemovedItem;  // To hold the last removed item for undo functionality.

  List<ShoppingItem> get shoppingList => _shoppingList;  // Getter for shopping list.
  List<ShoppingItem> get history => _history;  // Getter for history.

  void addItem(String itemName, String imageUrl, String price, int quantity, String expirationDate, String notes) {
    if (itemName.isNotEmpty) {
      final item = ShoppingItem(
        name: itemName,
        imageUrl: imageUrl,
        price: price,
        expirationDate: expirationDate,
        quantity: quantity,
        dateAdded: DateTime.now(),
        notes: notes.isEmpty ? null : notes,
      );
      _shoppingList.add(item);  // Add item to shopping list.
      _history.add(item);  // Add item to history.
      notifyListeners();  // Notify listeners to update UI.
    }
  }

  void toggleBought(int index) {
    _shoppingList[index].isBought = !_shoppingList[index].isBought;  // Toggle isBought status.
    _lastRemovedItem = _shoppingList[index];  // Save item for potential undo.
    notifyListeners();  // Notify listeners to update UI.
  }

  void removeItem(int index) {
    _lastRemovedItem = _shoppingList[index];  // Save item for potential undo.
    _shoppingList.removeAt(index);  // Remove item from shopping list.
    notifyListeners();  // Notify listeners to update UI.
  }

  void undoLastAction() {
    if (_lastRemovedItem != null) {
      _shoppingList.add(_lastRemovedItem!);  // Restore the last removed item.
      _lastRemovedItem = null;  // Clear last removed item.
      notifyListeners();  // Notify listeners to update UI.
    }
  }

  double get totalBasketPrice {  // Calculate total price for all items in the basket.
    double total = 0;
    for (var item in _shoppingList) {
      total += item.totalPrice;
    }
    return total;
  }
}

void main() {
  runApp(MyApp());  // Run the main app widget.
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShoppingListProvider(),  // Creating the provider for shopping list.
      child: MaterialApp(
        title: 'Shopping List App',
        theme: ThemeData(primarySwatch: Colors.blue),  // Set the app theme.
        home: HomeScreen(),  // Set HomeScreen as the initial screen.
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Fetch joke from JokeAPI and show it as a dialog
  Future<void> _fetchJoke() async {
    final response = await http.get(
      Uri.parse('https://v2.jokeapi.dev/joke/Any?type=single'),  // Fetch a joke from API.
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);  // Decode the JSON data.
      String joke = data['joke'] ?? 'No joke found';  // Get the joke text.
      _showDialog('Joke', joke);  // Show the joke in a dialog.
    } else {
      _showDialog('Error', 'Failed to load joke');  // Show error if request fails.
    }
  }

  // Fetch weather data from OpenWeather API (keyless) and show it as a dialog
  Future<void> _fetchWeather() async {
    final response = await http.get(
      Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=30.0444&longitude=31.2357&current_weather=true'),  // Fetch weather data.
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);  // Decode the JSON data.
      String weather = data['current_weather']['temperature'].toString() + '°C';  // Get temperature.
      _showDialog('Current Weather', 'The temperature is $weather');  // Show the temperature in a dialog.
    } else {
      _showDialog('Error', 'Failed to load weather');  // Show error if request fails.
    }
  }

  // Function to show a dialog with title and message
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();  // Close the dialog.
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text('Go to Shopping List'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ShoppingListScreen()));  // Navigate to shopping list.
              },
            ),
            ElevatedButton(
              onPressed: _fetchJoke,
              child: Text('Get New Joke'),  // Button to fetch and show a new joke.
            ),
            ElevatedButton(
              onPressed: _fetchWeather,
              child: Text('Get Weather'),  // Button to fetch and show weather info.
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _itemController = TextEditingController();  // Controller for item name input.
  final _urlController = TextEditingController();  // Controller for image URL input.
  final _priceController = TextEditingController();  // Controller for price input.
  final _quantityController = TextEditingController();  // Controller for quantity input.
  final _expirationController = TextEditingController();  // Controller for expiration date input.
  final _notesController = TextEditingController();  // Controller for notes input.

  @override
  Widget build(BuildContext context) {
    final shoppingListProvider = Provider.of<ShoppingListProvider>(context);  // Access the provider.

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              // Sorting functionality can be implemented here if needed
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),  // Padding around the form.
        child: Column(
          children: <Widget>[
            TextField(
              controller: _itemController,
              decoration: InputDecoration(labelText: 'Item Name'),  // Input field for item name.
            ),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'Image URL'),  // Input field for image URL.
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),  // Input field for price.
            ),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,  // Input field for quantity, numeric only.
            ),
            TextField(
              controller: _expirationController,
              decoration: InputDecoration(labelText: 'Expiration Date (optional)'),  // Input field for expiration date.
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes (optional)'),  // Input field for notes.
            ),
            ElevatedButton(
              onPressed: () {
                shoppingListProvider.addItem(
                  _itemController.text,
                  _urlController.text,
                  _priceController.text,
                  int.tryParse(_quantityController.text) ?? 1,
                  _expirationController.text,
                  _notesController.text,
                );
                _itemController.clear();  // Clear the item name input.
                _urlController.clear();  // Clear the URL input.
                _priceController.clear();  // Clear the price input.
                _quantityController.clear();  // Clear the quantity input.
                _expirationController.clear();  // Clear the expiration date input.
                _notesController.clear();  // Clear the notes input.
              },
              child: Text('Add Item'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('View History'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),  // Navigate to history screen.
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: shoppingListProvider.shoppingList.length,
                itemBuilder: (context, index) {
                  final item = shoppingListProvider.shoppingList[index];
                  return ListTile(
                    leading: item.imageUrl != null
                        ? Image.network(item.imageUrl!)  // Show item image if URL exists.
                        : null,
                    title: Text(item.name),  // Show item name.
                    subtitle: Text(
                      'Price: \$${item.price}, Exp: ${item.expirationDate}\nTotal: \$${item.totalPrice.toStringAsFixed(2)}',  // Show item price and total.
                    ),
                    trailing: IconButton(
                      icon: Icon(item.isBought ? Icons.check_box : Icons.check_box_outline_blank),  // Show checkbox for bought status.
                      onPressed: () {
                        shoppingListProvider.toggleBought(index);  // Toggle bought status.
                      },
                    ),
                    onTap: () {
                      shoppingListProvider.toggleBought(index);  // Toggle bought status on tap.
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Total Basket Price: \$${shoppingListProvider.totalBasketPrice.toStringAsFixed(2)}',  // Show total price of all items.
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shoppingListProvider = Provider.of<ShoppingListProvider>(context);  // Access the provider.

    return Scaffold(
      appBar: AppBar(title: Text('Shopping History')),
      body: ListView.builder(
        itemCount: shoppingListProvider.history.length,
        itemBuilder: (context, index) {
          final item = shoppingListProvider.history[index];
          return ListTile(
            leading: item.imageUrl != null
                ? Image.network(item.imageUrl!)  // Show item image if URL exists.
                : null,
            title: Text(item.name),  // Show item name.
            subtitle: Text('Added on: ${item.dateAdded.toLocal()}'),  // Show date when item was added.
            trailing: Icon(
              item.isBought ? Icons.check_circle : Icons.circle,
              color: item.isBought ? Colors.green : Colors.red,  // Icon color based on bought status.
            ),
            tileColor: item.isBought ? Colors.green[100] : Colors.red[100],  // Background color based on bought status.
          );
        },
      ),
    );
  }
}
