import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'plan_screen.dart'; 
import 'reminders_screen.dart'; 
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _selectedTab = 1; 

  final GlobalKey<RemindersScreenState> remindersKey = GlobalKey<RemindersScreenState>();

  String _latestReading = '110';
  DateTime _lastReadingTime = DateTime.now().subtract(const Duration(minutes: 10));
  String _readingStatus = 'In Range';
  Color _readingStatusColor = AppColors.textSuccessGreen; 

  final TextEditingController _glucoseController = TextEditingController();
  String _selectedMealTime = 'Fasting';

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _evaluateReading(int reading, String mealTime) {
    String newStatus = 'In Range';
    Color newColor = AppColors.textSuccessGreen;

    if (reading < 70) {
      newStatus = 'Low';
      newColor = Colors.red;
    } else {
      if (mealTime == 'Fasting' && reading > 130) {
        newStatus = 'High';
        newColor = Colors.red;
      } else if (mealTime == 'After Meal' && reading > 180) {
        newStatus = 'High';
        newColor = Colors.red;
      } else if (mealTime == 'Before Bed' && reading > 140) {
        newStatus = 'High';
        newColor = Colors.red;
      }
    }

    setState(() {
      _latestReading = reading.toString();
      _lastReadingTime = DateTime.now();
      _readingStatus = newStatus;
      _readingStatusColor = newColor;
    });
  }

  void _showAddReadingSheet() {
    _glucoseController.clear(); 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Log Glucose Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textSubtitle)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEEF1F1))),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _glucoseController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], textAlign: TextAlign.center, maxLength: 3,
                                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: AppColors.textMainTitle, height: 1.1),
                                  decoration: const InputDecoration(border: InputBorder.none, counterText: "", hintText: '000', hintStyle: TextStyle(color: AppColors.borderDashed)),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.only(bottom: 12.0), child: Text('mg/dL', style: TextStyle(fontSize: 20, color: AppColors.textSubtitle, fontWeight: FontWeight.w500))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.water_drop_outlined, color: AppColors.primaryBlue, size: 18), SizedBox(width: 8), Text('Blood Sugar', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600))]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('When did you measure?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: [
                        _buildMealOption(setSheetState, 'Fasting', Icons.wb_twilight),
                        _buildMealOption(setSheetState, 'After Meal', Icons.restaurant),
                        _buildMealOption(setSheetState, 'Before Bed', Icons.nights_stay_outlined),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_glucoseController.text.isNotEmpty) {
                            _evaluateReading(int.parse(_glucoseController.text), _selectedMealTime);
                            Navigator.pop(context); 
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
                        child: const Text('Save Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildMealOption(StateSetter setSheetState, String title, IconData icon) {
    final bool isSelected = _selectedMealTime == title;
    return GestureDetector(
      onTap: () => setSheetState(() => _selectedMealTime = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isSelected ? AppColors.primaryBlue : const Color(0xFFEEF1F1), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSubtitle), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSubtitle))]),
      ),
    );
  }

  Widget? _getFloatingActionButton() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(onPressed: _showAddReadingSheet, backgroundColor: AppColors.primaryBlue, elevation: 4, shape: const CircleBorder(), child: const Icon(Icons.add, color: Colors.white, size: 32));
    } else if (_selectedIndex == 2) {
      return FloatingActionButton(onPressed: () => remindersKey.currentState?.showAddReminderSheet(context), backgroundColor: AppColors.primaryBlue, elevation: 4, shape: const CircleBorder(), child: const Icon(Icons.add, color: Colors.white, size: 32));
    }
    return null; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundLight,
      appBar: _selectedIndex == 0 ? AppBar(backgroundColor: AppColors.backgroundLight, elevation: 0, centerTitle: true, title: const Text('Glucose Dashboard', style: TextStyle(color: AppColors.textMainTitle, fontSize: 20, fontWeight: FontWeight.bold)), automaticallyImplyLeading: false) : null,
      
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(), 
          const PlanScreen(),    
          RemindersScreen(key: remindersKey), 
          const ProfileScreen(),
        ],
      ),
      
      floatingActionButton: _getFloatingActionButton(),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLatestReadingCard(),
          const SizedBox(height: 24),
          _buildTimeTabs(),
          const SizedBox(height: 16),
          _buildChartCard(),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _buildSmallStatCard('Average Glucose', '125', 'mg/dL')), const SizedBox(width: 16), Expanded(child: _buildSmallStatCard('Time in Range', '85', '%'))]),
          const SizedBox(height: 16),
          _buildHbA1cCard(),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  Widget _buildLatestReadingCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Reading: ${_getTimeAgo(_lastReadingTime)}', style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(_latestReading, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)), const SizedBox(width: 8), const Text('mg/dL', style: TextStyle(fontSize: 18, color: AppColors.textSubtitle, fontWeight: FontWeight.w500))]),
          const SizedBox(height: 8),
          Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _readingStatusColor, shape: BoxShape.circle)), const SizedBox(width: 8), Text(_readingStatus, style: TextStyle(color: _readingStatusColor, fontWeight: FontWeight.bold, fontSize: 14))]),
        ],
      ),
    );
  }

  Widget _buildTimeTabs() {
    return Container(
      height: 44, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.bgTabInactive, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [_buildTabItem('24h', 0), _buildTabItem('7D', 1), _buildTabItem('30D', 2)]),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(color: isActive ? AppColors.bgTabActive : Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []),
          alignment: Alignment.center, child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.textMainTitle : AppColors.textSubtitle)),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Glucose Levels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)), Text('+5% from last week', style: TextStyle(fontSize: 13, color: AppColors.primaryBlue, fontWeight: FontWeight.w500))]),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false, 
                  horizontalInterval: 1, 
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.borderDashed, strokeWidth: 1)
                ),
                titlesData: FlTitlesData(
                  show: true, 
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 30, 
                      interval: 1, 
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: AppColors.textMainTitle, fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('Mon', style: style); break;
                          case 1: text = const Text('Tue', style: style); break;
                          case 2: text = const Text('Wed', style: style); break;
                          case 3: text = const Text('Thu', style: style); break;
                          case 4: text = const Text('Fri', style: style); break;
                          case 5: text = const Text('Sat', style: style); break;
                          case 6: text = const Text('Sun', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, space: 10, child: text);
                      }
                    )
                  )
                ),
                borderData: FlBorderData(show: false), 
                minX: 0, maxX: 6, minY: 0, maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1), FlSpot(0.5, 3), FlSpot(1.2, 2.5), FlSpot(1.8, 1), FlSpot(2.2, 2.5), 
                      FlSpot(3, 1), FlSpot(3.5, 2.2), FlSpot(4, 2.5), FlSpot(4.5, 0.2), FlSpot(5.2, 3.2), 
                      FlSpot(5.8, 0.8), FlSpot(6, 2.8)
                    ], 
                    isCurved: true, 
                    color: AppColors.chartLineBlue, 
                    barWidth: 3, 
                    isStrokeCapRound: true, 
                    dotData: const FlDotData(show: false), 
                    belowBarData: BarAreaData(show: true, color: AppColors.chartLineBlue.withValues(alpha: 0.15))
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, String unit) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)), if (unit.isNotEmpty) ...[const SizedBox(width: 4), Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.textSubtitle))]])]));
  }

  Widget _buildHbA1cCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Est. HbA1c', style: TextStyle(color: AppColors.textSubtitle, fontSize: 13)), SizedBox(height: 8), Text('6.5%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle))]));
  }

  Widget _buildFloatingBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildNavItem(icon: Icons.home_filled, label: 'Home', index: 0), _buildNavItem(icon: Icons.restaurant, label: 'Plan', index: 1), _buildNavItem(icon: Icons.notifications_none, label: 'Reminders', index: 2), _buildNavItem(icon: Icons.person_outline, label: 'Profile', index: 3)]),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index), behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSelected ? AppColors.textMainTitle : AppColors.textSubtitle, size: 26), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.textMainTitle : AppColors.textSubtitle))]),
    );
  }
}