import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelRegistrationPage extends StatefulWidget {
  const TravelRegistrationPage({Key? key}) : super(key: key);

  @override
  State<TravelRegistrationPage> createState() => _TravelRegistrationPageState();
}

class _TravelRegistrationPageState extends State<TravelRegistrationPage> {
  int currentPage = 0;
  final PageController _pageController = PageController();
  
  // Form keys untuk setiap halaman
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKey3 = GlobalKey<FormState>();
    // Controllers untuk form fields
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _travelNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _ppivLicenseController = TextEditingController();
  final TextEditingController _ihkLicenseController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerNikController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  
  // Controllers untuk admin/PIC
  final List<TextEditingController> _adminNameControllers = [TextEditingController()];
  final List<TextEditingController> _adminNikControllers = [TextEditingController()];
  
  bool _isSubmitting = false;
  bool _dataConfirmation = false;
  @override
  void dispose() {
    _pageController.dispose();
    _companyNameController.dispose();
    _travelNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _licenseNumberController.dispose();
    _ppivLicenseController.dispose();
    _ihkLicenseController.dispose();
    _ownerNameController.dispose();
    _ownerNikController.dispose();
    _ownerPhoneController.dispose();
    
    // Dispose admin controllers
    for (var controller in _adminNameControllers) {
      controller.dispose();
    }
    for (var controller in _adminNikControllers) {
      controller.dispose();
    }
      super.dispose();
  }

  // Add new admin field
  void _addAdminField() {
    setState(() {
      _adminNameControllers.add(TextEditingController());
      _adminNikControllers.add(TextEditingController());
    });
  }

  // Remove admin field
  void _removeAdminField(int index) {
    if (_adminNameControllers.length > 1) {
      setState(() {
        _adminNameControllers[index].dispose();
        _adminNikControllers[index].dispose();
        _adminNameControllers.removeAt(index);
        _adminNikControllers.removeAt(index);
      });
    }
  }

  // Get current form key based on page
  GlobalKey<FormState> _getCurrentFormKey() {
    switch (currentPage) {
      case 0:
        return _formKey1;
      case 1:
        return _formKey2;
      case 2:
        return _formKey3;
      default:
        return _formKey1;
    }
  }
  // Validate current page
  bool _validateCurrentPage() {
    print("=== VALIDATING PAGE $currentPage ===");
    
    final formKey = _getCurrentFormKey();
    print("Form key: $formKey");
    print("Form key currentState: ${formKey.currentState}");
    
    if (formKey.currentState == null) {
      print("ERROR: Form key currentState is null");
      return false;
    }
    
    final isValid = formKey.currentState!.validate();
    print("Page $currentPage validation result: $isValid");
    
    // Additional validation for page 3 (data confirmation checkbox)
    if (currentPage == 2 && !_dataConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui kebenaran data yang disampaikan'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return isValid;
  }

  // Navigate to next page
  void _nextPage() {
    print("=== TOMBOL LANJUT DITEKAN ===");
    print("Current page: $currentPage");
    
    final isValid = _validateCurrentPage();
    print("Page valid: $isValid");
    
    if (isValid) {
      if (currentPage < 2) {
        setState(() {
          currentPage++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        print("Moving to page: $currentPage");
      } else {
        // Last page, submit form
        _submitRegistration();
      }
    } else {
      print("Validation failed, staying on current page");
    }
  }

  // Navigate to previous page
  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Submit complete registration
  Future<void> _submitRegistration() async {
    print("=== SUBMITTING REGISTRATION ===");
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }      // Update user document with complete travel information
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'companyName': _companyNameController.text.trim(),
        'travelName': _travelNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'website': _websiteController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'ppivLicense': _ppivLicenseController.text.trim(),
        'ihkLicense': _ihkLicenseController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'ownerNik': _ownerNikController.text.trim(),
        'ownerPhone': _ownerPhoneController.text.trim(),
        'admins': _adminNameControllers.asMap().entries.map((entry) => {
          'name': entry.value.text.trim(),
          'nik': _adminNikControllers[entry.key].text.trim(),
        }).toList(),
        'dataConfirmation': _dataConfirmation,
        'registrationStatus': 'complete',
        'verified': false, // Default to false, will be verified by admin
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login kembali.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login page
      Navigator.of(context).pushReplacementNamed('/login');
      
    } catch (e) {
      print("Error submitting registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registrasi Travel'),
        backgroundColor: const Color(0xFF1658B3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= currentPage ? const Color(0xFF1658B3) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1658B3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                if (currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1658B3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(currentPage < 2 ? 'Lanjut' : 'Selesai'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Form(
      key: _formKey1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Perusahaan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1658B3),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Langkah 1 dari 3',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
              TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Perusahaan Travel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama perusahaan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _travelNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Travel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tour),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama travel harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _ppivLicenseController,
              decoration: const InputDecoration(
                labelText: 'No Izin PPIV',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.verified_user),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'No Izin PPIV harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _ihkLicenseController,
              decoration: const InputDecoration(
                labelText: 'No Izin IHK (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_membership),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return Form(
      key: _formKey2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kontak & Website',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1658B3),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Langkah 2 dari 3',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Perusahaan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email harus diisi';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.web),
                hintText: 'https://www.example.com',
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'Nomor Induk Berusaha (NIB)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor izin usaha harus diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage3() {
    return Form(
      key: _formKey3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,          children: [
            const Text(
              'Informasi Pemilik',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1658B3),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Langkah 3 dari 3',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemilik/Direktur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pemilik harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ownerNikController,
              decoration: const InputDecoration(
                labelText: 'NIK/KTP Pemilik',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'NIK/KTP harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _ownerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP Pemilik',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor HP pemilik harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Admin delegation section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pemberian Kuasa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dengan ini memberikan kuasa kepada PT ${_companyNameController.text.isEmpty ? "[Nama PT]" : _companyNameController.text} sebagai admin/PIC dalam mengoperasikan aplikasi ini:',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dynamic admin fields
                  ...List.generate(_adminNameControllers.length, (index) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Admin ${index + 1}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              if (_adminNameControllers.length > 1)
                                IconButton(
                                  onPressed: () => _removeAdminField(index),
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminNameControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Nama Admin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama admin harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _adminNikControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'NIK/KTP Admin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.credit_card),
                              suffixIcon: Icon(Icons.upload_file),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'NIK/KTP admin harus diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Add admin button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _addAdminField,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1658B3),
                        side: const BorderSide(color: Color(0xFF1658B3)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Data confirmation checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _dataConfirmation,
                  onChanged: (value) {
                    setState(() {
                      _dataConfirmation = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF1658B3),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dengan ini menyatakan seluruh data yang disampaikan adalah benar',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF1658B3),
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Informasi Penting',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Setelah menyelesaikan registrasi, akun Anda akan diverifikasi oleh tim kami. Proses ini dapat memakan waktu 1-2 hari kerja.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}