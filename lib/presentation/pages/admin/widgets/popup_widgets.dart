import 'package:flutter/material.dart';

// Add Data popup dialog
class AddDataPopupWidget extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  
  const AddDataPopupWidget({
    Key? key, 
    required this.onSave, 
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AddDataPopupWidget> createState() => _AddDataPopupWidgetState();
}

class _AddDataPopupWidgetState extends State<AddDataPopupWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _addressController.dispose();
    _ttlController.dispose();
    super.dispose();
  }
  
  Widget _buildFormField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onCancel,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            height: double.infinity,
            width: double.infinity,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormField('Nama', 'Masukkan Nama Warga', _nameController),
                const SizedBox(height: 10),
                _buildFormField('NIK', 'Masukkan NIK Warga', _nikController),
                const SizedBox(height: 10),
                _buildFormField('Alamat', 'Masukkan Alamat Warga', _addressController),
                const SizedBox(height: 10),
                _buildFormField('TTL', 'Tanggal / Bulan / Tahun', _ttlController),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onSave,
                        child: const Text('Upload'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onCancel,
                        child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Upload CSV popup dialog
class UploadCSVPopupWidget extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onCancel;
  final VoidCallback onSelectFile;
  
  const UploadCSVPopupWidget({
    Key? key, 
    required this.onUpload, 
    required this.onCancel,
    required this.onSelectFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            height: double.infinity,
            width: double.infinity,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upload Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file, size: 40),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onSelectFile,
                        child: const Text('Upload CSV'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onUpload,
                        child: const Text('Upload'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onCancel,
                        child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Select All action component
class SelectAllActionWidget extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onHapusAll;
  
  const SelectAllActionWidget({
    Key? key, 
    required this.selectedCount, 
    required this.totalCount,
    required this.onSelectAll,
    required this.onHapusAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool allSelected = selectedCount == totalCount && totalCount > 0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (_) => onSelectAll(),
                activeColor: Colors.blue,
              ),
              const Text('Pilih Semua'),
              const Spacer(),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onHapusAll,
              child: const Text('Hapus Semua'),
            ),
          ),
        ),
      ],
    );
  }
}