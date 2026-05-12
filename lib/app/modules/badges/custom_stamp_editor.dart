import 'package:flutter/material.dart';

import '../../data/models/custom_stamp.dart';
import '../../data/models/game_type.dart';
import '../../data/models/stamp_condition.dart';

/// Result returned by the editor sheet — caller decides whether to insert
/// (new) or update (existing) based on context.
class CustomStampDraft {
  const CustomStampDraft({
    required this.title,
    required this.emoji,
    required this.colorValue,
    this.condition,
  });

  final String title;
  final String emoji;
  final int colorValue;
  // Null = manual stamp (user toggles); non-null = auto stamp (derived).
  final StampCondition? condition;
}

const _emojiChoices = ['⭐', '🌟', '✨', '🎉', '🏆', '🌈', '🦄', '💯'];

const _colorChoices = <int>[
  0xFFE53935, // red
  0xFFFB8C00, // orange
  0xFFFBC02D, // yellow
  0xFF43A047, // green
  0xFF1E88E5, // blue
  0xFF8E24AA, // purple
];

// Operations available as an auto-condition. Excludes `mixed` — a condition
// of "혼합" would only match record-level mixed runs, which is confusing UX;
// for now require pure-type conditions.
const _conditionOps = <GameType>[
  GameType.addition,
  GameType.subtraction,
  GameType.multiplication,
  GameType.division,
];

const _conditionLevels = <int>[1, 2, 3, 4, 5];

// Time-limit quick picks (seconds). Null = no limit.
const _timeChoices = <int>[30, 60, 90, 120, 180];

class CustomStampEditor extends StatefulWidget {
  const CustomStampEditor({super.key, this.initial});

  /// Non-null when editing an existing stamp; fields are pre-filled.
  final CustomStamp? initial;

  @override
  State<CustomStampEditor> createState() => _CustomStampEditorState();
}

class _CustomStampEditorState extends State<CustomStampEditor> {
  late final TextEditingController _titleController;
  late String _emoji;
  late int _colorValue;

  // Condition state, broken out so the UI can toggle each piece independently
  // without juggling a nullable StampCondition object.
  late bool _autoEnabled;
  GameType? _condOperation;
  int? _condLevel;
  int _condCount = 1;
  bool _condPerfect = false;
  int? _condMaxSeconds;

  static const _maxTitleLength = 12;

  @override
  void initState() {
    super.initState();
    final c = widget.initial?.condition;
    _titleController = TextEditingController(
      text: widget.initial?.title ?? '',
    );
    _emoji = widget.initial?.emoji ?? _emojiChoices.first;
    _colorValue = widget.initial?.colorValue ?? _colorChoices.first;
    _autoEnabled = c != null;
    _condOperation = c?.operation;
    _condLevel = c?.level;
    _condCount = c?.targetCount ?? 1;
    _condPerfect = c?.requirePerfect ?? false;
    _condMaxSeconds = c?.maxSeconds;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  StampCondition? _buildCondition() {
    if (!_autoEnabled) return null;
    return StampCondition(
      operation: _condOperation,
      level: _condLevel,
      targetCount: _condCount,
      requirePerfect: _condPerfect,
      maxSeconds: _condMaxSeconds,
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      CustomStampDraft(
        title: title,
        emoji: _emoji,
        colorValue: _colorValue,
        condition: _buildCondition(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.9;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.initial == null ? '새 도장 만들기' : '도장 편집',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _PreviewIcon(emoji: _emoji, color: color),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  maxLength: _maxTitleLength,
                  textAlign: TextAlign.center,
                  autofocus: widget.initial == null,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '도장 이름 (예: 곱셈 마스터)',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('아이콘'),
                const SizedBox(height: 8),
                _EmojiPicker(
                  selected: _emoji,
                  onChanged: (e) => setState(() => _emoji = e),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('색깔'),
                const SizedBox(height: 8),
                _ColorPicker(
                  selected: _colorValue,
                  onChanged: (c) => setState(() => _colorValue = c),
                ),
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _autoEnabled,
                  onChanged: (v) => setState(() => _autoEnabled = v),
                  title: const Text(
                    '자동으로 도장 받기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    '조건에 맞는 게임을 끝내면 자동으로 받아져요',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                if (_autoEnabled) ...[
                  const SizedBox(height: 8),
                  const _SectionLabel('연산'),
                  const SizedBox(height: 6),
                  _ChipRow<GameType?>(
                    options: const [null, ..._conditionOps],
                    selected: _condOperation,
                    label: (v) => v == null ? '전체' : '${v.symbol} ${v.label}',
                    onChanged: (v) => setState(() => _condOperation = v),
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('레벨'),
                  const SizedBox(height: 6),
                  _ChipRow<int?>(
                    options: const [null, ..._conditionLevels],
                    selected: _condLevel,
                    label: (v) => v == null ? '전체' : '레벨 $v',
                    onChanged: (v) => setState(() => _condLevel = v),
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('목표 횟수'),
                  const SizedBox(height: 6),
                  _CountStepper(
                    value: _condCount,
                    onChanged: (v) => setState(() => _condCount = v),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _condPerfect,
                    onChanged: (v) =>
                        setState(() => _condPerfect = v ?? false),
                    title: const Text(
                      '만점만 인정',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const _SectionLabel('시간 제한 (선택)'),
                  const SizedBox(height: 6),
                  _ChipRow<int?>(
                    options: const [null, ..._timeChoices],
                    selected: _condMaxSeconds,
                    label: (v) => v == null ? '제한 없음' : '$v초 이내',
                    onChanged: (v) => setState(() => _condMaxSeconds = v),
                  ),
                  const SizedBox(height: 12),
                  _ConditionPreview(condition: _buildCondition()!),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _PreviewIcon extends StatelessWidget {
  const _PreviewIcon({required this.emoji, required this.color});

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _emojiChoices.map((e) {
        final isSelected = e == selected;
        return InkWell(
          onTap: () => onChanged(e),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(e, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorChoices.map((c) {
        final isSelected = c == selected;
        return InkWell(
          onTap: () => onChanged(c),
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(c),
              border: Border.all(
                color: isSelected ? Colors.black87 : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(c).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((o) {
        return ChoiceChip(
          label: Text(label(o)),
          selected: o == selected,
          onSelected: (_) => onChanged(o),
        );
      }).toList(),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _min = 1;
  static const _max = 99;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: value > _min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 60,
          child: Text(
            '$value회',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          onPressed: value < _max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
        const Spacer(),
        // Quick picks for common targets.
        for (final preset in const [1, 5, 10])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton(
              onPressed: () => onChanged(preset),
              style: TextButton.styleFrom(
                minimumSize: const Size(36, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text('$preset'),
            ),
          ),
      ],
    );
  }
}

class _ConditionPreview extends StatelessWidget {
  const _ConditionPreview({required this.condition});

  final StampCondition condition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              condition.describe(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
