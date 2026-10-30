import 'package:flutter/material.dart';
import 'package:gen_ui_demo/core/theme/app_theme.dart';
import 'package:genui/genui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// 1. The schema: tells the AI what data a RecipeSteps card needs
final _recipeStepsSchema = S.object(
  description: 'Step-by-step cooking instructions the user ticks off while cooking.',
  properties: {
    'dish': S.string(description: 'The dish, e.g. "Jollof rice".'),
    'emoji': S.string(description: 'One food emoji for the dish.'),
    'steps': S.list(
      items: S.object(
        properties: {
          'title': S.string(description: 'Short step title, e.g. "Fry the tomato stew".'),
          'detail': S.string(description: 'One or two sentences on how to do it.'),
          'minutes': S.integer(description: 'Roughly how long this step takes.'),
        },
        required: ['title', 'detail'],
      ),
    ),
    'tip': S.string(
      description: 'One secret tip from a Nigerian aunty, WITHOUT any label, e.g. "Let the bottom burn small for party flavour".',
    ),
  },
  required: ['dish', 'steps'],
);

// 2. The catalog item: connects the schema to a Flutter widget
final recipeSteps = CatalogItem(
  name: 'RecipeSteps',
  dataSchema: _recipeStepsSchema,
  widgetBuilder: (itemContext) {
    return RecipeStepsCard(data: RecipeStepsData.fromJson(itemContext.data as Map<String, Object?>));
  },
);

// 3. The data class: reads the AI's JSON
class RecipeStepsData {
  final String dish;
  final String emoji;
  final String? tip;
  final List<({String title, String detail, int? minutes})> steps;

  RecipeStepsData({required this.dish, required this.emoji, this.tip, required this.steps});

  factory RecipeStepsData.fromJson(Map<String, Object?> json) {
    return RecipeStepsData(
      dish: json['dish'] as String,
      emoji: json['emoji'] as String? ?? "🍲",
      tip: json['tip'] as String?,
      steps: [
        for (final step in (json['steps'] as List).cast<Map<String, Object?>>())
          (
            title: step['title'] as String,
            detail: step['detail'] as String,
            minutes: (step['minutes'] as num?)?.toInt(),
          ),
      ],
    );
  }

  int get totalMinutes => steps.fold(0, (sum, step) => sum + (step.minutes ?? 0));
}

// 4. The widget: what the user actually sees
class RecipeStepsCard extends StatefulWidget {
  final RecipeStepsData data;
  const RecipeStepsCard({super.key, required this.data});

  @override
  State<RecipeStepsCard> createState() => _RecipeStepsCardState();
}

class _RecipeStepsCardState extends State<RecipeStepsCard> {
  // Steps the user has finished
  final Set<int> doneSteps = {};

  bool get isAllDone => doneSteps.length == widget.data.steps.length;

  void _toggleStep(int index) {
    setState(() => doneSteps.contains(index) ? doneSteps.remove(index) : doneSteps.add(index));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            // Header and progress
            Row(
              spacing: 12,
              children: [
                Text(data.emoji, style: TextStyle(fontSize: 36)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Let's cook!", style: TextStyle(color: AppColors.muted)),
                      Text(data.dish, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (data.totalMinutes > 0)
                  Row(
                    spacing: 4,
                    children: [
                      Icon(Iconsax.timer_1, size: 16, color: AppColors.muted),
                      Text("${data.totalMinutes} min", style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: doneSteps.length / data.steps.length,
                minHeight: 8,
                color: AppColors.leaf,
                backgroundColor: AppColors.outline,
              ),
            ),

            // Steps: tap one when it's done
            for (int i = 0; i < data.steps.length; i++)
              _StepTile(number: i + 1, step: data.steps[i], isDone: doneSteps.contains(i), onTap: () => _toggleStep(i)),

            if (data.tip != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pepper.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text("👩🏾‍🍳 Aunty's tip: ${data.tip}", style: TextStyle(fontSize: 13)),
              ),

            // The finish line
            AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child: isAllDone ? _Celebration(dish: data.dish, emoji: data.emoji) : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final ({String title, String detail, int? minutes}) step;
  final bool isDone;
  final VoidCallback onTap;

  const _StepTile({required this.number, required this.step, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDone ? AppColors.leaf.withValues(alpha: 0.08) : AppColors.cream,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone ? AppColors.leaf : AppColors.jollof,
                child: isDone
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : Text("$number", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(step.detail, style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
              if (step.minutes != null) Text("${step.minutes}m", style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

// Shown when every step is done
class _Celebration extends StatelessWidget {
  final String dish;
  final String emoji;
  const _Celebration({required this.dish, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.jollof, AppColors.pepper]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text("🎉 $emoji 🎉", style: TextStyle(fontSize: 32)),
          Text(
            "Enjoy your $dish!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text("Tap “New dish” to cook something else.", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
