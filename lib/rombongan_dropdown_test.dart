import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RombonganDropdownTest extends StatefulWidget {
  const RombonganDropdownTest({super.key});

  @override
  State<RombonganDropdownTest> createState() => _RombonganDropdownTestState();
}

class _RombonganDropdownTestState extends State<RombonganDropdownTest> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _rombonganList = [];
  String? _selectedRombonganFilter;
  String? _adminTravelId;
  String _status = 'Initializing...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      setState(() {
        _status = 'Loading admin data...';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Error: No authenticated user';
          _isLoading = false;
        });
        return;
      }

      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists) {
        setState(() {
          _status = 'Error: Admin document not found';
          _isLoading = false;
        });
        return;
      }

      _adminTravelId = adminDoc.data()?['travelId'];
      
      setState(() {
        _status = 'Admin TravelId: $_adminTravelId';
      });

      if (_adminTravelId == null) {
        setState(() {
          _status = 'Error: Admin has no travelId';
          _isLoading = false;
        });
        return;
      }

      await _loadRombonganList();
      
    } catch (e) {
      setState(() {
        _status = 'Error loading admin data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRombonganList() async {
    try {
      setState(() {
        _status += '\nLoading rombongan list...';
      });

      final rombonganQuery = await _firestore
          .collection('rombongan')
          .where('travelId', isEqualTo: _adminTravelId)
          .get();

      setState(() {
        _rombonganList = rombonganQuery.docs
            .map((doc) {
              final data = doc.data();
              final name = data['name'];
              String finalName;
              if (name == null || name.toString().trim().isEmpty) {
                final shortId = doc.id.length > 4 ? doc.id.substring(0, 4) : doc.id;
                finalName = 'Rombongan $shortId';
              } else {
                finalName = name.toString().trim();
              }
              
              return {
                'id': doc.id,
                'name': finalName,
                ...data
              };
            })
            .where((rombongan) => rombongan['name'].toString().isNotEmpty)
            .toList();
        
        _rombonganList.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        
        _status += '\nLoaded ${_rombonganList.length} rombongan: ${_rombonganList.map((r) => r['name']).join(', ')}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status += '\nError loading rombongan: $e';
        _isLoading = false;
      });
    }
  }

  List<DropdownMenuItem<String>> _buildRombonganDropdownItems() {
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Semua Rombongan'),
      ),
    ];

    Set<String> uniqueRombonganNames = {};
    for (var rombongan in _rombonganList) {
      final name = rombongan['name'] as String;
      if (name.isNotEmpty && !uniqueRombonganNames.contains(name)) {
        uniqueRombonganNames.add(name);
        items.add(
          DropdownMenuItem<String>(
            value: name,
            child: Text(name),
          ),
        );
      }
    }

    if (_selectedRombonganFilter != null && 
        !uniqueRombonganNames.contains(_selectedRombonganFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedRombonganFilter = null;
        });
      });
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rombongan Dropdown Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Status:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rombongan Dropdown Test:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedRombonganFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter Rombongan',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                items: _buildRombonganDropdownItems(),
                onChanged: (value) {
                  setState(() {
                    _selectedRombonganFilter = value;
                  });
                  print('Selected rombongan: $value');
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Selected: ${_selectedRombonganFilter ?? "Semua Rombongan"}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Available Rombongan:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _rombonganList.length,
                itemBuilder: (context, index) {
                  final rombongan = _rombonganList[index];
                  return Card(
                    child: ListTile(
                      title: Text(rombongan['name']),
                      subtitle: Text('ID: ${rombongan['id']}'),
                      trailing: Text('TravelId: ${rombongan['travelId'] ?? 'N/A'}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAdminData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
