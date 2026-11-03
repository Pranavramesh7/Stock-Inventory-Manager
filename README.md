
# NET4207 Stock Inventory Manager

## Project Description
A Flutter-based Stock Inventory Manager that allows a retailer to add, store, retrieve and search stock records using Firebase Cloud Firestore.

## Technologies
- Flutter and Dart
- Firebase Cloud Firestore
- Visual Studio Code
- GitHub

## Setup and Run
1. Install Flutter and Dart.
2. Install project dependencies using `flutter pub get`.
3. Configure Firebase using FlutterFire CLI.
4. Enable Cloud Firestore in the lecturer-provided Firebase project.
5. Run the application using `flutter run`.

## Firestore Database Schema

Collection: stockItems

| Field | Data Type |
|---|---|
| sku | String |
| itemName | String |
| category | String |
| quantity | Integer |
| unitPrice | Number |
| reorderLevel | Integer |
| createdAt | Timestamp |

## Validation
- SKU must follow STK- followed by three digits.
- Item name must contain at least three characters.
- Category is compulsory.
- Quantity and reorder level must be non-negative integers.
- Unit price must be greater than zero.

## Advanced Search
The application supports partial, case-insensitive searches by item name or SKU. Users can filter by category and low-stock status. Multiple filters work together. Inventory can be sorted by quantity in ascending or descending order.

Low stock is defined as quantity less than or equal to reorderLevel.

## Test Log

| Test | Expected Result | Actual Result |
|---|---|---|
| Blank form submission | Validation errors; no Firestore write | To be tested |
| Valid stock submission | Record saved and retrieved | To be tested |
| Search mouse + Electronics + Low Stock | Only STK-103 displayed | To be tested |

## Firebase
Firebase Cloud Firestore stores inventory records. GitHub stores the project source code and documentation, not inventory data.
