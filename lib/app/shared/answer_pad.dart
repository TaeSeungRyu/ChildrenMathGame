import 'package:flutter/material.dart';

/// "정답 입력" 박스 — 사용자가 입력한 숫자를 큰 글씨로 표시한다.
/// [value]가 비어 있으면 placeholder "정답 입력"을 보여준다.
///
/// 기존 game_view / review_view의 내부 _AnswerDisplay와 동일한 룩 앤 필을
/// 외부에서 재사용 가능한 형태로 추출한 위젯이다. 신규 게임 모드(액션 등)에서
/// 동일 UI를 일관되게 사용하기 위함.
class AnswerDisplay extends StatelessWidget {
  const AnswerDisplay({
    super.key,
    required this.value,
    this.height = 62,
  });

  final String value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: value.isEmpty
          ? Text(
              '정답 입력',
              style: TextStyle(fontSize: 24, color: theme.hintColor),
            )
          : Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

/// 3×4 숫자 키패드(1~9, 지우기/0/입력). 콜백 기반이라 어떤 컨트롤러와도
/// 결합되며, 기존 GameController와 동일한 사용감(라벨·색·크기)을 따른다.
class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    super.key,
    required this.onAppendDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  final ValueChanged<String> onAppendDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([_digit('1'), _digit('2'), _digit('3')]),
        const SizedBox(height: 4),
        _row([_digit('4'), _digit('5'), _digit('6')]),
        const SizedBox(height: 4),
        _row([_digit('7'), _digit('8'), _digit('9')]),
        const SizedBox(height: 4),
        _row(
          [
            _action(
              label: '지우기',
              onPressed: onDelete,
              color: Colors.orange.shade400,
            ),
            _digit('0'),
            _action(
              label: '입력',
              onPressed: onSubmit,
              color: Colors.green.shade500,
            ),
          ],
          flexes: const [1, 1, 2],
          height: 72,
        ),
      ],
    );
  }

  Widget _row(
    List<Widget> children, {
    List<int>? flexes,
    double height = 54,
  }) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(width: 4));
      items.add(Expanded(flex: flexes?[i] ?? 1, child: children[i]));
    }
    return SizedBox(height: height, child: Row(children: items));
  }

  Widget _digit(String d) {
    return _KeypadButton(label: d, onPressed: () => onAppendDigit(d));
  }

  Widget _action({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return _KeypadButton(
      label: label,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      fontSize: 22,
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 28,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}
