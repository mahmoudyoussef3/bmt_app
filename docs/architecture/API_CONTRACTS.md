# API Contracts

The system uses **Supabase PostgREST** for standard CRUD operations and **Supabase Edge Functions / RPCs** for complex transactional operations.
All API responses follow standard HTTP Status Codes:
* `200 OK`, `201 Created`
* `400 Bad Request` (Validation Error)
* `401 Unauthorized` (Missing/Invalid Token)
* `403 Forbidden` (RLS Policy Violation)
* `404 Not Found`
* `500 Internal Server Error`

All authenticated requests must include: `Authorization: Bearer <Supabase_JWT>`

---

## 1. Client App APIs

### `POST /rpc/book_seat`
Books a specific seat for a trip. This is a transactional RPC to prevent race conditions.
* **Request Body:**
  ```json
  {
    "p_trip_id": "uuid",
    "p_seat_id": "uuid",
    "p_pickup_station_id": "uuid",
    "p_dropoff_station_id": "uuid",
    "p_payment_method": "cash | wallet | card | subscription"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "booking_id": "uuid",
    "qr_code_token": "string",
    "total_amount": 15.00,
    "status": "confirmed"
  }
  ```
* **Errors:** `400` if seat already taken or insufficient wallet balance.

### `GET /rest/v1/operation_trips?select=*,route:routes(*),pricing:trip_pricing(*)`
Searches for available trips.
* **Query Params:** `trip_date=eq.YYYY-MM-DD`, `route_id=eq.uuid`, `status=eq.scheduled`

---

## 2. Driver App APIs

### `POST /rpc/update_trip_status`
Transitions the trip state (e.g., scheduled -> boarding -> in_progress -> completed).
* **Request Body:**
  ```json
  {
    "p_trip_id": "uuid",
    "p_new_status": "boarding | in_progress | completed"
  }
  ```
* **Side Effects:** Triggers realtime events to Client App. Changes Driver status to `on_trip` or `available`.

### `POST /rpc/scan_passenger_ticket`
Validates a passenger's QR code during boarding.
* **Request Body:**
  ```json
  {
    "p_trip_id": "uuid",
    "p_qr_code_token": "string"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "valid": true,
    "passenger_name": "string",
    "seat_label": "string",
    "payment_status": "paid"
  }
  ```

---

## 3. Dashboard (Admin) APIs

### `POST /rest/v1/operation_trips`
Creates a new scheduled trip.
* **Request Body:**
  ```json
  {
    "route_id": "uuid",
    "driver_id": "uuid",
    "vehicle_id": "uuid",
    "trip_date": "2024-12-01",
    "departure_time": "08:00:00",
    "capacity": 14,
    "status": "scheduled"
  }
  ```

### `POST /rpc/generate_trip_seats`
Auto-generates seat rows in `trip_seats` based on vehicle capacity after a trip is created.
* **Request Body:**
  ```json
  {
    "p_trip_id": "uuid",
    "p_capacity": 14
  }
  ```

### `GET /rest/v1/assignments?driver_id=eq.uuid&status=eq.active`
Checks if a driver is currently assigned to a vehicle before allowing trip scheduling.
