import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _currentCarbs = 75;
  final int _targetCarbs = 150;
  int _currentCalories = 900;
  final int _targetCalories = 1800;
  bool _showFoodsToEat = true;

  void _showEditMacroDialog(String title, int currentValue, Function(int) onSave) {
    final TextEditingController controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit $title', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'Enter amount', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSubtitle))),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSave(int.parse(controller.text));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // تم استبدال الـ Scaffold بـ Container
    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Your Nutrition Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              const SizedBox(height: 16),
              const Text('Here is your AI-powered plan for today, based\non your recent glucose levels and activity.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSubtitle, height: 1.5)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildMacroCard(title: 'Total Carbs', current: _currentCarbs, target: _targetCarbs, unit: 'g', onEdit: () => _showEditMacroDialog('Carbs', _currentCarbs, (val) => setState(() => _currentCarbs = val)))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMacroCard(title: 'Calories', current: _currentCalories, target: _targetCalories, unit: '', onEdit: () => _showEditMacroDialog('Calories', _currentCalories, (val) => setState(() => _currentCalories = val)))),
                ],
              ),
              const SizedBox(height: 32),
              _buildMealCard(icon: Icons.local_cafe_outlined, title: 'Breakfast', description: 'Oatmeal with Berries,\nGreek Yogurt'),
              const SizedBox(height: 16),
              _buildMealCard(icon: Icons.lunch_dining_outlined, title: 'Lunch', description: 'Grilled Chicken Salad,\nQuinoa'),
              const SizedBox(height: 16),
              _buildMealCard(icon: Icons.dinner_dining_outlined, title: 'Dinner', description: 'Baked Salmon,\nSteamed Broccoli'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildTabButton('Foods to Eat', true)),
                  Expanded(child: _buildTabButton('Foods to Avoid', false)),
                ],
              ),
              const Divider(height: 1, color: AppColors.borderDashed),
              const SizedBox(height: 24),
              _showFoodsToEat ? _buildFoodsToEatList() : _buildFoodsToAvoidList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard({required String title, required int current, required int target, required String unit, required VoidCallback onEdit}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onEdit, behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$current$unit', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                const SizedBox(width: 4),
                Text('/ $target$unit', style: const TextStyle(fontSize: 14, color: AppColors.borderDashed, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppColors.iconBgLight, shape: BoxShape.circle), child: Icon(icon, color: AppColors.primaryBlue, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)), const SizedBox(height: 4), Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textSubtitle, height: 1.5))])),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isEatTab) {
    final bool isActive = _showFoodsToEat == isEatTab;
    return GestureDetector(
      onTap: () => setState(() => _showFoodsToEat = isEatTab),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFF1F2937) : AppColors.textSubtitle)),
          const SizedBox(height: 12),
          Container(height: 3, color: isActive ? const Color(0xFF1F2937) : Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildFoodsToEatList() {
    final foods = ['Leafy Greens', 'Whole Grains', 'Lean Protein', 'Berries', 'Avocado'];
    return Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.start, children: foods.map((food) => _buildChip(food, Icons.thumb_up_outlined, true)).toList());
  }

  Widget _buildFoodsToAvoidList() {
    final foods = ['White Bread', 'Sugary Drinks', 'Processed Meats', 'Pastries'];
    return Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.start, children: foods.map((food) => _buildChip(food, Icons.thumb_down_outlined, false)).toList());
  }

  Widget _buildChip(String text, IconData icon, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isGood ? AppColors.iconBgLight : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isGood ? AppColors.primaryBlue : const Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isGood ? AppColors.primaryBlue : const Color(0xFFDC2626))),
        ],
      ),
    );
  }
}