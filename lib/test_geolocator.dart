import 'package:flutter/material.dart';
import 'package:location/location.dart';

class TestLocationPage extends StatefulWidget {
  const TestLocationPage({super.key});

  @override
  State<TestLocationPage> createState() => _TestLocationPageState();
}

class _TestLocationPageState extends State<TestLocationPage> {
  String _status = 'Press button to test location';
  bool _isLoading = false;
  Location location = Location();

  Future<void> _testLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing location...';
    });

    try {
      // Test if the plugin is properly registered
      final serviceEnabled = await location.serviceEnabled();
      setState(() {
        _status = 'Success! Location service enabled: $serviceEnabled';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Location'),
        backgroundColor: const Color(0xFF1658B3),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _testLocation,
                      child: const Text('Test Location Plugin'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
