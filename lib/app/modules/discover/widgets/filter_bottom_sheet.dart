import 'package:flutter/material.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final DiscoverFilter initialFilter;
  final ValueChanged<DiscoverFilter> onApply;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues ageRange;
  String? interestedIn;

  @override
  void initState() {
    super.initState();
    ageRange = RangeValues(
      widget.initialFilter.minAge.toDouble(),
      widget.initialFilter.maxAge.toDouble(),
    );
    interestedIn = widget.initialFilter.interestedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            'Age range: ${ageRange.start.round()} - ${ageRange.end.round()}',
          ),
          RangeSlider(
            values: ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            onChanged: (RangeValues values) {
              setState(() => ageRange = values);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: interestedIn,
            hint: const Text('Interested in (optional)'),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(value: null, child: Text('Any')),
              ...AppConstants.genderOptions.map(
                (String e) =>
                    DropdownMenuItem<String?>(value: e, child: Text(e)),
              ),
            ],
            onChanged: (String? value) {
              setState(() => interestedIn = value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(
                  widget.initialFilter.copyWith(
                    minAge: ageRange.start.round(),
                    maxAge: ageRange.end.round(),
                    interestedIn: interestedIn,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
