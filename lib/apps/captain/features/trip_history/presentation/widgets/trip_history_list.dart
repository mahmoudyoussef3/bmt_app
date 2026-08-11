import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/trip_history_item.dart';
import '../utils/trip_history_filters.dart';
import 'trip_history_animated_entry.dart';
import 'trip_history_card.dart';

class TripHistoryList extends StatelessWidget {
  const TripHistoryList({super.key, required this.groups});

  final List<TripHistoryGroup> groups;

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(groups);

    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _LabelRow(:final label) => _GroupLabel(label: label),
        _TripRow(:final trip, :final indexInGroup) => Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: CaptainDesignTokens.s16,
          ),
          child: TripHistoryAnimatedEntry(
            index: indexInGroup,
            child: TripHistoryCard(trip: trip),
          ),
        ),
      },
    );
  }

  static List<_Row> _flatten(List<TripHistoryGroup> groups) {
    return [
      for (final group in groups) ...[
        _LabelRow(group.label),
        for (var i = 0; i < group.trips.length; i++)
          _TripRow(group.trips[i], i),
      ],
    ];
  }
}

sealed class _Row {
  const _Row();
}

class _LabelRow extends _Row {
  const _LabelRow(this.label);
  final String label;
}

class _TripRow extends _Row {
  const _TripRow(this.trip, this.indexInGroup);
  final TripHistoryItem trip;

  final int indexInGroup;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: CaptainDesignTokens.s8,
        bottom: CaptainDesignTokens.s8,
      ),
      child: Text(
        label,
        style: CaptainTypography.titleSmall(
          context,
        ).copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}
