import 'package:flutter/material.dart';

// Warga model class
class Warga {
  final String name;
  final String phone;
  final String address;
  final String rt;
  final String rw;
  
  Warga({
    required this.name, 
    required this.phone, 
    required this.address, 
    required this.rt, 
    required this.rw,
  });
}

// Search bar widget
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  
  const SearchBarWidget({
    Key? key, 
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Cari Data Warga',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

// Filter chip widget
class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  
  const FilterChipWidget({
    Key? key, 
    required this.label, 
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.blue)),
          const SizedBox(width: 5),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

// Warga card widget
class WargaCardWidget extends StatelessWidget {
  final Warga warga;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const WargaCardWidget({
    Key? key, 
    required this.warga, 
    required this.onEdit, 
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              warga.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(warga.phone),
            Text('${warga.address} • ${warga.rt} ${warga.rw}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: onEdit,
                    child: const Text('Edit', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: onDelete,
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Selectable Warga card widget for multi-select mode
class SelectableWargaCardWidget extends StatelessWidget {
  final Warga warga;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const SelectableWargaCardWidget({
    Key? key, 
    required this.warga, 
    required this.isSelected,
    required this.onToggleSelection,
    required this.onEdit, 
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggleSelection(),
              activeColor: Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warga.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(warga.phone),
                  Text('${warga.address} • ${warga.rt} ${warga.rw}'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: onEdit,
                          child: const Text('Edit', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: onDelete,
                          child: const Text('Hapus'),
                        ),
                      ),
                    ],
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

// Bottom action bar widget
class BottomActionBarWidget extends StatelessWidget {
  final VoidCallback onUploadCSV;
  final VoidCallback onAddData;
  
  const BottomActionBarWidget({
    Key? key, 
    required this.onUploadCSV, 
    required this.onAddData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onUploadCSV,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAddData,
            ),
          ),
        ],
      ),
    );
  }
}

// Filter popup dialog
class FilterPopupWidget extends StatefulWidget {
  final String initialRT;
  final String initialRW;
  final String initialGender;
  final Function(String, String, String) onApply;
  final VoidCallback onCancel;
  
  const FilterPopupWidget({
    Key? key, 
    required this.initialRT,
    required this.initialRW,
    required this.initialGender,
    required this.onApply,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FilterPopupWidget> createState() => _FilterPopupWidgetState();
}

class _FilterPopupWidgetState extends State<FilterPopupWidget> {
  late String _rt;
  late String _rw;
  late String _gender;
  
  @override
  void initState() {
    super.initState();
    _rt = widget.initialRT;
    _rw = widget.initialRW;
    _gender = widget.initialGender;
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
                      'Filter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RT'),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'RT',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            controller: TextEditingController(text: _rt),
                            onChanged: (value) {
                              setState(() {
                                _rt = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RW'),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'RW',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            controller: TextEditingController(text: _rw),
                            onChanged: (value) {
                              setState(() {
                                _rw = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Gender'),
                Row(
                  children: [
                    Checkbox(
                      value: _gender == 'Laki-laki' || _gender.isEmpty,
                      onChanged: (value) {
                        setState(() {
                          _gender = value! ? 'Laki-laki' : '';
                        });
                      },
                    ),
                    const Text('Laki-laki'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _gender == 'Perempuan' || _gender.isEmpty,
                      onChanged: (value) {
                        setState(() {
                          _gender = value! ? 'Perempuan' : '';
                        });
                      },
                    ),
                    const Text('Perempuan'),
                  ],
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
                        onPressed: () => widget.onApply(_rt, _rw, _gender),
                        child: const Text('Apply'),
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