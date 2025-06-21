# Setup Guide - Real-Time Location Feature

## 🚀 Setup Firebase Realtime Database

### 1. Enable Firebase Realtime Database
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project `umrahtrack-hazz`
3. Navigate to **Realtime Database** in the left sidebar
4. Click **Create Database**
5. Choose **Start in test mode** (for development)
6. Select your preferred location (closest to your users)

### 2. Update Database Rules
Copy the rules from `database.rules.json` to your Firebase Console:

```json
{
  "rules": {
    "locations": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        ".validate": "newData.hasChildren(['latitude', 'longitude', 'timestamp'])"
      }
    }
  }
}
```

**What these rules do:**
- Users can only read/write their own location data
- Validates that location data contains required fields
- Ensures data security and privacy

### 3. Deploy Rules (Optional)
If you have Firebase CLI installed:
```bash
firebase deploy --only database
```

## 📱 Testing the Location Feature

### Pre-requisites:
- **Physical Android device** (GPS doesn't work in emulator)
- **Location/GPS enabled** on the device
- **Internet connection** for Firebase sync
- **Developer options enabled** for USB debugging

### Testing Steps:

#### 1. Build and Install App
```bash
flutter clean
flutter pub get
flutter build apk --debug
# Or connect device and run:
flutter run --debug
```

#### 2. Test Location Permission Flow
1. Open app and navigate to Jamaah section
2. Tap on "Lokasi" from bottom navigation or quick actions
3. When prompted, **allow location permissions**
4. If permission denied, test the "Buka Pengaturan" button

#### 3. Test Real-Time Tracking
1. Toggle the location switch **ON**
2. You should see:
   - Your location marker appear on the map
   - Coordinates, accuracy, and speed displayed
   - Map auto-centers on your location
3. **Move around physically** to test real-time updates
4. Check Firebase Console to see data being saved

#### 4. Test Map Controls
- **Pan and zoom** the map manually
- Use **center button** to return to your location
- Test **auto-follow mode** (moves map as you move)
- Use **restart button** to restart tracking

#### 5. Test Error Scenarios
- Turn off GPS and see error handling
- Turn off internet and test offline behavior
- Deny permissions and test recovery flow

### Expected Behavior:
✅ **Location tracking starts immediately** when toggled ON  
✅ **Map shows real-time position** with smooth updates  
✅ **Firebase Console shows location data** under `/locations/{uid}`  
✅ **Accuracy typically 3-10 meters** in open areas  
✅ **Auto-save every 10 meters** of movement  
✅ **Battery efficient** - only updates on significant movement  

### Firebase Data Structure:
Check Firebase Console → Realtime Database for:
```json
{
  "locations": {
    "user_uid_here": {
      "latitude": -6.2088,
      "longitude": 106.8456,
      "accuracy": 5.2,
      "altitude": 100.0,
      "speed": 1.4,
      "timestamp": 1640995200000,
      "lastUpdate": "2024-01-01T12:00:00Z",
      "userId": "user_uid_here"
    }
  }
}
```

## 🛠️ Troubleshooting

### Common Issues:

#### 1. Location Not Working
- **Check device GPS is ON**
- **Restart the app** and try again
- **Use restart button** in the app
- **Test in open area** (not indoors)

#### 2. Firebase Not Saving
- **Check internet connection**
- **Verify Firebase configuration** in `google-services.json`
- **Check database rules** in Firebase Console
- **Check user is authenticated** (logged in)

#### 3. Permission Issues
- **Manual enable in Settings** → Apps → UmrahTrack → Permissions
- **Clear app data** and test permission flow again
- **Check AndroidManifest.xml** has location permissions

#### 4. Map Not Loading
- **Check internet connection** for map tiles
- **Try different map zoom levels**
- **Clear app cache** and rebuild

#### 5. Poor Accuracy
- **Test outdoors** with clear sky view
- **Wait a few minutes** for GPS to stabilize
- **Check device GPS accuracy** in Settings

### Performance Tips:
- **Location updates every 10 meters** (configurable in LocationProvider)
- **Background tracking** works with proper permissions
- **Battery optimization** - disable for UmrahTrack app in Settings
- **Data usage** - minimal, only coordinates sent to Firebase

## 🔧 Customization Options

### Adjust Location Accuracy
In `LocationProvider.dart`:
```dart
final LocationSettings _locationSettings = const LocationSettings(
  accuracy: LocationAccuracy.high,     // Change accuracy level
  distanceFilter: 10,                  // Update every X meters
);
```

### Change Map Center (Default)
In `JamaahLokasiPage.dart`:
```dart
LatLng _currentMapCenter = const LatLng(21.4225, 39.8262); // Mecca
```

### Customize Map Appearance
- Change tile provider in FlutterMap TileLayer
- Add custom markers or overlays
- Modify zoom levels and bounds

## 📊 Monitoring & Analytics

### Firebase Console Monitoring:
1. **Realtime Database** → View live location updates
2. **Authentication** → Monitor user sessions
3. **Usage** → Track database read/write operations

### App Analytics:
- Monitor location permission acceptance rate
- Track location accuracy and update frequency
- Monitor GPS error rates and recovery

## 🔐 Security Notes

### Privacy Considerations:
- **Location data is sensitive** - only store what's necessary
- **User consent** - clearly explain why location is needed
- **Data retention** - consider automatic cleanup of old locations
- **Sharing controls** - allow users to control visibility

### Security Best Practices:
- **Database rules enforce user isolation**
- **Location data encrypted** in transit and at rest
- **No location sharing** between users without explicit permission
- **Regular security audits** of Firebase rules and access patterns

## 🚀 Next Steps

### Potential Enhancements:
1. **Location History** - Store and display movement history
2. **Geofencing** - Alerts when entering/leaving specific areas
3. **Group Tracking** - Allow travel agents to see jamaah locations
4. **Offline Support** - Cache locations when offline
5. **Battery Optimization** - Intelligent tracking intervals
6. **Location Sharing** - Optional sharing with emergency contacts

### Integration Opportunities:
- **Emergency Services** - Quick location sharing in emergencies
- **Travel Coordination** - Group meet-up points and navigation
- **Attendance Tracking** - Verify presence at specific locations
- **Safety Monitoring** - Automated check-ins and alerts
