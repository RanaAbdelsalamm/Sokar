import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/nutrition_service.dart';
import '../services/database_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final NutritionService _nutritionService = NutritionService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = true;
  bool _showFoodsToEat = true;

  Map<String, dynamic> _plan = {};

  double _consumedCarbs = 0.0;
  double _consumedCalories = 0.0;
  double _targetCarbs = 150.0;
  double _targetCalories = 1800.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final planFuture = _nutritionService.generateDailyPlan();
      final consumedFuture = _databaseService.getDailyNutrition();

      final plan = await planFuture;
      final consumed = await consumedFuture;

      setState(() {
        _plan = plan;
        _targetCarbs = (plan['target_carbs'] as num?)?.toDouble() ?? 150.0;
        _targetCalories = (plan['target_calories'] as num?)?.toDouble() ?? 1800.0;
        _consumedCarbs = consumed['carbs'] ?? 0.0;
        _consumedCalories = consumed['calories'] ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PlanScreen _loadData error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshConsumed() async {
    try {
      final consumed = await _databaseService.getDailyNutrition();
      setState(() {
        _consumedCarbs = consumed['carbs'] ?? 0.0;
        _consumedCalories = consumed['calories'] ?? 0.0;
      });
    } catch (e) {
      debugPrint('PlanScreen _refreshConsumed error: $e');
    }
  }

  void _showEditDialog({
    required String title,
    required double currentValue,
    required bool isCarbs,
  }) {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F0F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit $title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMainTitle,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSubtitle),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final value = double.tryParse(text);
                if (value == null) return;

                Navigator.pop(ctx);

                final newCarbs = isCarbs ? value : _consumedCarbs;
                final newCalories = isCarbs ? _consumedCalories : value;

                await _databaseService.saveDailyNutrition(
                  newCarbs,
                  newCalories,
                );
                await _refreshConsumed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.backgroundLight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Your Nutrition Plan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainTitle,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Here is your AI-powered plan for today, based\non your recent glucose levels and activity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSubtitle,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildMacroCard(
                      title: 'Total Carbs',
                      current: _consumedCarbs,
                      target: _targetCarbs,
                      unit: 'g',
                      onEdit: () => _showEditDialog(
                        title: 'Carbs',
                        currentValue: _consumedCarbs,
                        isCarbs: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMacroCard(
                      title: 'Calories',
                      current: _consumedCalories,
                      target: _targetCalories,
                      unit: '',
                      onEdit: () => _showEditDialog(
                        title: 'Calories',
                        currentValue: _consumedCalories,
                        isCarbs: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ExpandableMealCard(
                icon: Icons.local_cafe_outlined,
                title: 'Breakfast',
                mealData: _plan['breakfast'],
              ),
              const SizedBox(height: 16),
              ExpandableMealCard(
                icon: Icons.lunch_dining_outlined,
                title: 'Lunch',
                mealData: _plan['lunch'],
              ),
              const SizedBox(height: 16),
              ExpandableMealCard(
                icon: Icons.dinner_dining_outlined,
                title: 'Dinner',
                mealData: _plan['dinner'],
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildTabButton('Foods to Eat', true)),
                  Expanded(child: _buildTabButton('Foods to Avoid', false)),
                ],
              ),
              const Divider(height: 1, color: AppColors.borderDashed),
              const SizedBox(height: 24),

              _showFoodsToEat
                  ? _buildFoodChips(
                      _plan['foods_to_eat'],
                      Icons.thumb_up_outlined,
                      true,
                    )
                  : _buildFoodChips(
                      _plan['foods_to_avoid'],
                      Icons.thumb_down_outlined,
                      false,
                    ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required String title,
    required double current,
    required double target,
    required String unit,
    required VoidCallback onEdit,
  }) {
    final currentStr = '${current.toStringAsFixed(0)}$unit';
    final targetStr = '/ ${target.toStringAsFixed(0)}$unit';

    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSubtitle,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currentStr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMainTitle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  targetStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.borderDashed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isEatTab) {
    final bool isActive = _showFoodsToEat == isEatTab;
    return GestureDetector(
      onTap: () => setState(() => _showFoodsToEat = isEatTab),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF1F2937)
                  : AppColors.textSubtitle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            color: isActive ? const Color(0xFF1F2937) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodChips(
    dynamic foodsList,
    IconData icon,
    bool isGood,
  ) {
    final List<String> foods = [];
    if (foodsList is List) {
      for (final item in foodsList) {
        foods.add(item.toString());
      }
    }

    if (foods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          isGood ? 'No recommendations available.' : 'No restrictions listed.',
          style: const TextStyle(color: AppColors.textSubtitle, fontSize: 14),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: foods
            .map((food) => _buildChip(food, icon, isGood))
            .toList(),
      ),
    );
  }

  Widget _buildChip(String text, IconData icon, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isGood ? AppColors.iconBgLight : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isGood ? AppColors.primaryBlue : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isGood ? AppColors.primaryBlue : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableMealCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final dynamic mealData; 

  const ExpandableMealCard({
    super.key,
    required this.icon,
    required this.title,
    required this.mealData,
  });

  @override
  State<ExpandableMealCard> createState() => _ExpandableMealCardState();
}

class _ExpandableMealCardState extends State<ExpandableMealCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    String description = 'No data available';
    String? calories;
    String? carbs;

    // Check if the new structured data is coming from the API
    if (widget.mealData is Map) {
      final map = widget.mealData as Map<String, dynamic>;
      description = map['description']?.toString() ?? description;
      calories = map['calories']?.toString();
      carbs = map['carbs']?.toString();
    } 
    // Fallback for old data format
    else if (widget.mealData is String) {
      description = widget.mealData as String;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isExpanded ? 0.08 : 0.03),
              blurRadius: _isExpanded ? 20 : 10,
              offset: Offset(0, _isExpanded ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.iconBgLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMainTitle,
                        ),
                      ),
                      // Here is the new sleek subtitle that appears if we have data
                      if (calories != null && carbs != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '(${carbs}g Carbs - $calories Calories)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSubtitle, // لون رمادي شيك وناعم
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textSubtitle,
                ),
              ],
            ),
            
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.borderDashed, height: 1),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSubtitle,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}