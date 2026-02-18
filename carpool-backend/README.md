# carpool-backend

## Google Places proxy (Flutter Web CORS workaround)

Configure your API key:

```bash
export GOOGLE_MAPS_API_KEY="your-key"
```

`application.properties` reads it from:

```properties
google.maps.api-key=${GOOGLE_MAPS_API_KEY}
```

### Autocomplete

```bash
curl "http://localhost:8080/api/places/autocomplete?input=1600+Amphitheatre&sessionToken=test-session-123&types=address&components=country:us"
```

### Details

```bash
curl "http://localhost:8080/api/places/details?placeId=ChIJ2eUgeAK6j4ARbn5u_wAGqWA&sessionToken=test-session-123"
```
