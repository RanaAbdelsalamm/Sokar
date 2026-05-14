import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import 'plan_screen.dart'; 
import 'reminders_screen.dart'; 
import 'profile_screen.dart';
import '../services/database_service.dart';
import '../services/dashboard_controller.dart';
import '../services/chatbot_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 01. State Variables
  int _selectedIndex = 0;
  int _selectedTab = 0; 
  bool _isFabMenuOpen = false;
  bool _isLoading = true;

  final GlobalKey<RemindersScreenState> remindersKey = GlobalKey<RemindersScreenState>();
  final DashboardController _controller = DashboardController();
  final ChatBotService _chatbotService = ChatBotService();

  double? _latestReading;
  DateTime? _lastReadingTime;
  String _readingStatus = 'No Data';
  Color _readingStatusColor = AppColors.textSubtitle; 
  
  double _averageGlucose = 0.0;
  double _timeInRange = 0.0;
  double? _hba1cValue;
  bool _isHbA1cPredicted = false;
  List<QueryDocumentSnapshot> _chartReadings = [];

  final TextEditingController _glucoseController = TextEditingController();
  String _selectedMealTime = 'Fasting';

  // 02. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    await _controller.initAI();
    await _fetchDashboardData();
  }

  // 03. Fetch Data from Controller
  Future<void> _fetchDashboardData() async {
    int days = _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 7 : 30);
    final data = await _controller.getDashboardState(days);

    if (mounted) {
      setState(() {
        _latestReading = data['latestGlucose'];
        _lastReadingTime = data['latestGlucoseTime'];
        _hba1cValue = data['latestHbA1c'];
        _isHbA1cPredicted = data['isPredicted'];
        _averageGlucose = data['glucoseAvg'];
        _timeInRange = data['timeInRange'];
        _chartReadings = data['chartData'];
        _isLoading = false;

        if (_latestReading != null) {
          _updateReadingStatus(_latestReading!.toInt(), 'Fasting'); 
        }
      });
    }
  }

  void _updateReadingStatus(int reading, String mealTime) {
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
    _readingStatus = newStatus;
    _readingStatusColor = newColor;
  }

  // 04. UI Helpers
  String _getTimeString(DateTime? time) {
    if (time == null) return 'No readings yet';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  bool _isReadingOld(DateTime? time) {
    if (time == null) return false;
    return DateTime.now().difference(time).inHours >= 12;
  }

  // 05. Share Report Logic
  void _shareReport() {
    final String reportText = '''
📊|Glucose Dashboard Report:
---------------------------------
Latest Reading: ${_latestReading != null ? _latestReading!.toStringAsFixed(0) : '--'} mg/dL ($_readingStatus)
Average Glucose: ${_averageGlucose.toStringAsFixed(0)} mg/dL
Time in Range: ${_timeInRange.toStringAsFixed(0)}%
HbA1c: ${_hba1cValue != null ? '$_hba1cValue%' : '--'} ${_isHbA1cPredicted ? '(AI Predicted)' : ''}
---------------------------------
(Tracked via Sokar APP)
''';
    SharePlus.instance.share(ShareParams(text: reportText, subject: 'My Glucose Report'));
  }

  // 06. ML Risk Assessment Trigger
  Future<void> _triggerRiskAssessment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    double? risk = await _controller.calculateDiabetesRisk();
    if (!mounted) return;
    Navigator.pop(context); 

    if (risk != null) {
      String riskLevel = risk > 0.6 ? 'High Risk' : (risk > 0.3 ? 'Moderate Risk' : 'Low Risk');
      Color riskColor = risk > 0.6 ? Colors.red : (risk > 0.3 ? Colors.orange : AppColors.textSuccessGreen);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Diabetes Risk AI', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(risk * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: riskColor)),
              const SizedBox(height: 8),
              Text(riskLevel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: riskColor)),
              const SizedBox(height: 16),
              Text(
                risk > 0.9 ? 'Immediate medical attention is advised based on your clinical records.' 
                           : 'This is an AI estimation based on your profile and recent glucose levels.', 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontSize: 12, color: AppColors.textSubtitle)
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  // 07. Chatbot Sheet UI
  void _showChatbotSheet() {
    List<Map<String, String>> messages = [];
    TextEditingController chatController = TextEditingController();
    bool isBotTyping = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setChatState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sokar Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textSubtitle)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: messages.isEmpty 
                      ? const Center(child: Text("Say hi to Sokar! It knows your latest readings.", style: TextStyle(color: AppColors.textSubtitle)))
                      : ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            bool isUser = messages[index]['sender'] == 'user';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.primaryBlue : const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(16)
                                ),
                                child: Text(
                                  messages[index]['text']!,
                                  style: TextStyle(color: isUser ? Colors.white : AppColors.textMainTitle),
                                ),
                              ),
                            );
                          }
                        )
                  ),
                  if (isBotTyping)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Sokar is typing...", style: TextStyle(color: AppColors.textSubtitle, fontStyle: FontStyle.italic)),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: TextField(
                      controller: chatController,
                      decoration: InputDecoration(
                        hintText: 'Ask Sokar a medical question...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                          onPressed: () async {
                            if (chatController.text.trim().isEmpty) return;
                            
                            String userMsg = chatController.text.trim();
                            setChatState(() {
                              messages.add({'sender': 'user', 'text': userMsg});
                              isBotTyping = true;
                            });
                            chatController.clear();

                            String botResponse = await _chatbotService.sendMessage(userMsg);
                            
                            setChatState(() {
                              messages.add({'sender': 'bot', 'text': botResponse});
                              isBotTyping = false;
                            });
                          },
                        )
                      )
                    ),
                  )
                ],
              )
            );
          }
        );
      }
    );
  }

  // 08. Manual Entry Bottom Sheet
  void _showAddReadingSheet() {
    _glucoseController.clear(); 
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Log Glucose Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textSubtitle)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
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
                    const SizedBox(height: 32), 
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_glucoseController.text.isNotEmpty) {
                            final navigator = Navigator.of(context);
                            
                            String testType = 'BloodGlucose';
                            if (_selectedMealTime == 'Fasting') testType = 'Fasting Blood Sugar';
                            
                            await DatabaseService().saveManualReading(testType: testType, result: double.parse(_glucoseController.text));
                            
                            navigator.pop(); 
                            _fetchDashboardData(); 
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
                        child: const Text('Save Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
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

  // 09. Main Build Structure
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: AppColors.backgroundLight,
          appBar: _selectedIndex == 0 ? AppBar(
            backgroundColor: AppColors.backgroundLight, elevation: 0, centerTitle: true, 
            title: const Text('Glucose Dashboard', style: TextStyle(color: AppColors.textMainTitle, fontSize: 20, fontWeight: FontWeight.bold)), 
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share, color: AppColors.textMainTitle),
                onPressed: _shareReport,
              ),
              const SizedBox(width: 8),
            ],
          ) : null,
          
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildDashboardView(), 
                  const PlanScreen(),    
                  RemindersScreen(key: remindersKey), 
                  const ProfileScreen(),
                ],
              ),
          bottomNavigationBar: _buildFloatingBottomNav(),
        ),

        // 10. Custom Overlay for Glow FAB and Menu
        if (_isFabMenuOpen && _selectedIndex == 0)
          GestureDetector(
            onTap: () => setState(() => _isFabMenuOpen = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
        if (_selectedIndex == 0 || _selectedIndex == 2)
          Positioned(
            bottom: 100, 
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isFabMenuOpen && _selectedIndex == 0) ...[
                  _buildFabMenuItem(title: 'Sokar Chatbot', icon: Icons.chat_bubble_outline, onTap: () {
                    setState(() => _isFabMenuOpen = false);
                    _showChatbotSheet();
                  }),
                  const SizedBox(height: 16),
                  _buildFabMenuItem(title: 'Diabetes Risk AI', icon: Icons.analytics_outlined, onTap: () {
                    setState(() => _isFabMenuOpen = false);
                    _triggerRiskAssessment();
                  }),
                  const SizedBox(height: 16),
                  _buildFabMenuItem(title: 'Log Reading', icon: Icons.water_drop_outlined, onTap: () {
                    setState(() => _isFabMenuOpen = false);
                    _showAddReadingSheet();
                  }),
                  const SizedBox(height: 16),
                ],
                GestureDetector(
                  onTap: () {
                    if (_selectedIndex == 0) {
                      setState(() => _isFabMenuOpen = !_isFabMenuOpen);
                    } else {
                      remindersKey.currentState?.showAddReminderSheet(context);
                    }
                  },
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 5)
                      ]
                    ),
                    child: Icon(_isFabMenuOpen ? Icons.close : Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFabMenuItem({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }

  // 11. Dashboard View Data Mapping
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
          Row(
            children: [
              Expanded(child: _buildSmallStatCard('Average Glucose', _latestReading == null ? '--' : _averageGlucose.toStringAsFixed(0), 'mg/dL')), 
              const SizedBox(width: 16), 
              Expanded(child: _buildSmallStatCard('Time in Range', _latestReading == null ? '--' : _timeInRange.toStringAsFixed(0), '%'))
            ]
          ),
          const SizedBox(height: 16),
          _buildHbA1cCard(),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  Widget _buildLatestReadingCard() {
    bool isRedAlert = _isReadingOld(_lastReadingTime);
    String timeText = _getTimeString(_lastReadingTime);

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Reading: $timeText', 
            style: TextStyle(color: isRedAlert ? Colors.red : AppColors.textSubtitle, fontSize: 13, fontWeight: isRedAlert ? FontWeight.bold : FontWeight.normal)
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, 
            children: [
              Text(_latestReading != null ? _latestReading!.toStringAsFixed(0) : '--', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)), 
              const SizedBox(width: 8), 
              const Text('mg/dL', style: TextStyle(fontSize: 18, color: AppColors.textSubtitle, fontWeight: FontWeight.w500))
            ]
          ),
          const SizedBox(height: 8),
          if (_latestReading != null)
            Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _readingStatusColor, shape: BoxShape.circle)), const SizedBox(width: 8), Text(_readingStatus, style: TextStyle(color: _readingStatusColor, fontWeight: FontWeight.bold, fontSize: 14))]),
        ],
      ),
    );
  }

  Widget _buildTimeTabs() {
    return Container(
      height: 44, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.bgTabInactive, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          _buildTabItem('24h', 0), 
          _buildTabItem('7D', 1), 
          _buildTabItem('30D', 2)
        ]
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          _fetchDashboardData(); 
        },
        child: Container(
          decoration: BoxDecoration(color: isActive ? AppColors.bgTabActive : Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []),
          alignment: Alignment.center, child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.textMainTitle : AppColors.textSubtitle)),
        ),
      ),
    );
  }

  // 12. Apple Watch Style Bar Chart Implementation
  Widget _buildChartCard() {
    int maxX = _selectedTab == 0 ? 24 : (_selectedTab == 1 ? 6 : 4);
    Map<int, List<double>> groupedData = {};

    if (_chartReadings.isNotEmpty) {
      for (var doc in _chartReadings) {
        var data = doc.data() as Map<String, dynamic>;
        double result = data['result'].toDouble();
        DateTime time = (data['timestamp'] as Timestamp).toDate();
        
        int xValue = 0;
        if (_selectedTab == 0) {
          xValue = time.hour; 
        } else if (_selectedTab == 1) {
          xValue = time.weekday - 1; 
        } else {
          xValue = (time.day / 7).floor(); 
        }
        
        if (xValue > maxX) xValue = maxX;

        if (!groupedData.containsKey(xValue)) {
          groupedData[xValue] = [];
        }
        groupedData[xValue]!.add(result);
      }
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i <= maxX; i++) {
      double avgResult = 0;
      if (groupedData.containsKey(i) && groupedData[i]!.isNotEmpty) {
        avgResult = groupedData[i]!.reduce((a, b) => a + b) / groupedData[i]!.length;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avgResult > 0 ? avgResult : 0, 
              color: avgResult > 0 ? AppColors.primaryBlue : Colors.transparent, 
              width: 8, 
              borderRadius: BorderRadius.circular(4), 
              backDrawRodData: BackgroundBarChartRodData(
                show: true, 
                toY: 300, 
                color: const Color(0xFFF2F4F7)
              )
            )
          ]
        )
      );
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Glucose Levels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: _chartReadings.isEmpty 
              ? const Center(child: Text('Log your first reading to see charts.', style: TextStyle(color: AppColors.textSubtitle)))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 300,
                    minY: 0,
                    barGroups: barGroups,
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false, horizontalInterval: 50, 
                      getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.borderDashed, strokeWidth: 1)
                    ),
                    titlesData: FlTitlesData(
                      show: true, 
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 30, interval: 1, 
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(color: AppColors.textMainTitle, fontSize: 10);
                            String text = '';
                            if (_selectedTab == 0) {
                              if (value == 0) { text = '12am'; }
                              else if (value == 6) { text = '6am'; }
                              else if (value == 12) { text = '12pm'; }
                              else if (value == 18) { text = '6pm'; }
                              else if (value == 24) { text = '12am'; }
                            } else if (_selectedTab == 1) {
                              switch (value.toInt()) {
                                case 0: text = 'Mon'; break;
                                case 1: text = 'Tue'; break;
                                case 2: text = 'Wed'; break;
                                case 3: text = 'Thu'; break;
                                case 4: text = 'Fri'; break;
                                case 5: text = 'Sat'; break;
                                case 6: text = 'Sun'; break;
                              }
                            } else {
                              switch (value.toInt()) {
                                case 0: text = 'W1'; break;
                                case 1: text = 'W2'; break;
                                case 2: text = 'W3'; break;
                                case 3: text = 'W4'; break;
                                case 4: text = 'W1'; break;
                              }
                            }
                            if (text.isEmpty) return const SizedBox.shrink();
                            return SideTitleWidget(meta: meta, space: 10, child: Text(text, style: style));
                          }
                        )
                      )
                    ),
                    borderData: FlBorderData(show: false), 
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13)), 
          const SizedBox(height: 8), 
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, 
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)), 
              if (unit.isNotEmpty) ...[const SizedBox(width: 4), Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.textSubtitle))]
            ]
          )
        ]
      )
    );
  }

  Widget _buildHbA1cCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HbA1c', style: TextStyle(color: AppColors.textSubtitle, fontSize: 13)),
              if (_isHbA1cPredicted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.bgBlueCard, borderRadius: BorderRadius.circular(8)),
                  child: const Text('AI Predicted', style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const SizedBox(height: 8), 
          Text(
            _hba1cValue != null ? '$_hba1cValue%' : '--', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)
          ),
          const SizedBox(height: 8),
          Text(
            _hba1cValue == null 
              ? 'Need more readings to estimate.'
              : (_isHbA1cPredicted ? 'Estimated based on recent glucose.' : 'Lab tested result.'),
            style: const TextStyle(fontSize: 11, color: AppColors.textSubtitle)
          )
        ]
      )
    );
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
      onTap: () {
        setState(() => _isFabMenuOpen = false); 
        _onItemTapped(index);
      }, 
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isSelected ? AppColors.textMainTitle : AppColors.textSubtitle, size: 26), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.textMainTitle : AppColors.textSubtitle))]),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}