# Inventory App

A Flutter project demonstrating CRUD operations using Firebase Cloud Firestore.

## Getting Started

This app manages an inventory database. 

### Features Implemented:
- View all items from Firestore in real-time (`StreamBuilder` + `ListView.builder`).
- Add and Edit items using a Bottom Sheet form.
- Form validation to prevent empty, negative, or invalid numeric data.

### ✨ Enhanced Features

1. **Swipe to Delete (`Dismissible`)**
   - You can easily delete an item by swiping its row horizontally from right to left. It includes a red background delete indicator for better user experience.
   
2. **Real-time Total Inventory Value Summary**
   - At the top of the item list, a highlighted summary card continuously updates to show the total value of your inventory (the sum of `quantity * price` across all items) reacting immediately to database changes.
