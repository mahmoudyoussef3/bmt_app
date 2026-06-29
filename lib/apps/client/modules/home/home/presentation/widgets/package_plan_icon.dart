import 'package:flutter/material.dart';

IconData iconForPackagePlan(String iconKey) {
  return switch (iconKey) {
    'dateRange' => Icons.date_range_rounded,
    'calendarWeek' => Icons.calendar_view_week_rounded,
    'calendarMonth' => Icons.calendar_month_rounded,
    _ => Icons.card_membership_rounded,
  };
}
