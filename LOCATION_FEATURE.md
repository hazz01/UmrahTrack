# Fitur Lokasi Real-Time untuk Jamaah

## Deskripsi
Halaman lokasi jamaah telah dikembangkan dengan fitur-fitur berikut:

### ✅ Fitur yang Sudah Diimplementasikan:

1. **Map Real-Time dengan Flutter Map**
   - Menampilkan peta OpenStreetMap
   - Marker lokasi user real-time
   - Kontrol zoom dan pan
   - Auto-follow user location

2. **Tracking Lokasi Real-Time**
   - GPS tracking dengan akurasi tinggi
   - Update otomatis setiap 10 meter pergerakan
   - Simpan ke Firebase Realtime Database secara otomatis
   - Switch on/off untuk mengontrol tracking

3. **Kontrol Lokasi**
   - Tombol on/off tracking
   - Tombol restart untuk mengatasi lag/error
   - Tombol center map ke lokasi user
   - Mode auto-follow yang bisa dimatikan manual

4. **Informasi Lokasi Detail**
   - Koordinat latitude/longitude
   - Akurasi GPS (dalam meter)
   - Kecepatan pergerakan (km/h)
   - Status tracking aktif/tidak aktif

5. **Penanganan Error & Permission**
   - Request permission lokasi otomatis
   - Error handling untuk GPS tidak aktif
   - Tombol buka pengaturan aplikasi
   - Pesan error yang informatif

6. **Navigasi yang Diperbaiki**
   - Menggunakan `pushReplacementNamed` bukan `pop`
   - Bottom navigation yang konsisten
   - Navigasi antar halaman yang smooth

### 🔧 Struktur Teknis:

```
lib/
├── providers/
│   └── location_provider.dart      # Provider untuk state management lokasi
├── services/
│   └── location_service.dart       # Service untuk Firebase operations
└── presentation/
    └── pages/jamaah/
        └── jamaah_lokasi.dart      # Halaman lokasi utama
```

### 🗄️ Database Structure (Firebase Realtime Database):

```json
{
  "locations": {
    "[user_uid]": {
      "latitude": -6.2088,
      "longitude": 106.8456,
      "accuracy": 10.5,
      "altitude": 100.0,
      "speed": 5.2,
      "timestamp": 1640995200000,
      "lastUpdate": "2024-01-01T12:00:00Z",
      "userId": "[user_uid]"
    }
  }
}
```

### 📱 Permissions yang Ditambahkan:

**Android (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 📦 Dependencies yang Ditambahkan:

```yaml
firebase_database: ^11.1.7    # Firebase Realtime Database
geolocator: ^13.0.1          # GPS dan location services
permission_handler: ^11.3.1   # Handle permissions
```

### 🎯 Cara Penggunaan:

1. **Akses Halaman Lokasi:**
   - Dari bottom navigation bar jamaah
   - Atau dari quick action di homepage

2. **Aktivasi Tracking:**
   - Toggle switch di kartu status lokasi
   - Akan meminta permission lokasi pertama kali

3. **Kontrol Map:**
   - Tap dan drag untuk pan
   - Pinch untuk zoom
   - Tombol center untuk kembali ke lokasi user

4. **Restart jika Error:**
   - Gunakan tombol restart (ikon refresh orange)
   - Otomatis akan restart tracking

### 🔄 Real-Time Features:

- **Auto-save ke Firebase:** Setiap perubahan lokasi otomatis tersimpan
- **Live updates:** Map akan update posisi secara real-time
- **Background tracking:** Akan terus track meski app di background (dengan permission)
- **Efficient updates:** Hanya update saat ada pergerakan signifikan (10m)

### 🛡️ Error Handling:

- **GPS tidak aktif:** Arahkan user ke pengaturan
- **Permission ditolak:** Tampilkan pesan dan tombol pengaturan
- **Network error:** Retry otomatis untuk save ke Firebase
- **App crash:** Tracking akan otomatis restart saat app dibuka lagi

### 🎨 UI/UX Improvements:

- **Material Design 3** dengan gradient yang konsisten
- **Floating action buttons** untuk kontrol cepat
- **Status card** dengan informasi lengkap
- **Smooth animations** untuk transisi map
- **Error states** yang user-friendly
- **Loading indicators** saat mengakses GPS

### 🚀 Cara Testing:

1. Run aplikasi di device fisik (GPS tidak bekerja di emulator)
2. Pastikan lokasi/GPS aktif di device
3. Beri permission lokasi saat diminta
4. Toggle tracking on/off untuk test
5. Gerakkan device untuk melihat real-time update

### 📝 Catatan Penting:

- **Harus di device fisik:** Fitur GPS tidak bisa ditest di emulator
- **Battery usage:** Real-time tracking akan menggunakan battery
- **Data usage:** Saving ke Firebase membutuhkan internet
- **Accuracy:** Akurasi tergantung kondisi GPS dan lingkungan
