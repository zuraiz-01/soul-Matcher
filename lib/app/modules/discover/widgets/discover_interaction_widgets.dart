import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DiscoverSafetyAction { report, block }

class DiscoverActionButtons extends StatelessWidget {
  const DiscoverActionButtons({
    super.key,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    this.enabled = true,
  });

  final Future<void> Function()? onPass;
  final Future<void> Function()? onSuperLike;
  final Future<void> Function()? onLike;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _ActionButton(
          icon: Icons.close_rounded,
          color: const Color(0xFF8E8E93),
          onTap: enabled ? onPass : null,
        ),
        _ActionButton(
          icon: Icons.star_rounded,
          color: const Color(0xFF5A7DFF),
          onTap: enabled ? onSuperLike : null,
        ),
        _ActionButton(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE55B79),
          onTap: enabled ? onLike : null,
        ),
      ],
    );
  }
}

Future<DiscoverSafetyAction?> showDiscoverSafetyActionSheet(
  BuildContext context,
) {
  return showModalBottomSheet<DiscoverSafetyAction>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext modalContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: _SheetCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _BottomSheetHandle(),
              Text(
                'Safety actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Take action on this profile.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _SheetActionTile(
                icon: Icons.flag_outlined,
                iconColor: const Color(0xFFF6A23A),
                title: 'Report user',
                subtitle: 'Tell us why this profile looks suspicious',
                onTap: () =>
                    Navigator.of(modalContext).pop(DiscoverSafetyAction.report),
              ),
              const SizedBox(height: 8),
              _SheetActionTile(
                icon: Icons.block_outlined,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Block user',
                subtitle: 'They will no longer appear in Discover',
                onTap: () =>
                    Navigator.of(modalContext).pop(DiscoverSafetyAction.block),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showDiscoverReportBottomSheet({
  required BuildContext context,
  required Future<void> Function(String reason) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportBottomSheet(onSubmit: onSubmit),
  );
}

class _ReportBottomSheet extends StatefulWidget {
  const _ReportBottomSheet({required this.onSubmit});

  final Future<void> Function(String reason) onSubmit;

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  static const List<String> _quickReasons = <String>[
    'Fake profile',
    'Spam behavior',
    'Inappropriate content',
    'Harassment',
    'Scam attempt',
  ];

  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('Validation', 'Please add a reason before submitting.');
      return;
    }
    Navigator.of(context).pop();
    await widget.onSubmit(reason);
  }

  void _onReasonSelected(bool selected, String reason) {
    setState(() {
      _selectedReason = selected ? reason : null;
      if (selected && _reasonController.text.trim().isEmpty) {
        _reasonController.text = reason;
        _reasonController.selection = TextSelection.fromPosition(
          TextPosition(offset: _reasonController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: _SheetCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _BottomSheetHandle(),
              Text(
                'Report user',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'This report is anonymous. Help us understand what happened.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReasons
                    .map((String reason) {
                      final bool isSelected = _selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (bool selected) =>
                            _onReasonSelected(selected, reason),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 180,
                decoration: const InputDecoration(
                  hintText: 'Write a short reason...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white30,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: child,
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(),
      borderRadius: BorderRadius.circular(27),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
