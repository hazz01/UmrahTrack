import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> login(String username, String password) async {
    // Contoh login manual
    if (username == 'admin') {
      _currentUser = UserModel(id: '1', name: 'Admin RT', role: 'admin');
    } else {
      _currentUser = UserModel(id: '2', name: 'Warga A', role: 'warga');
    }
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
