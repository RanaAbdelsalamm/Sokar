import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_colors.dart';
import '../services/database_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

// --- Local Notifications Setup ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  
  try {
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.toString()));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  }
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('notification_icon');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
  
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
}

Future<void> scheduleNotification(int id, String title, String body, TimeOfDay time) async {
  final now = DateTime.now();
  var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'med_reminder_channel',
    'Medication Reminders',
    channelDescription: 'Notifications for your medication schedule',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
    notificationDetails: platformChannelSpecifics,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

// --- Reminder Models ---
class MedReminder {
  final String id;
  final int notifId; 
  final IconData icon;
  final String title;
  final String dosage;
  final TimeOfDay time;
  final DateTime date;
  bool isDaily;
  List<int> repeatDays; 
  
  Set<String> inactiveDates; 
  Set<String> deletedDates; 
  Map<String, bool> history; 

  bool isActive; 
  bool? isTaken;

  MedReminder({
    required this.id,
    required this.notifId,
    required this.icon,
    required this.title,
    required this.dosage,
    required this.time,
    required this.date,
    this.isDaily = false,
    this.repeatDays = const [],
    Set<String>? inactiveDates,
    Set<String>? deletedDates,
    Map<String, bool>? history,
    this.isActive = true,
    this.isTaken,
  }) : inactiveDates = inactiveDates ?? {},
       deletedDates = deletedDates ?? {},
       history = history ?? {};
}

// --- Reminders Screen ---
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => RemindersScreenState();
}

class RemindersScreenState extends State<RemindersScreen> {
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  
  final DatabaseService _db = DatabaseService();
  StreamSubscription<QuerySnapshot>? _remindersSub;

  final List<MedReminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    _listenToReminders();
  }

  void _listenToReminders() {
    _remindersSub = _db.getRemindersStream().listen((snapshot) {
      final List<MedReminder> loaded = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        IconData icon = Icons.medication;
        if (data['type'] == 'Insulin') icon = Icons.vaccines_outlined;
        if (data['type'] == 'Liquid') icon = Icons.water_drop_outlined;

        Map<String, bool> historyMap = {};
        if (data['history'] is Map) {
          (data['history'] as Map).forEach((k, v) => historyMap[k.toString()] = v == true);
        }

        // Parse notifId or generate a fallback one for older data
        int parsedNotifId = data['notifId'] ?? doc.id.hashCode.abs().remainder(100000);

        loaded.add(MedReminder(
          id: doc.id,
          notifId: parsedNotifId,
          icon: icon,
          title: data['title'] ?? '',
          dosage: data['dosage'] ?? '',
          time: TimeOfDay(hour: data['timeHour'] ?? 8, minute: data['timeMinute'] ?? 0),
          date: data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : DateTime.now(),
          isDaily: data['isDaily'] ?? false,
          repeatDays: data['repeatDays'] != null ? List<int>.from(data['repeatDays']) : [],
          isActive: data['isActive'] ?? true,
          history: historyMap,
          inactiveDates: data['inactiveDates'] != null ? Set<String>.from(data['inactiveDates']) : {},
          deletedDates: data['deletedDates'] != null ? Set<String>.from(data['deletedDates']) : {},
        ));
      }
      
      if (mounted) {
        setState(() {
          _reminders.clear();
          _reminders.addAll(loaded);
        });
      }
    });
  }

  @override
  void dispose() {
    _remindersSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    String dayStr;
    if (targetDate == today) {
      dayStr = 'Today';
    } else if (targetDate == tomorrow) {
      dayStr = 'Tomorrow';
    } else {
      dayStr = weekdays[date.weekday - 1];
    }

    return '$dayStr, ${date.day} ${months[date.month - 1]}';
  }

  String _getRepeatLabel(bool isDaily, List<int> days) {
    if (isDaily) return 'Daily';
    if (days.isEmpty) return 'Once';

    const shortDays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<String> selected = days.map((d) => shortDays[d]).toList();
    if (selected.length > 2) return '${selected.take(2).join(', ')}...';
    return selected.join(', ');
  }

  void _showRepeatPicker(BuildContext context, bool currentIsDaily, List<int> currentDays, Function(bool, List<int>) onSave) {
    bool tempDaily = currentIsDaily;
    List<int> tempDays = List.from(currentDays);
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Repeat', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                  TextButton(
                    onPressed: () {
                      onSave(tempDaily, tempDays);
                      Navigator.pop(context);
                    },
                    child: const Text('Save', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Once (Today)', style: TextStyle(color: AppColors.textMainTitle, fontWeight: FontWeight.w600)),
                        trailing: (!tempDaily && tempDays.isEmpty) ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                        onTap: () {
                          setDialogState(() {
                            tempDaily = false;
                            tempDays.clear();
                          });
                        },
                      ),
                      ListTile(
                        title: const Text('Daily', style: TextStyle(color: AppColors.textMainTitle, fontWeight: FontWeight.w600)),
                        trailing: tempDaily ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                        onTap: () {
                          setDialogState(() {
                            tempDaily = true;
                            tempDays.clear();
                          });
                        },
                      ),
                      const Divider(height: 1, color: AppColors.bgTabInactive),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('SPECIFIC DAYS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                        ),
                      ),
                      ...List.generate(7, (index) {
                        int dayValue = index + 1;
                        bool isSelected = tempDays.contains(dayValue);
                        return CheckboxListTile(
                          title: Text(dayNames[index], style: const TextStyle(color: AppColors.textMainTitle)),
                          value: isSelected,
                          activeColor: AppColors.primaryBlue,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              tempDaily = false; 
                              if (value == true) {
                                tempDays.add(dayValue);
                              } else {
                                tempDays.remove(dayValue);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  void showAddReminderSheet(BuildContext context) {
    String selectedType = 'Pill';
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    bool isDaily = false;
    List<int> repeatDays = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String unitText = selectedType == 'Liquid' ? 'ml' : selectedType == 'Insulin' ? 'units' : 'mg';
            String hintText = selectedType == 'Liquid' ? 'Enter liquid name' : selectedType == 'Insulin' ? 'Enter insulin name' : 'Enter pill name';
            String repeatLabel = _getRepeatLabel(isDaily, repeatDays);

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
                                _buildTypeOption(setSheetState, 'Pill', Icons.medication, selectedType, () { selectedType = 'Pill'; }),
                                _buildTypeOption(setSheetState, 'Insulin', Icons.vaccines_outlined, selectedType, () { selectedType = 'Insulin'; }),
                                _buildTypeOption(setSheetState, 'Liquid', Icons.water_drop_outlined, selectedType, () { selectedType = 'Liquid'; }),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Text('MEDICATION NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
                              child: TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  hintText: hintText,
                                  hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.5)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DOSAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
                                        child: TextField(
                                          controller: dosageController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            hintText: '00',
                                            hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.5)),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                            suffixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: AppColors.bgBlueCard, borderRadius: BorderRadius.circular(8)),
                                              child: Text(unitText, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                            ),
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
                                      const Text('REPEAT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          _showRepeatPicker(context, isDaily, repeatDays, (daily, days) {
                                            setSheetState(() {
                                              isDaily = daily;
                                              repeatDays = days;
                                            });
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(child: Text(repeatLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                              const Icon(Icons.repeat, color: AppColors.primaryBlue, size: 20),
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

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty && dosageController.text.isNotEmpty) {
                            String dosageText = '${dosageController.text} $unitText';
                            
                            // Generate a unique ID for the notification directly at creation time
                            int uniqueNotifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                            
                            _db.addReminder({
                              'notifId': uniqueNotifId, // Save the ID to database
                              'title': nameController.text,
                              'dosage': dosageText,
                              'type': selectedType,
                              'timeHour': selectedTime.hour,
                              'timeMinute': selectedTime.minute,
                              'date': Timestamp.fromDate(DateTime.now()),
                              'isDaily': isDaily,
                              'repeatDays': repeatDays,
                              'isActive': true,
                              'history': {},
                              'deletedDates': [],
                              'inactiveDates': [],
                            });
                            
                            scheduleNotification(
                              uniqueNotifId, 
                              'Time for your Medication!', 
                              'It\'s time to take $dosageText of ${nameController.text}.', 
                              selectedTime
                            );
                            
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
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                children: [
                  _buildUpcomingView(),
                  _buildAllRemindersView(),
                  _buildHistoryView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTabIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.textMainTitle : AppColors.textSubtitle)),
        ),
      ),
    );
  }

  List<MedReminder> _generateInstancesForDateRange(DateTime start, DateTime end, bool onlyPending) {
    List<MedReminder> instances = [];
    
    for (var med in _reminders) {
      DateTime medStart = DateTime(med.date.year, med.date.month, med.date.day);
      DateTime current = start.isBefore(medStart) ? medStart : start;
      
      while (!current.isAfter(end)) {
        String dateKey = '${current.year}-${current.month.toString().padLeft(2,'0')}-${current.day.toString().padLeft(2,'0')}';
        
        if (med.deletedDates.contains(dateKey)) {
          current = current.add(const Duration(days: 1));
          continue;
        }

        // Move to history if already interacted with
        if (onlyPending && med.history.containsKey(dateKey)) {
          current = current.add(const Duration(days: 1));
          continue;
        }
        
        bool shouldAdd = false;
        if (med.isDaily) {
          shouldAdd = true;
        } else if (med.repeatDays.isNotEmpty) {
          if (med.repeatDays.contains(current.weekday)) {
            shouldAdd = true;
          }
        } else {
          if (current.isAtSameMomentAs(medStart)) {
            shouldAdd = true;
          }
        }
        
        if (shouldAdd) {
          instances.add(MedReminder(
            id: '${med.id}_$dateKey',
            notifId: med.notifId, // Pass the unique ID
            icon: med.icon,
            title: med.title,
            dosage: med.dosage,
            time: med.time,
            date: current,
            isDaily: med.isDaily,
            repeatDays: med.repeatDays,
            isActive: !med.inactiveDates.contains(dateKey),
            isTaken: med.history[dateKey],
          ));
        }
        
        current = current.add(const Duration(days: 1));
      }
    }
    return instances;
  }

  Widget _buildUpcomingView() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final upcomingMeds = _generateInstancesForDateRange(today, tomorrow, true);

    upcomingMeds.sort((a, b) {
      int dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      return (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute);
    });

    Map<String, List<MedReminder>> grouped = {};
    for (var med in upcomingMeds) {
      String header = _formatHeader(med.date);
      if (!grouped.containsKey(header)) grouped[header] = [];
      grouped[header]!.add(med);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (upcomingMeds.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No upcoming reminders for today or tomorrow.", style: TextStyle(color: AppColors.textSubtitle)))),
        
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              const SizedBox(height: 16),
              ...entry.value.map((med) => _buildSwipeableCard(med)),
              const SizedBox(height: 8),
            ],
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAllRemindersView() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    final pendingMeds = _generateInstancesForDateRange(today, endOfWeek, true);
    
    pendingMeds.sort((a, b) {
      int dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      return (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute);
    });

    Map<String, List<MedReminder>> grouped = {};
    for (var med in pendingMeds) {
      String header = _formatHeader(med.date);
      if (!grouped.containsKey(header)) grouped[header] = [];
      grouped[header]!.add(med);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (pendingMeds.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No scheduled reminders.", style: TextStyle(color: AppColors.textSubtitle)))),
        
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              const SizedBox(height: 16),
              ...entry.value.map((med) => _buildSwipeableCard(med)),
              const SizedBox(height: 8),
            ],
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHistoryView() {
    List<MedReminder> historyMeds = [];
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    for (var med in _reminders) {
      DateTime medStart = DateTime(med.date.year, med.date.month, med.date.day);
      DateTime current = medStart;
      
      while (current.isBefore(todayMidnight.add(const Duration(days: 1)))) {
        String dateKey = '${current.year}-${current.month.toString().padLeft(2,'0')}-${current.day.toString().padLeft(2,'0')}';
        
        if (med.deletedDates.contains(dateKey)) {
          current = current.add(const Duration(days: 1));
          continue;
        }

        bool shouldAdd = false;
        if (med.isDaily) {
          shouldAdd = true;
        } else if (med.repeatDays.isNotEmpty && med.repeatDays.contains(current.weekday)) {
          shouldAdd = true;
        } else if (current.isAtSameMomentAs(medStart)) {
          shouldAdd = true;
        }

        if (shouldAdd) {
          bool? isTaken;
          
          if (med.history.containsKey(dateKey)) {
            // Evaluated explicitly by user
            isTaken = med.history[dateKey];
          } else if (current.isBefore(todayMidnight)) {
            // Marked as missed if day has passed
            isTaken = false; 
          }

          if (isTaken != null) {
            historyMeds.add(MedReminder(
              id: '${med.id}_$dateKey',
              notifId: med.notifId,
              icon: med.icon, title: med.title, dosage: med.dosage, time: med.time, date: current,
              isDaily: med.isDaily, repeatDays: med.repeatDays, isTaken: isTaken,
            ));
          }
        }
        current = current.add(const Duration(days: 1));
      }
    }
    
    historyMeds.sort((a, b) {
      int dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return (b.time.hour * 60 + b.time.minute).compareTo(a.time.hour * 60 + a.time.minute);
    });

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
        direction: DismissDirection.horizontal,
        
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.close, color: Colors.white, size: 32),
        ),
        
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: AppColors.textSuccessGreen, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.check, color: Colors.white, size: 32),
        ),
        
        onDismissed: (direction) {
          String parentId = med.id.split('_')[0];
          String dateKey = med.id.split('_')[1];
          bool isTaken = (direction == DismissDirection.endToStart);
          
          _db.updateReminderField(parentId, {'history.$dateKey': isTaken});
          
          // Cancel the notification using the unique ID
          final originalMed = _reminders.firstWhere((r) => r.id == parentId);
          flutterLocalNotificationsPlugin.cancel(id: originalMed.notifId);

          setState(() {
            originalMed.history[dateKey] = isTaken;
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
                    onChanged: (val) {
                      String parentId = med.id.split('_')[0];
                      String dateKey = med.id.split('_')[1];
                      final originalMed = _reminders.firstWhere((r) => r.id == parentId);
                      
                      List<String> updatedInactive = List<String>.from(originalMed.inactiveDates);
                      if (val) {
                        updatedInactive.remove(dateKey);
                      } else {
                        updatedInactive.add(dateKey);
                      }
                      
                      _db.updateReminderField(parentId, {'inactiveDates': updatedInactive});
                      
                      // Notification logic correctly maps to the exact unique ID 
                      if (val) {
                        scheduleNotification(
                          originalMed.notifId,
                          'Time for your Medication!',
                          'It\'s time to take ${originalMed.dosage} of ${originalMed.title}.',
                          originalMed.time
                        );
                      } else {
                        flutterLocalNotificationsPlugin.cancel(id: originalMed.notifId);
                      }
                      
                      setState(() {
                        if (val) {
                          originalMed.inactiveDates.remove(dateKey);
                        } else {
                          originalMed.inactiveDates.add(dateKey);
                        }
                      });
                    }, 
                    activeTrackColor: AppColors.primaryBlue
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.bgTabInactive)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.textSubtitle), 
                      const SizedBox(width: 4), 
                      Text(med.time.format(context), style: const TextStyle(color: AppColors.textSubtitle, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textSubtitle, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(_getRepeatLabel(med.isDaily, med.repeatDays).toUpperCase(), style: const TextStyle(color: AppColors.textSubtitle, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ), 
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.textSubtitle, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      String parentId = med.id.split('_')[0];
                      String dateKey = med.id.split('_')[1];
                      final originalMed = _reminders.firstWhere((r) => r.id == parentId);
                      
                      List<String> updatedDeleted = List<String>.from(originalMed.deletedDates);
                      updatedDeleted.add(dateKey);
                      
                      _db.updateReminderField(parentId, {'deletedDates': updatedDeleted});
                      
                      // Cancel exact notification instantly
                      flutterLocalNotificationsPlugin.cancel(id: originalMed.notifId);

                      setState(() {
                        originalMed.deletedDates.add(dateKey);
                      });
                    },
                  ),
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
          Icon(isTaken ? Icons.check_circle : Icons.cancel, color: isTaken ? AppColors.textSuccessGreen : Colors.red, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isTaken ? AppColors.textSuccessGreen : Colors.red, decoration: TextDecoration.lineThrough, decorationThickness: 2)),
                Text(_formatHeader(med.date), style: const TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
          Text(med.time.format(context), style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13)),
        ],
      ),
    );
  }
}