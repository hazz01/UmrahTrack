import 'dart:ui';

import 'package:flutter/material.dart';
import '../../widgets/bottom_navbar_admin.dart';

class KelolaWargaPage extends StatefulWidget {
  const KelolaWargaPage({super.key});

  @override
  State<KelolaWargaPage> createState() => _KelolaWargaPageState();
}

class _KelolaWargaPageState extends State<KelolaWargaPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRT = 'Pilih Travel';
  List<String> _rtList = [
    'Pilih Grub',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];

  String _selectedRW = 'Pilih RW';
  List<String> _rwList = [
    'Pilih Grub',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];

  bool _isSelectMode = false;
  bool _isFilterOpen = false;
  bool _isAddDataOpen = false;
  bool _isUploadCSVOpen = false;
  List<Warga> _wargaList = [];
  List<Warga> _selectedWarga = [];

  // Filter values
  String _filterRT = '';
  String _filterRW = '';
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Mock data for demonstration
    setState(() {
      _wargaList = List.generate(
        4,
        (index) => Warga(
          name: 'Budi Santoso',
          phone: '09990990${7970 + index}',
          address: 'Dekat Masjidil Haram',
          rt: 'Travel 1',
          rw: '',
        ),
      );
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedWarga.clear();
      }
    });
  }

  bool _isFilterPopupVisible = false;

  void _toggleFilterPopup() {
    if (!_isFilterPopupVisible) {
      _isFilterPopupVisible = true;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _buildFilterPopup();
        },
      ).whenComplete(() {
        // Ketika modal ditutup, set ke false lagi
        setState(() {
          _isFilterPopupVisible = false;
        });
      });
    }
  }

  bool _isAddDataPopupVisible = false;

  void _toggleAddDataPopup() {
    if (!_isAddDataPopupVisible) {
      _isAddDataPopupVisible = true;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _buildAddDataPopup();
        },
      ).whenComplete(() {
        // Ketika modal ditutup, set ke false lagi
        setState(() {
          _isAddDataPopupVisible = false;
        });
      });
    }
  }

  bool _isCSVPopupVisible = false;

  void _toggleUploadCSVPopup() {
    if (!_isCSVPopupVisible) {
      _isCSVPopupVisible = true;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _buildUploadCSVPopup();
        },
      ).whenComplete(() {
        // Ketika modal ditutup, set ke false lagi
        setState(() {
          _isCSVPopupVisible = false;
        });
      });
    }
    // setState(() {
    //   _isUploadCSVOpen = !_isUploadCSVOpen;

    //   showModalBottomSheet(
    //     context: context,
    //     isScrollControlled: true,
    //     backgroundColor: Colors.transparent,
    //     builder: (BuildContext context) {
    //       return _buildUploadCSVPopup();
    //     },
    //   ).whenComplete(() {
    //     // Ketika modal ditutup, set ke false lagi
    //     setState(() {
    //       _isFilterPopupSCVVisible = false;
    //     });
    //   });
    // });
  }

  void _toggleWargaSelection(Warga warga) {
    setState(() {
      if (_selectedWarga.contains(warga)) {
        _selectedWarga.remove(warga);
      } else {
        _selectedWarga.add(warga);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedWarga.length == _wargaList.length) {
        _selectedWarga.clear();
      } else {
        _selectedWarga = List.from(_wargaList);
      }
    });
  }

  void _applyFilter() {
    // Implementation for filter application
    _toggleFilterPopup();
  }

  void _hapusSelected() {
    setState(() {
      _wargaList.removeWhere((warga) => _selectedWarga.contains(warga));
      _selectedWarga.clear();
    });
  }

  void _hapusAll() {
    setState(() {
      _wargaList.clear();
      _selectedWarga.clear();
    });
  }

  void _showFilterOverlay() {
    _filterOverlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.5),
          child: _buildFilterPopup(),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true)?.insert(_filterOverlayEntry!);
  }

  void _hideFilterOverlay() {
    _filterOverlayEntry?.remove();
    _filterOverlayEntry = null;
  }

  OverlayEntry? _filterOverlayEntry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      // appBar: AppBar(
      //   backgroundColor: Color(0xFFF8F8F8),
      //   title: const Text('Kelola Data Warga'),
      //   actions: [
      //     if (_isSelectMode)
      //       IconButton(
      //         icon: const Icon(Icons.close),
      //         onPressed: _toggleSelectMode,
      //       ),
      //   ],
      // ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 70,
              ),
              _buildSearchBar(),
              SizedBox(
                height: 18,
              ),
              _buildFilterChips(),
              // SizedBox(
              //   height: 18,
              // ),
              Expanded(
                child:
                    _isSelectMode ? _buildSelectModeList() : _buildWargaList(),
              ),
            ],
          ),
          if (_isFilterOpen) _buildFilterPopup(),
          if (_isAddDataOpen) _buildAddDataPopup(),
          if (_isUploadCSVOpen) _buildUploadCSVPopup(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSelectMode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _hapusAll,
                child: const Text('Hapus Semua'),
              ),
            ),
          _buildBottomActionBar(),
          BottomNavbarAdmin(
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushNamed(context, '/admin/home');
                  break;
                case 1:
                  Navigator.pushNamed(context, '/admin/lokasi');
                  break;
                case 2:
                  Navigator.pushNamed(context, '/admin/cctv');
                  break;
                case 3:
                  Navigator.pushNamed(context, '/admin/surat');
                  break;
                case 4:
                  Navigator.pushNamed(context, '/admin/laporan');
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
            hintText: 'Cari Data Warga',
            prefixIcon: const Icon(
              Icons.search,
              size: 21,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(84),
              borderSide: const BorderSide(
                color: Color(0xFFB9B9B9),
                width: 1,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            hintStyle: const TextStyle(
                color:
                    Color(0x80000000), // Equivalent to black with 50% opacity
                fontSize: 14,
                fontWeight: FontWeight.w400),
            prefixIconColor: Color(0xFF1658B3)),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 60,
            decoration: BoxDecoration(
              color: Color(0xFF1658B3),
              borderRadius: BorderRadius.circular(84),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _toggleFilterPopup,
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Travel 1'),
          const SizedBox(width: 8),
          _buildFilterChip('Travel 2'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8F8),
        borderRadius: BorderRadius.circular(84),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              // Remove filter
            },
            child: const Icon(Icons.close, size: 20, color: Color(0xA61658B3)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF1658B3),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildWargaList() {
    return ListView.builder(
      itemCount: _wargaList.length,
      itemBuilder: (context, index) {
        final warga = _wargaList[index];
        return _buildWargaCard(warga);
      },
    );
  }

  Widget _buildSelectModeList() {
    return ListView.builder(
      itemCount: _wargaList.length,
      itemBuilder: (context, index) {
        final warga = _wargaList[index];
        return _buildSelectableWargaCard(warga);
      },
    );
  }

  Widget _buildWargaCard(Warga warga) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  warga.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black),
                ),
              ],
            ),
            Text(
              warga.phone,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF636363),
              ),
            ),
            Text(
              '${warga.address} • ${warga.rt} ${warga.rw}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF636363),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: Color(0x261658B3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(68),
                      ),
                    ),
                    onPressed: () {
                      // Implement edit functionality
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                          color: Color(0xFF1658B3),
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFFF4041),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(68),
                      ),
                    ),
                    onPressed: () {
                      // Implement edit functionality
                    },
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableWargaCard(Warga warga) {
    final isSelected = _selectedWarga.contains(warga);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleWargaSelection(warga),
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
                          onPressed: () {
                            // Implement edit functionality
                          },
                          child: const Text('Edit',
                              style: TextStyle(color: Colors.black)),
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
                          onPressed: () {
                            // Implement hapus functionality
                          },
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

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.sync,
                size: 28,
              ),
              label: const Text(
                'Auto Sync',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDDE8F8)),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 55),
                backgroundColor: Color(0xFF1658B3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(84),
                  side: const BorderSide(
                    color: Color(0xFFB0CAEF),
                    width: 1,
                  ),
                ),
              ),
              onPressed: () {
                // Implement auto sync functionality
              },
              // onPressed: _toggleUploadCSVPopup,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.add,
                size: 28,
                color: Color(0xFF1658B3),
              ),
              label: const Text(
                'New Person',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1658B3),
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 55),
                backgroundColor: Color(0xFFDCE6F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(84),
                  side: BorderSide.none,
                ),
              ),
              onPressed: _toggleAddDataPopup,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPopup() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {}, // agar tap pada konten tidak menutup modal
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                // Local variables for state within the modal
                String localSelectedRT = _selectedRT;
                String localSelectedRW = _selectedRW;
                String localFilterRW = _filterRW;
                String localGender = _gender;

                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 85,
                              height: 6,
                              color: Color(0xFFE1E1E1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text("")),
                              const Expanded(
                                flex: 12,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Filter',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Colors.black.withOpacity(0.65),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 23),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          dropdownColor: Colors.white,
                                          value: _selectedRT != 'Pilih Travel'
                                              ? _selectedRT
                                              : null,
                                          hint: Text(
                                            "Pilih Travel",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          isExpanded: true,
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              // Update both the modal state and parent state
                                              setModalState(() {
                                                localSelectedRT = newValue;
                                              });
                                              setState(() {
                                                _selectedRT = newValue;
                                              });
                                            }
                                          },
                                          items: _rtList
                                              .where((e) => e != 'Pilih Travel')
                                              .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text('Travel $value'),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Expanded(
                              //   child: Column(
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: [
                              //       Container(
                              //         padding: const EdgeInsets.symmetric(
                              //             horizontal: 16, vertical: 4),
                              //         decoration: BoxDecoration(
                              //           color: Colors.white,
                              //           borderRadius: BorderRadius.circular(20),
                              //           border: Border.all(
                              //               color: Colors.grey.shade300,
                              //               width: 1),
                              //         ),
                              //         child: DropdownButtonHideUnderline(
                              //           child: DropdownButton<String>(
                              //             dropdownColor: Colors.white,
                              //             value: _selectedRW != 'Pilih RW'
                              //                 ? _selectedRW
                              //                 : null,
                              //             hint: Text(
                              //               "Pilih RW",
                              //               style: TextStyle(
                              //                 fontSize: 16,
                              //                 fontWeight: FontWeight.w600,
                              //                 color: Colors.black,
                              //               ),
                              //             ),
                              //             isExpanded: true,
                              //             onChanged: (String? newValue) {
                              //               if (newValue != null) {
                              //                 // Update both the modal state and parent state
                              //                 setModalState(() {
                              //                   localSelectedRW = newValue;
                              //                 });
                              //                 setState(() {
                              //                   _selectedRW = newValue;
                              //                 });
                              //               }
                              //             },
                              //             items: _rwList
                              //                 .where((e) => e != 'Pilih RW')
                              //                 .map((String value) {
                              //               return DropdownMenuItem<String>(
                              //                 value: value,
                              //                 child: Text('RW $value'),
                              //               );
                              //             }).toList(),
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Gender',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      fillColor:
                                          MaterialStateProperty.all<Color>(
                                        Color(0xFF1658B3),
                                      ),
                                      value: _gender == 'Laki-laki' ||
                                          _gender.isEmpty,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localGender =
                                              value! ? 'Laki-laki' : '';
                                        });
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
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      fillColor:
                                          MaterialStateProperty.all<Color>(
                                        Color(0xFF1658B3),
                                      ),
                                      value: _gender == 'Perempuan' ||
                                          _gender.isEmpty,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localGender =
                                              value! ? 'Perempuan' : '';
                                        });
                                        setState(() {
                                          _gender = value! ? 'Perempuan' : '';
                                        });
                                      },
                                    ),
                                    const Text('Perempuan'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  label: const Text(
                                    'Apply',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDDE8F8)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFF1658B3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                      side: const BorderSide(
                                        color: Color(0xFFB0CAEF),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    _applyFilter();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  label: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1658B3),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFFDCE6F4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddDataPopup() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {}, // Ini untuk mencegah tap menutup modal
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 85,
                              height: 6,
                              color: Color(0xFFE1E1E1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text("")),
                              const Expanded(
                                flex: 12,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Add Data',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Colors.black.withOpacity(0.65),
                                  ),
                                  onPressed: () {
                                    _toggleAddDataPopup;
                                  },
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 23),
                          _buildFormField('Kode', 'Masukkan Kode Koneksi'),
                          const SizedBox(height: 8),
                          // _buildFormField('NIK', 'Masukkan NIK Warga'),
                          // const SizedBox(height: 8),
                          // _buildFormField('Alamat', 'Masukkan Alamat Warga'),
                          // const SizedBox(height: 8),
                          // _buildFormField('TTL', 'Tanggal / Bulan / Tahun'),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  label: const Text(
                                    'Upload',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDDE8F8)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFF1658B3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                      side: const BorderSide(
                                        color: Color(0xFFB0CAEF),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    _toggleAddDataPopup();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  label: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1658B3),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFFDCE6F4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                  onPressed: _toggleAddDataPopup,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCSVPopup() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {},
            // _toggleUploadCSVPopup
            child: StatefulBuilder(
              builder: (BuildContext content, StateSetter setModalState) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 85,
                              height: 6,
                              color: Color(0xFFE1E1E1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text("")),
                              const Expanded(
                                flex: 12,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Upload Data',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Colors.black.withOpacity(0.65),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 23),
                          CustomPaint(
                            painter: DashedBorderPainter(),
                            child: Container(
                              height: 230,
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                  16), // tambahkan padding jika dibutuhkan
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 30,
                                    color: Color(0xFF7F7F7F),
                                  ),
                                  SizedBox(
                                    height: 11,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // Upload CSV file logic
                                    },
                                    child: const Text(
                                      'Upload SCV',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7F7F7F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  label: const Text(
                                    'Upload',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDDE8F8)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFF1658B3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                      side: const BorderSide(
                                        color: Color(0xFFB0CAEF),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {},
                                  // _toggleUploadCSVPopup();
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                    label: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1658B3),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      minimumSize: const Size(0, 55),
                                      backgroundColor: Color(0xFFDCE6F4),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(84),
                                        side: BorderSide.none,
                                      ),
                                    ),
                                    onPressed: () {}
                                    // _toggleUploadCSVPopup,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, String hint) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for Warga data
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

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 50;
    double dashSpace = 4;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(16),
    );
    final path = Path()..addRRect(rect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
