# Padel Rental App — Beginner's Project Guide

This guide explains the whole project for someone reading Flutter/Dart code for the first time. Section 5 and 6 walk through every feature as a scenario: **what the user does → what the code does → what changes in Firebase**.

## Contents

1. [What the app is](#1-what-the-app-is)
2. [The tools behind it](#2-the-tools-behind-it)
3. [Dart and Flutter basics you need to read the code](#3-dart-and-flutter-basics-you-need-to-read-the-code)
4. [Project map](#4-project-map)
5. [Player scenarios, step by step](#5-player-scenarios-step-by-step)
6. [Owner scenarios, step by step](#6-owner-scenarios-step-by-step)
7. [The database (Cloud Firestore)](#7-the-database-cloud-firestore)
8. [How to run and demo the project](#8-how-to-run-and-demo-the-project)
9. [Requirements checklist](#9-requirements-checklist)
10. [Glossary](#10-glossary)

## 1. What the app is

Padel Rental is an Android phone app that lets people rent padel equipment (rackets, balls, shoes, bags, accessories) from a padel facility. It is written in **Flutter** (language: **Dart**) and keeps all its data online in **Firebase**.

The app has two kinds of users. Each person chooses their type when they sign up.

| User | Who they are | What they can do |
| --- | --- | --- |
| **Player** | A customer who wants to rent equipment | Sign up and log in, browse categories and products, search by text, voice or QR code, add items to a cart, change quantities, see the total price, submit the rental, see their past rentals |
| **Facility owner** | The person who runs the padel facility | Create categories, add / edit / delete equipment, set the price per day and the available quantity, print QR codes, mark rented items as returned, see a report of rentals and returns for any date |

A simple story of the whole app: the **owner** fills the shop with equipment, a **player** rents some of it, and later the **owner** marks it as returned and checks the daily report.

## 2. The tools behind it

You only need to know three main tools and a few small helper packages.

**Flutter** is a toolkit from Google for building apps. You describe the screen in code ("a column with a text box and a button") and Flutter draws it. One code base can run on Android, iPhone and the web; this project builds for Android.

**Dart** is the programming language Flutter uses. If you know Java, C# or JavaScript, Dart will look familiar: classes, functions, `if`, `for`, and types like `String`, `int`, `double`, `bool`, `List`.

**Firebase** is an online service from Google. The app uses two parts of it:

- **Firebase Authentication** stores the accounts (email + password), checks logins and sends "reset your password" emails.
- **Cloud Firestore** is the online database. It stores categories, equipment, users and rentals. Every phone running the app sees the same data, and changes show up live.

Helper packages (listed in `pubspec.yaml`, the project's shopping list of libraries):

| Package | What it does in this app |
| --- | --- |
| `firebase_core` | Connects the app to the Firebase project |
| `firebase_auth` | Sign-up, login, logout, password reset |
| `cloud_firestore` | Reads and writes the database |
| `shared_preferences` | Saves small values on the phone (the "Remember me" choice and the last email) |
| `speech_to_text` | Turns the user's voice into text for voice search |
| `mobile_scanner` | Uses the camera to read QR codes and barcodes |
| `qr_flutter` | Draws the QR code of each product |
| `fluttertoast` | Shows short pop-up messages like "Added to cart" |
| `intl` | Formats dates ("15 Oct 2026") and money |

## 3. Dart and Flutter basics you need to read the code

Six ideas explain almost every line in this project.

**1. Everything on the screen is a widget.** A widget is a building block: `Text`, `TextField`, `Button`, `Column` (things stacked top to bottom), `Row` (side by side), `Card`, `ListView` (a scrolling list). Widgets go inside other widgets like boxes inside boxes:

```dart
Column(
  children: [
    Text('Padel Rental'),
    TextFormField(decoration: InputDecoration(labelText: 'Email')),
    FilledButton(onPressed: _login, child: Text('Login')),
  ],
)
```

Every screen is a class with a `build()` method that returns its widgets. `Scaffold` is the usual outer box of a screen: it gives the top bar (`appBar`) and the page area (`body`).

**2. Stateless vs Stateful.** A `StatelessWidget` never changes after it is drawn (for example the owner home menu). A `StatefulWidget` has values that change while you use it, kept in a matching `State` class. Example: the login screen remembers whether the "Remember me" box is ticked in `bool _rememberMe`.

**3. `setState` redraws the screen.** When a value changes, the code wraps the change in `setState(() { ... })`. Flutter then runs `build()` again and the screen shows the new value:

```dart
Checkbox(
  value: _rememberMe,
  onChanged: (v) => setState(() => _rememberMe = v!),
)
```

**4. `async` / `await` for slow work.** Talking to Firebase takes time (it goes over the internet). A function marked `async` can `await` a slow call, which means "wait here for the answer, but don't freeze the app". A slow answer has the type `Future<...>`:

```dart
Future<void> _login() async {
  final user = await AuthService.login(email, password, _rememberMe);
  // this line runs only after Firebase answered
}
```

**5. Future vs Stream.** A `Future` gives **one** answer later (log in, save a rental). A `Stream` keeps giving **new** answers whenever the data changes (the equipment list). `FutureBuilder` and `StreamBuilder` are widgets that redraw themselves when the answer arrives, showing a loading circle until then. Because the equipment list uses a `Stream`, when the owner changes a price, every player's screen updates by itself.

**6. `Navigator` moves between screens.** `Navigator.push(...)` opens a new screen on top; `Navigator.pop(context)` goes back. `pushReplacement` swaps the current screen, so the back button can't return to the login page after logging in.

Small Dart signs you will see:

- `final` = a value set once. `const` = a value fixed when the app is built.
- A name starting with `_` (like `_login`) is private to that file.
- `String?` with a question mark = "may be empty (null)". `x!` = "I'm sure it's not null".
- `(v) => ...` is a short function (a lambda).
- `'${e.name} added'` puts a value inside a text.

## 4. Project map

All the Dart code lives in the `lib/` folder, split into four layers: **models** (what the data looks like), **services** (talking to Firebase), **screens** (what the user sees) and **widgets** (small reusable pieces). A screen never talks to Firebase directly; it always asks a service.

```
   SCREENS (lib/screens)        SERVICES (lib/services)        ONLINE AND ON THE PHONE
 +-----------------------+    +------------------------+    +-------------------------+
 | Auth screens          |    | auth_service           |    | Firebase Auth           |
 |  login, sign-up, reset|    |  accounts, remember me |    |  emails and passwords   |
 | Player screens        |    | db_service             |    | Cloud Firestore         |
 |  browse, search, cart |--->|  all database work     |--->|  equipment, rentals     |
 | Owner screens         |    | cart                   |    | Phone storage           |
 |  equipment, report    |    |  items and total       |    |  shared_preferences     |
 | Scanner screen        |    | search                 |    |                         |
 |  camera reads QR      |    |  smart text matching   |    |                         |
 +-----------------------+    +------------------------+    +-------------------------+
         calls ------------------------>      uses ----------------------->
```

Read it left to right: a screen asks a service, and the service talks to Firebase or the phone. The camera and microphone are the only exception: the scanner and products screens use them directly through their packages.

| File | Job |
| --- | --- |
| `main.dart` | Starting point. Connects to Firebase, then opens the login screen or, if "Remember me" was ticked, the right home screen |
| `utils.dart` | Small helpers: pop-up message (`showMsg`), money and date formatting, an icon per category |
| `models/app_user.dart` | A user: name, email, role (`player` / `owner`), birthdate |
| `models/category.dart` | A category: name |
| `models/equipment.dart` | A piece of equipment: name, description, category, price per day, quantity, code for the QR |
| `models/rental.dart` | A rental: who, which items, how many days, total, rented / returned and the dates |
| `services/auth_service.dart` | Sign-up, login, remember me, forgot password, logout |
| `services/db_service.dart` | Every database read and write: categories, equipment, rentals, report, default data |
| `services/cart.dart` | The rental cart and its total price |
| `services/search.dart` | Smart search for typed and spoken words |
| `screens/auth/login_screen.dart` | Login page with "Remember me" and "Forgot password?" |
| `screens/auth/signup_screen.dart` | Create account, birthdate calendar, Player / Facility owner choice |
| `screens/auth/forgot_password_screen.dart` | Sends the password reset email |
| `screens/player/player_home_screen.dart` | Player home: grid of categories, cart button, menu |
| `screens/player/products_screen.dart` | Equipment list with text, voice and QR search |
| `screens/player/product_details_screen.dart` | One product: price, stock, QR code, choose quantity, add to cart |
| `screens/player/cart_screen.dart` | Cart: + / − quantity, rental days, total, submit |
| `screens/player/my_rentals_screen.dart` | The player's own rentals |
| `screens/owner/owner_home_screen.dart` | Owner home: menu of owner features |
| `screens/owner/categories_screen.dart` | Create and delete categories |
| `screens/owner/equipment_list_screen.dart` | All equipment with edit, delete and QR buttons |
| `screens/owner/equipment_form_screen.dart` | Add or edit equipment: price, quantity, category, code |
| `screens/owner/qr_codes_screen.dart` | All QR codes on one page to show or print |
| `screens/owner/rentals_screen.dart` | Active rentals, "Mark returned" button |
| `screens/owner/report_screen.dart` | Transaction report for a chosen date |
| `screens/scanner_screen.dart` | Camera screen that reads a QR code or barcode |
| `widgets/rental_card.dart` | Card that shows one rental |
| `widgets/equipment_qr.dart` | Draws the QR code of one product |

Other important files outside `lib/`:

- `pubspec.yaml`: the list of packages the app uses.
- `android/app/google-services.json`: the keys that connect the app to *your* Firebase project.
- `firestore.rules`: who is allowed to read and write what in the database.
- `test/search_test.dart`: automatic tests for the smart search.

## 5. Player scenarios, step by step

Each scenario reads: **what the user does → what the code does → what changes in Firebase**.

### 5.1 Create an account (sign-up with a birthdate calendar)

1. On the login screen the user taps **"Don't have an account? Sign up"** → `SignupScreen` opens.
2. They type name, email, password and confirm password. Each box has a `validator` that shows a red message if it's wrong (for example "At least 6 characters").
3. They tap **Birthdate** → `_pickBirthdate()` calls Flutter's `showDatePicker()` and a calendar appears.
4. They choose **Player** or **Facility owner** (a radio button) and tap **Sign up**.
5. `AuthService.signUp()` asks **Firebase Authentication** to create the account, then saves name, email, role and birthdate in Firestore at `users/{user id}`.
6. The app opens the home screen that fits the role (`homeFor(user)` in `main.dart`).

### 5.2 Log in and "Remember me"

1. The user types email and password, ticks **Remember me** and taps **Login**.
2. `AuthService.login()` checks the password with Firebase Authentication, then saves `remember_me = true` and the email on the phone with `shared_preferences`.
3. Next time the app starts, `StartScreen` in `main.dart` calls `AuthService.autoLogin()`. If Remember me was ticked and Firebase still has the user signed in, it goes **straight to the home screen**. If not, it signs out and shows the login screen (with the saved email already filled in).
4. **Logout** (menu on the home screen) sets `remember_me = false` and signs out.

### 5.3 Forgot password

1. On the login screen the user taps **Forgot password?** → `ForgotPasswordScreen` opens with the email already copied in.
2. They tap **Send reset link** → `AuthService.resetPassword()` calls Firebase's `sendPasswordResetEmail`.
3. Firebase emails a link. The user opens it, chooses a new password, and logs in with it.

### 5.4 Browse categories and products

1. `PlayerHomeScreen` shows a grid of categories. It listens to `DbService.categoriesStream()`, so new categories appear by themselves.
2. Tapping a category opens `ProductsScreen` with only that category (`equipmentStream(categoryId: ...)`); **All equipment** shows everything.
3. Tapping a product opens `ProductDetailsScreen`: picture icon, description, price per day, how many are available and its QR code.

### 5.5 Search by text

1. The user types in **Search by name**. Each letter calls `setState`, so the list filters as they type.
2. The filtering is done by `searchEquipment()` in `services/search.dart`. It searches the name, category and description, ignores extra words like "show me the", accepts singular or plural ("ball" finds "Balls") and one wrong letter ("rocket" finds "racket").

### 5.6 Search by voice

1. The user taps the **microphone button**. The first time, Android asks for microphone permission.
2. `_voiceSearch()` starts `speech_to_text` in English for up to 15 seconds. A moving bar shows it is listening and the words appear in the search box while the user speaks.
3. When they stop talking, the phone returns a few guesses of what was said. The app picks the first guess that finds equipment and the list filters with the same smart search as typing.

### 5.7 Search by QR code (camera)

1. The user taps the **scanner button** → `ScannerScreen` opens the camera (`mobile_scanner`).
2. When the camera sees a QR code or barcode, the screen closes and returns the code, for example `1001`.
3. `DbService.findByBarcode('1001')` looks in Firestore for equipment with that code, and the app opens its details page. If nothing matches, a message says "No equipment with barcode ...".

### 5.8 Add to cart, edit quantities, see the total

1. On a product page the user chooses a quantity with **− / +** (never more than the available stock) and taps **Add to cart**. `cart.add()` puts it in the cart; adding the same product again increases its quantity.
2. The **cart button** at the top shows how many items are in the cart. Tapping it opens `CartScreen`.
3. In the cart they can press **+ / −** on each item (going below 1 removes it) and choose the number of **rental days** (1 to 30).
4. The total updates at once, because the cart is a `ChangeNotifier`: whenever it changes, the screen redraws. The formula (in `services/cart.dart`):

```
total = (sum of: price per day × quantity, for every item) × days
```

Example: 2 rackets at 100 EGP/day + 1 pack of balls at 20 EGP/day, for 3 days = (200 + 20) × 3 = **660 EGP**.

### 5.9 Submit the rental

1. The user taps **Submit rental** → `DbService.submitRental()`.
2. Inside a Firestore **transaction**, it first reads the current stock of every item and stops with a message if there isn't enough ("Only 1 of Head Delta Pro available now").
3. If there is enough, it lowers each item's quantity and saves a new document in `rentals` with status `rented` and today's date.
4. The cart empties and a message shows the total.

### 5.10 See my rentals

From the menu, **My rentals** opens `MyRentalsScreen`. It lists the player's own rentals (newest first) with their items, total and whether they are still rented or already returned.

## 6. Owner scenarios, step by step

### 6.1 First login: default equipment

1. The first time any **Facility owner** signs up or logs in, `AuthService` calls `DbService.addDefaultDataIfEmpty()`.
2. If the `categories` collection is empty, it adds 5 categories (Padel Rackets, Balls, Shoes, Bags, Accessories) and 12 pieces of equipment with prices, quantities and codes `1001` to `5003`, all at once in one **batch** write.
3. If categories already exist, it does nothing, so the owner's own changes are never overwritten.

### 6.2 Create a category

1. Owner home → **Categories** → `CategoriesScreen`.
2. They type a name (for example "Grips") and tap **Add** → `DbService.addCategory()` saves it in `categories`.
3. Players see the new category on their home grid immediately (it is a Stream).
4. The delete button only works when no equipment uses that category, so no product is left without one.

### 6.3 Add equipment (set price and quantity)

1. Owner home → **Equipment** → **+ Add** → `EquipmentFormScreen`.
2. They fill in **Name**, choose a **Category** from the dropdown, an optional **Description**, **Price per day** (EGP) and **Available quantity**.
3. **QR / barcode code**: they can type one, scan an existing barcode with the camera button, or leave it empty and the app creates a unique code (like `P1760612345678`).
4. **Add equipment** → `DbService.addEquipment()` saves a new document in `equipment`.

### 6.4 Edit or delete equipment

- **Edit**: tap a product in the list → the same form opens filled in → change the price or quantity → **Save changes** → `DbService.updateEquipment()`.
- **Delete**: tap the bin icon → a "Delete equipment?" box asks to confirm → `DbService.deleteEquipment()`.

### 6.5 QR codes

1. In the equipment list, the **QR button** on each row shows a big QR code for that product.
2. Owner home → **QR codes** shows every product's QR code in a grid, ready to show on a screen or print and stick on the equipment.
3. Each QR code simply contains the product's code (for example `1001`). When a player scans it, the app finds the product with that code.

### 6.6 Mark a rental as returned

1. Owner home → **Active rentals** → `RentalsScreen` lists every rental with status `rented`.
2. When the player brings the equipment back, the owner taps **Mark returned** → `DbService.markReturned()`.
3. In one transaction it adds the quantities back to each item's stock and sets the rental's status to `returned` with today's date.

### 6.7 Transaction report for a date

1. Owner home → **Transaction report** → `ReportScreen`, showing today by default.
2. Tap the date to pick another day from a calendar.
3. `DbService.report(day)` finds rentals whose `rentDay` is that date and rentals whose `returnDay` is that date.
4. The screen shows three numbers (rentals, returns, rental income) and then the two lists: **Rented on this day** and **Returned on this day**.

## 7. The database (Cloud Firestore)

Firestore stores data as **documents** (like a small form with fields) grouped in **collections** (like folders). The app uses four collections.

| Collection | One document is | Fields |
| --- | --- | --- |
| `users` | One account (the document id = the Firebase user id) | `name`, `email`, `role` (`player` or `owner`), `birthdate` |
| `categories` | One category | `name` |
| `equipment` | One product | `name`, `description`, `categoryId`, `categoryName`, `price` (per day), `quantity` (available now), `barcode` (the code inside the QR) |
| `rentals` | One submitted cart | `userId`, `userName`, `items` (list of name, price, quantity), `days`, `total`, `status` (`rented` / `returned`), `rentDate`, `rentDay`, `returnDate`, `returnDay` |

`rentDay` and `returnDay` are saved as plain text like `2026-10-16`. That makes the report simple: "give me every rental where `rentDay` equals `2026-10-16`".

**Security rules** (`firestore.rules`) decide who may read and write. In plain words:

- You must be logged in to read anything.
- You can only create or change **your own** user profile.
- Only an **owner** can create, edit or delete categories and equipment.
- A player may only change an equipment's `quantity` (that happens when they rent).
- A player can create rentals only in **their own** name; only an owner can mark them returned.

**Why transactions?** Imagine one racket is left and two players press Submit at the same moment. Without care, both could rent it. A Firestore **transaction** reads the stock and writes the new stock as one step: if the stock changed in between, Firestore retries, and the second player gets "Only 0 available now".

## 8. How to run and demo the project

### 8.1 One-time Firebase setup (already done for the `padel-rental` project)

1. In the [Firebase console](https://console.firebase.google.com), create a project and add an **Android** app with package name `com.padel.padel_rental`.
2. Download `google-services.json` into `android/app/`.
3. **Authentication** → Get started → enable **Email/Password**.
4. **Firestore Database** → create it, then publish the rules from `firestore.rules`.

### 8.2 Run the app

1. Start the Android emulator (Android Studio → Device Manager → ▶ next to **Lab_Phone**) or plug in a real phone.
2. In a terminal inside the project folder:

```
flutter pub get
flutter run
```

After the first run, the app stays installed: open it from its icon on the phone.

### 8.3 Emulator tips

- **Keyboard**: if only a small floating bar shows instead of the keyboard, tap **☰** on the bar → **Show on-screen keyboard**. The PC keyboard also works after clicking inside the emulator.
- **Microphone** (voice search): emulator side bar **⋯** → **Microphone** → turn on **Virtual microphone uses host audio input**. Do this every time the emulator starts.
- **Camera** (QR search): the emulator uses the laptop webcam. The webcam can't see the laptop's own screen, so show the QR code on a phone or on paper.

### 8.4 Demo script (about 5 minutes)

1. **Owner**: sign up as *Facility owner* → the default categories and equipment are created → open **Equipment**, edit a price, add one new product → open **QR codes**.
2. **Player**: log out, sign up as *Player* with a birthdate from the calendar, tick **Remember me** when logging in.
3. Browse a category → type "rack" in search → tap the microphone and say "balls" → scan a QR code with the camera.
4. Add two items to the cart → change quantities and days → show the total → **Submit rental**.
5. Close and reopen the app → it opens straight to the home screen (Remember me).
6. **Owner** again: **Active rentals** → **Mark returned** → **Transaction report** for today shows 1 rental and 1 return.
7. Show **Forgot password?** sending a reset email.

## 9. Requirements checklist

Every app requirement of the assignment is built; GitHub is the one item still open.

| Requirement | Where in the app | Main file | Scenario |
| --- | --- | --- | --- |
| Sign-up & Login | Login and Create account screens | `auth_service.dart` | 5.1, 5.2 |
| Birthdate using a calendar | Create account → Birthdate | `signup_screen.dart` | 5.1 |
| Remember me | Login → checkbox | `auth_service.dart`, `main.dart` | 5.2 |
| Forget password recovery | Login → Forgot password? | `forgot_password_screen.dart` | 5.3 |
| Navigate categories and products | Player home → category → product | `player_home_screen.dart`, `products_screen.dart` | 5.4 |
| Search by text | Products → search box | `search.dart` | 5.5 |
| Search by voice | Products → microphone | `products_screen.dart` | 5.6 |
| Search by barcode (camera) | Products → scanner button | `scanner_screen.dart` | 5.7 |
| Add multiple equipment to the cart | Product → Add to cart | `cart.dart` | 5.8 |
| Edit quantity in the cart | Cart → + / − | `cart_screen.dart` | 5.8 |
| Total rental cost before submission | Cart → Total | `cart.dart` | 5.8 |
| Owner: add / edit / delete equipment | Owner → Equipment | `equipment_list_screen.dart`, `equipment_form_screen.dart` | 6.3, 6.4 |
| Owner: create categories | Owner → Categories | `categories_screen.dart` | 6.2 |
| Owner: set rental price & quantity | Equipment form | `equipment_form_screen.dart` | 6.3 |
| Owner: transaction report on a date | Owner → Transaction report | `report_screen.dart` | 6.7 |
| Database: Firebase | Everywhere | `db_service.dart`, `auth_service.dart` | 7 |
| GUI | Material 3 design: cards, grids, forms, dialogs | all screens | — |
| GitHub with history and team collaboration | — | — | **Not done yet**: push to GitHub and each teammate commits under their own account |

## 10. Glossary

| Word | Meaning |
| --- | --- |
| Widget | A building block of the screen (text, button, list, ...) |
| `build()` | The method that returns what a screen looks like |
| State | Values a screen remembers while it is open |
| `setState` | "A value changed, redraw the screen" |
| `async` / `await` | Wait for slow work (internet) without freezing the app |
| Future | One answer that arrives later |
| Stream | Answers that keep arriving whenever the data changes |
| `Navigator` | Opens and closes screens |
| Model | A Dart class describing one kind of data (user, equipment, ...) |
| Service | A class that does the work behind the screens (Firebase, cart) |
| Package | A ready-made library added in `pubspec.yaml` |
| Firebase Authentication | Google's online service for accounts and passwords |
| Firestore | Google's online database used by the app |
| Collection / document | A folder of records / one record in Firestore |
| Transaction | Several database reads and writes done as one safe step |
| Batch | Several writes sent together in one go |
| Security rules | The rules in Firestore that decide who can read or write what |
| `ChangeNotifier` | An object that tells screens "I changed" (used by the cart) |
| `shared_preferences` | Small storage on the phone (Remember me) |
| Emulator | A virtual Android phone running on the laptop |
| QR code | A square code the camera can read; here it holds the product's code |
