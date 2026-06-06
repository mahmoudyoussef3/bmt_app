import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/app_surface.dart';

/// Mock country / dial code selector (UI placeholder).
class MockCountryOption {
  const MockCountryOption({
    required this.flag,
    required this.name,
    required this.dialCode,
  });

  final String flag;
  final String name;
  final String dialCode;
}

const List<MockCountryOption> kMockCountries = [
  MockCountryOption(flag: '🇪🇬', name: 'Egypt', dialCode: '+20'),
  MockCountryOption(
    flag: '🇦🇪',
    name: 'United Arab Emirates',
    dialCode: '+971',
  ),
  MockCountryOption(flag: '🇸🇦', name: 'Saudi Arabia', dialCode: '+966'),
  MockCountryOption(flag: '🇰🇼', name: 'Kuwait', dialCode: '+965'),
];

class MockCountryPickerTile extends StatelessWidget {
  const MockCountryPickerTile({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final MockCountryOption selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withAlpha(140)),
          ),
          child: Row(
            children: [
              Text(selected.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                selected.dialCode,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurface.withAlpha(180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<MockCountryOption?> showMockCountryPicker(
  BuildContext context,
  MockCountryOption current,
) {
  return showModalBottomSheet<MockCountryOption>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select country',
                style: Theme.of(ctx).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              ...kMockCountries.map((country) {
                final selected = country.dialCode == current.dialCode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    radius: 14,
                    onTap: () => Navigator.pop(ctx, country),
                    border: selected
                        ? Border.all(
                            color: Theme.of(ctx).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            country.name,
                            style: Theme.of(ctx).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          country.dialCode,
                          style: Theme.of(ctx).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
