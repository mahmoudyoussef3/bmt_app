# 🚌 Mega Transportation - Flutter Prototype

A complete Flutter prototype for **Mega Transportation**, an Egyptian employee commute management system. This prototype digitizes the entire transportation booking workflow that was previously managed through WhatsApp.

## 📱 Demo & Overview

This is an **initial prototype** with:
- ✅ Beautiful Material 3 UI design
- ✅ Realistic business workflows
- ✅ Clean architecture (Feature-based structure with Cubit)
- ✅ Three user roles: **Client**, **Driver**, **Admin**
- ✅ Mock data (no backend required yet)
- ✅ Fully responsive layouts
- ✅ Ready for company demo

## 🎯 Business Model

**Mega Transportation** operates:
- **Days**: Sunday to Thursday (Friday/Saturday off)
- **Customers**: Daily clients (per-trip booking) + Monthly subscribers (fixed bookings)
- **Routes**: Banha → Smart Village, October, Nasr City, Sheraton, Mohandessin, Maadi, Metro
- **Schedule**: 
  - Morning arrivals: 8:30 AM, 9:00 AM, 9:30 AM, 10:00 AM
  - Return departures: 4:30 PM, 5:00 PM, 5:30 PM, 6:00 PM

## 🏗️ Architecture

### Folder Structure
```
lib/
├── main.dart                 # App entry point & role selector
├── core/
│   ├── theme/               # Material 3 theme & styling
│   └── di/                  # Dependency injection (ready for expansion)
├── features/
│   ├── client/              # Client feature (booking, tracking, subscription)
│   │   ├── presentation/
│   │   │   ├── cubits/      # BookingCubit, TrackingCubit, SubscriptionCubit
│   │   │   ├── screens/     # HomeScreen, DailyBookingScreen, etc.
│   │   │   └── widgets/     # Reusable: LocationCard, VehicleCard, SeatGrid
│   │   ├── domain/          # (Ready for business logic)
│   │   └── data/            # (Ready for API integration)
│   ├── driver/              # Driver feature
│   │   └── presentation/
│   │       ├── cubits/      # DriverTripCubit
│   │       └── screens/     # TripListScreen
│   └── admin/               # Admin feature
│       └── presentation/
│           ├── cubits/      # AdminDashboardCubit
│           └── screens/     # DashboardScreen
└── shared/
    ├── models/              # Domain models (User, Trip, Vehicle, Booking, etc.)
    └── mock_data/           # Realistic dummy data generators
```

### State Management: Cubit

- **BookingCubit**: Manages the 6-step daily booking flow
- **SubscriptionCubit**: Monthly subscription selection & confirmation
- **TrackingCubit**: Real-time vehicle tracking state
- **BookingsListCubit**: Client's booking history
- **DriverTripCubit**: Driver's assigned trips & passenger status
- **AdminDashboardCubit**: Fleet analytics & vehicle occupancy

## 📱 Screens

### Client App (5 screens)

1. **Home Screen**
   - Welcome message with user's name
   - Quick action buttons (Daily Booking, Monthly, Track)
   - Upcoming bookings list
   - Active subscription info card

2. **Daily Booking Flow** (4 Steps)
   - Step 1: Select pickup location (Banha Station, Center, etc.)
   - Step 2: Select destination (Smart Village, Nasr City, etc.)
   - Step 3: Select arrival time (8:30 AM, 9:00 AM, etc.)
   - Step 4: Show available vehicles with:
     - Vehicle number
     - Driver name
     - Departure/arrival times
     - Available seats count
   - Step 5: Visual seat selection grid
   - Step 6: Booking confirmation

3. **Seat Selection Screen**
   - Interactive 6-seat grid (3 rows × 2 seats)
   - Visual feedback: Available (white), Booked (grey), Selected (blue)
   - Tap to select your seat

4. **Monthly Subscription Screen**
   - Stepper workflow:
     - Choose pickup location
     - Choose dropoff location
     - Select preferred arrival time
     - Choose preferred permanent seat
   - "My Subscription" tab showing active details
   - Option to cancel subscription

5. **Track Vehicle Screen**
   - Map placeholder with route visualization
   - ETA countdown (e.g., "Arriving in 7 min")
   - Trip details card
   - Driver contact info with Call/WhatsApp buttons
   - Real-time tracking simulation

### Driver App (1 screen)

1. **Trip List Screen**
   - Vehicle info header
   - All assigned trips for the day
   - Each trip shows:
     - Pickup & dropoff locations
     - Passenger list ordered by route
     - Per-passenger actions: Boarded ✓ or Skipped ✗
     - "Arrived" button to mark trip in progress

### Admin Dashboard (1 screen)

1. **Dashboard Screen**
   - **Statistics Cards**:
     - Total vehicles
     - Active trips
     - Total bookings
     - Revenue (EGP)
   - **Active Trips Section**: List of current trips with occupancy
   - **Vehicle Fleet Section**: All vehicles with:
     - Driver name
     - Occupancy meter (%)
     - Color-coded occupancy: 🟢 Low, 🟠 Medium, 🔴 High

## 🎨 Design System

- **Theme**: Material 3 with custom colors
- **Primary Color**: `#1F77D2` (Professional Blue)
- **Secondary Color**: `#26C281` (Success Green)
- **Accent Color**: `#FF6B6B` (Alert Red)
- **Typography**: Scalable, Material 3 compliant
- **Rounded corners**: 12-16px for modern look
- **Spacing**: 8px/12px/16px/24px grid

## 🗂️ Mock Data

Includes realistic dummy data:
- **8 Vehicles**: MEG-001 through MEG-008 with drivers
- **4 Drivers**: Ahmed Hassan, Mohamed Ali, Ibrahim Khalil, Karim Nassar
- **9 Locations**: Banha Station, Smart Village, October, Nasr City, Sheraton, Mohandessin, Maadi, Helwan
- **5 Sample Trips**: Different routes with various occupancy levels
- **2 Sample Users**: Client and Driver profiles
- **Vehicle Occupancy**: Mix of full, partial, and empty vehicles

## 🚀 Running the App

### Prerequisites
- Flutter 3.11.1 or higher
- Android Studio / Xcode for emulator

### Commands
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios
```

## 🎬 Demo Flow

1. **Open App** → Role selector appears
2. **Select "Client"** → Home screen shows bookings
3. **Tap "Daily Booking"** → Multi-step booking flow
4. **Select Location → Destination → Time** → Available vehicles shown
5. **Tap "Book Now"** → Seat selection grid appears
6. **Select Seat → Confirm** → Success screen with booking ID
7. **Back to Home** → New booking appears in list

**Driver Demo**:
- Select "Driver" → Shows trip list
- See all passengers per trip
- Mark passengers as "Boarded" or "Skipped"

**Admin Demo**:
- Select "Admin" → Dashboard with statistics
- View vehicle occupancy across fleet
- Monitor active trips

## 📊 Key Features Implemented

✅ **Client Features**
- Daily trip booking with 6-step wizard
- Monthly subscription management
- Real-time vehicle tracking (UI simulation)
- Booking history
- Driver contact integration (WhatsApp/Call buttons)

✅ **Driver Features**
- Trip list with all assigned journeys
- Per-passenger boarding status tracking
- Route and location information
- Quick trip status updates

✅ **Admin Features**
- Fleet overview with statistics
- Real-time occupancy monitoring
- Active trips dashboard
- Revenue tracking

## 🔮 Next Steps (Production)

When ready to move to production:
1. **Backend API**: Replace MockData with REST/GraphQL API calls
2. **Firebase**: User authentication & real-time database
3. **Maps Integration**: Replace map placeholder with Google Maps
4. **Push Notifications**: Trip updates for clients & drivers
5. **Payment Gateway**: Process monthly subscriptions
6. **Real GPS Tracking**: Replace simulation with actual location services
7. **Analytics**: Integrate Firebase Analytics

## 📝 Code Quality

- **No external generators**: Pure Dart 3 with sealed classes & pattern matching
- **Clean Architecture**: Clear separation of Presentation/Domain/Data layers
- **Reusable Widgets**: LocationCard, VehicleCard, SeatGrid, TripCard
- **Cubit State Management**: Predictable, testable state
- **Material 3 Compliant**: Modern design with rounded corners & shadows

## 📄 License

Private project for Mega Transportation Company.

---

**Built with ❤️ for Mega Transportation - Digitizing Employee Commute**
