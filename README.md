# Padel Equipment Rental & Management System

Flutter + Firebase app for renting padel equipment.
Two kinds of users: **Players** (rent equipment) and **Facility Owners** (manage equipment).

## Requirements → where they are in the code

| Requirement | Screen / file | How it works |
|---|---|---|
| Sign-up & Login | `screens/auth/signup_screen.dart`, `login_screen.dart` | `FirebaseAuth.createUserWithEmailAndPassword` / `signInWithEmailAndPassword`. Extra data (name, birthdate, role) saved in the `users` collection. |
| Birthdate using a calendar | `signup_screen.dart` → `_pickBirthdate()` | Flutter's built-in `showDatePicker()` |
| Remember me | `login_screen.dart` + `AuthService.autoLogin()` | The checkbox value is saved with `shared_preferences`. On app start (`StartScreen` in `main.dart`) the user goes straight to home only if it was ticked. |
| Forget password recovery | `screens/auth/forgot_password_screen.dart` | `FirebaseAuth.sendPasswordResetEmail` sends a reset link by email |
| Navigate categories & products | `screens/player/player_home_screen.dart` → `products_screen.dart` → `product_details_screen.dart` | Categories grid → list of equipment → details |
| Search by text | `products_screen.dart` | Filters the list by name/category while typing |
| Search by voice | `products_screen.dart` → `_voiceSearch()` | `speech_to_text` package writes the spoken words into the search box |
| Search by barcode (camera) | `products_screen.dart` → `_barcodeSearch()`, `screens/scanner_screen.dart` | `mobile_scanner` reads the code, then `DbService.findByBarcode()` |
| Add multiple equipment to cart | `product_details_screen.dart`, `services/cart.dart` | One global `cart` object (a `ChangeNotifier`) |
| Edit quantity in the cart | `screens/player/cart_screen.dart` | + / − buttons, can't exceed available quantity, 0 removes the item |
| Total rental cost before submission | `cart_screen.dart`, `Cart.total` | total = (price/day × quantity for each item) × number of days |
| Owner: Add / Edit / Delete equipment | `screens/owner/equipment_list_screen.dart`, `equipment_form_screen.dart` | Firestore `add` / `update` / `delete` |
| Owner: Create categories | `screens/owner/categories_screen.dart` | Firestore `categories` collection |
| Owner: Set rental price & quantity | `equipment_form_screen.dart` | "Price per day" and "Available quantity" fields |
| Owner: Transaction report on a date | `screens/owner/report_screen.dart` | Pick a date → shows rentals made and equipment returned that day + income |
| Database: Firebase | `services/db_service.dart`, `services/auth_service.dart` | Firebase Auth + Cloud Firestore |

Extra: the owner marks rentals as returned in `screens/owner/rentals_screen.dart`, which puts the quantity back and saves the return date (that's what the report shows as "returns").

## Project structure

```
lib/
  main.dart                 Starts Firebase, chooses login or home screen
  utils.dart                Toast message, money and date formatting
  models/                   Plain Dart classes for Firestore documents
    app_user.dart  category.dart  equipment.dart  rental.dart
  services/
    auth_service.dart       Sign-up, login, remember me, reset password, logout
    db_service.dart         All Firestore reads/writes
    cart.dart               The rental cart
  screens/
    auth/                   Login, sign-up, forgot password
    player/                 Home (categories), products + search, details, cart, my rentals
    owner/                  Owner home, equipment, categories, active rentals, report
    scanner_screen.dart     Camera barcode scanner (used by player and owner)
  widgets/rental_card.dart  Card that shows one rental
```

## Firestore collections

| Collection | Fields |
|---|---|
| `users/{uid}` | name, email, role (`player` / `owner`), birthdate |
| `categories` | name |
| `equipment` | name, description, categoryId, categoryName, price (per day), quantity (available now), barcode |
| `rentals` | userId, userName, items [ {equipmentId, name, price, quantity} ], days, total, status (`rented` / `returned`), rentDate, rentDay, returnDate, returnDay |

`rentDay` / `returnDay` are text like `2026-10-15` so the report can find all transactions of one date with a simple `where(... isEqualTo ...)`.

Submitting a rental and marking it returned use a **Firestore transaction**: it reads the current quantities, checks there is enough stock, then updates the quantities and the rental together. So two players can't rent the last racket at the same time.

## Setup

1. Firebase console → create a project → add an **Android** app with package name `com.padel.padel_rental`.
2. Download `google-services.json` into `android/app/` (same as Lab 3).
3. Firebase console → **Authentication** → Get started → enable **Email/Password**.
4. Firebase console → **Firestore Database** → Create database, then paste `firestore.rules` into the **Rules** tab and publish.
5. Run:
   ```
   flutter pub get
   flutter run
   ```

## How to demo

1. Sign up as **Facility owner** → add categories (Padel Rackets, Balls, Shoes, Bags, Accessories) → add equipment with price, quantity and a barcode.
2. Log out, sign up as **Player** → browse categories → search by text / voice / barcode → add items → edit quantities and days in the cart → submit.
3. Log in as the owner → **Active rentals** → mark returned → **Transaction report** for today.
