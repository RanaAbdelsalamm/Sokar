import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class MedReminder {
  final String id;
  final IconData icon;
  final String title;
  final String dosage;
  final TimeOfDay time;
  final DateTime date;
  bool isActive;
  bool? isTaken; 

  MedReminder({
    required this.id,
    required this.icon,
    required this.title,
    required this.dosage,
    required this.time,
    required this.date,
    this.isActive = true,
    this.isTaken,
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => RemindersScreenState(); 
}

class RemindersScreenState extends State<RemindersScreen> {
  int _selectedTabIndex = 0; 
  bool _showSmartSuggestion = true;

  final List<MedReminder> _reminders = [
    MedReminder(
      id: '1',
      icon: Icons.medication_outlined,
      title: 'Metformin',
      dosage: '500mg',
      time: const TimeOfDay(hour: 8, minute: 0),
      date: DateTime.now(), 
    ),
  ];

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void showAddReminderSheet(BuildContext context) {
    String selectedType = 'Pill';
    IconData selectedIcon = Icons.medication_outlined;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            
          
            String unitText = selectedType == 'Liquid' ? 'ml' : selectedType == 'Insulin' ? 'units' : 'mg';
            String hintText = selectedType == 'Liquid' ? 'e.g. NyQuil' : 'e.g. Metformin';

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textMainTitle)),
                        const SizedBox(width: 48), 
                      ],
                    ),
                    const SizedBox(height: 16),

                  
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SELECT TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTypeOption(setSheetState, 'Pill', Icons.medication, selectedType, () { selectedType = 'Pill'; selectedIcon = Icons.medication; }),
                                _buildTypeOption(setSheetState, 'Insulin', Icons.vaccines_outlined, selectedType, () { selectedType = 'Insulin'; selectedIcon = Icons.vaccines_outlined; }),
                                _buildTypeOption(setSheetState, 'Liquid', Icons.water_drop_outlined, selectedType, () { selectedType = 'Liquid'; selectedIcon = Icons.water_drop_outlined; }),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // شرط: لو انسولين هنخفي خانة الاسم خالص
                            if (selectedType != 'Insulin') ...[
                              const Text('MEDICATION NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  hintText: hintText,
                                  filled: true,
                                  fillColor: const Color(0xFFF2F4F7),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DOSAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: dosageController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          hintText: '500',
                                          filled: true,
                                          fillColor: const Color(0xFFF2F4F7),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                          suffixIcon: Container(
                                            margin: const EdgeInsets.all(8),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: AppColors.bgBlueCard, borderRadius: BorderRadius.circular(8)),
                                            child: Text(unitText, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2030),
                                          );
                                          if (picked != null) setSheetState(() => selectedDate = picked);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          decoration: BoxDecoration(color: const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(16)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${selectedDate.day} ${_getMonthName(selectedDate.month)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                                              const Icon(Icons.calendar_today, color: AppColors.primaryBlue, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Text('REMINDER TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                                if (picked != null) setSheetState(() => selectedTime = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(selectedTime.format(context), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                                    Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppColors.bgBlueCard, shape: BoxShape.circle), child: const Icon(Icons.access_time, color: AppColors.primaryBlue)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Save Button (Fixed at the bottom)
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          bool isValid = dosageController.text.isNotEmpty && (selectedType == 'Insulin' || nameController.text.isNotEmpty);
                          
                          if (isValid) {
                            String finalName = selectedType == 'Insulin' ? 'Insulin' : nameController.text;
                            
                            setState(() {
                              _reminders.add(MedReminder(
                                id: DateTime.now().toString(),
                                icon: selectedIcon,
                                title: finalName,
                                dosage: '${dosageController.text} $unitText',
                                time: selectedTime,
                                date: selectedDate,
                              ));
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
                        child: const Text('Save Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeOption(StateSetter setSheetState, String title, IconData icon, String selectedValue, VoidCallback onTap) {
    bool isSelected = title == selectedValue;
    return GestureDetector(
      onTap: () {
        onTap();
        setSheetState(() {});
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.textMainTitle, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppColors.primaryBlue : AppColors.textMainTitle)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.only(top: 24, bottom: 16), child: Text('Reminders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMainTitle))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    _buildTabButton('Upcoming', 0),
                    _buildTabButton('All', 1),
                    _buildTabButton('History', 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: return _buildUpcomingView();
      case 1: return _buildAllRemindersView();
      case 2: return _buildHistoryView();
      default: return _buildUpcomingView();
    }
  }

  Widget _buildTabButton(String title, int index) {
    final bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.textMainTitle : AppColors.textSubtitle)),
        ),
      ),
    );
  }

  Widget _buildUpcomingView() {
    final now = DateTime.now();
    final upcomingMeds = _reminders.where((r) => r.isTaken == null && (r.date.day == now.day || r.date.day == now.add(const Duration(days: 1)).day)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_showSmartSuggestion) ...[
          _buildSmartSuggestion(),
          const SizedBox(height: 24),
        ],
        const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
        const SizedBox(height: 16),
        if (upcomingMeds.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No upcoming reminders.", style: TextStyle(color: AppColors.textSubtitle)))),
        ...upcomingMeds.map((med) => _buildSwipeableCard(med)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAllRemindersView() {
    final pendingMeds = _reminders.where((r) => r.isTaken == null).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('All Scheduled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
        const SizedBox(height: 16),
        if (pendingMeds.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No scheduled reminders.", style: TextStyle(color: AppColors.textSubtitle)))),
        ...pendingMeds.map((med) => _buildSwipeableCard(med)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHistoryView() {
    final historyMeds = _reminders.where((r) => r.isTaken != null).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
        const SizedBox(height: 16),
        if (historyMeds.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No history yet.", style: TextStyle(color: AppColors.textSubtitle)))),
        ...historyMeds.map((med) => _buildHistoryItem(med)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSwipeableCard(MedReminder med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(med.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
        ),
        onDismissed: (direction) {
          setState(() {
            _reminders.removeWhere((r) => r.id == med.id);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: AppColors.iconBgLight, shape: BoxShape.circle), child: Icon(med.icon, color: AppColors.primaryBlue)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(med.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(med.dosage, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13))])),
                  CupertinoSwitch(
                    value: med.isActive, 
                    onChanged: (val) => setState(() => med.isActive = val), 
                    activeTrackColor: AppColors.primaryBlue
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.bgTabInactive)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Row(children: [const Icon(Icons.access_time, size: 16, color: AppColors.textSubtitle), const SizedBox(width: 4), Text(med.time.format(context), style: const TextStyle(color: AppColors.textSubtitle, fontWeight: FontWeight.w600))]), 
                  Row(
                    children: [
                      IconButton(onPressed: () => setState(() => med.isTaken = true), icon: const Icon(Icons.check_circle_outline, color: AppColors.textSuccessGreen)),
                      IconButton(onPressed: () => setState(() => med.isTaken = false), icon: const Icon(Icons.cancel_outlined, color: Colors.red)),
                    ],
                  )
                ]
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(MedReminder med) {
    bool isTaken = med.isTaken ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(isTaken ? Icons.check_circle : Icons.cancel, color: isTaken ? AppColors.primaryBlue : Colors.red, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(med.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isTaken ? AppColors.primaryBlue : Colors.red, decoration: TextDecoration.lineThrough, decorationThickness: 2))),
          Text(med.time.format(context), style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSmartSuggestion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEBF4FA), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Suggestion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                SizedBox(height: 4),
                Text('You usually take Lantus before dinner. Set a reminder for 7:00 PM?', style: TextStyle(fontSize: 13, color: AppColors.textSubtitle, height: 1.4)),
              ],
            )
          ),
          const SizedBox(width: 16), 
          ElevatedButton(
            onPressed: () {
              setState(() {
                _reminders.add(MedReminder(
                  id: DateTime.now().toString(),
                  icon: Icons.vaccines_outlined,
                  title: 'Lantus Insulin',
                  dosage: '10 units',
                  time: const TimeOfDay(hour: 19, minute: 0),
                  date: DateTime.now(),
                ));
                _showSmartSuggestion = false; 
              });
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), 
            child: const Text('Set', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}