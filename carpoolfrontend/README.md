# Carpool Frontend

## Run with Google Places API key
This app reads the Places Web Service API key from a compile-time define:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY
```

Use an API key with these APIs enabled in Google Cloud:
- Places API

The demo `Plan Carpool (Demo)` page uses:
- Places Autocomplete (Web Service)
- Place Details (Web Service)
- Backend optimize endpoint: `http://localhost:8080/api/optimize`
