class MapboxConfig {
  static const String accessToken = 'pk.eyJ1IjoiaDQyNCIsImEiOiJja21ycXB0dnQwYWhnMnZudGR3eWFlOGJnIn0.NYHwuoDP3269P5dsZ7-HLQ';
    // Mapbox tile URLs for flutter_map
  static String get streetTileUrl => 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$accessToken';
  static String get satelliteTileUrl => 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{z}/{x}/{y}?access_token=$accessToken';
  static String get outdoorsTileUrl => 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/tiles/{z}/{x}/{y}?access_token=$accessToken';
  static String get darkTileUrl => 'https://api.mapbox.com/styles/v1/mapbox/dark-v10/tiles/{z}/{x}/{y}?access_token=$accessToken';
  static String get lightTileUrl => 'https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}?access_token=$accessToken';
  // Default settings
  static String get defaultTileUrl => streetTileUrl;
  static const double defaultZoom = 15.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 3.0;
  
  // Mecca coordinates (default center)
  static const double meccaLatitude = 21.4225;
  static const double meccaLongitude = 39.8262;
}
