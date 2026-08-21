import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural guarantees for العملاء, checked the way `dashboard_rtl_test.dart`
/// checks the console's RTL rule: by reading the source.
///
/// These are not style assertions. Each one is a boundary whose violation is
/// invisible in a widget test and expensive in production — a cross-tenant read,
/// a layer inversion, a leaked payment field.
void main() {
  final featureDir = Directory('lib/apps/dashboard/features/customers');

  List<File> dartFiles(String subPath) =>
      Directory('${featureDir.path}/$subPath').existsSync()
      ? Directory('${featureDir.path}/$subPath')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
      : <File>[];

  /// Source with `//` comments stripped.
  ///
  /// These checks are about what the code *does*, and this module's comments
  /// deliberately name the things being excluded — the payment entity explains
  /// why `gateway_response` is absent, and the datasource explains that the
  /// office comes from `current_office_id()`. Matching prose would fail the
  /// module for documenting its own boundaries.
  String code(File file) => file
      .readAsStringSync()
      .split('\n')
      .map((line) {
        final comment = line.indexOf('//');
        return comment == -1 ? line : line.substring(0, comment);
      })
      .join('\n');

  List<File> allFiles() => featureDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  setUpAll(() {
    expect(
      featureDir.existsSync(),
      isTrue,
      reason: 'run from the repository root',
    );
  });

  group('office isolation', () {
    test('no customer query ever sends an office id', () {
      // Every RPC resolves the office from `current_office_id()` server-side.
      // A query that *accepts* an office id is a cross-tenant read waiting to
      // be found — see DASHBOARD_CONVENTIONS.md §5.
      for (final file in allFiles()) {
        final source = code(file);
        expect(
          source.contains('officeId'),
          isFalse,
          reason: '${file.path} references an office id',
        );
        expect(
          source.contains('office_id'),
          isFalse,
          reason: '${file.path} passes an office_id parameter',
        );
      }
    });

    test('the datasource holds no session to read an office from', () {
      final datasource = code(
        File(
          '${featureDir.path}/data/datasources/supabase_customers_datasource.dart',
        ),
      );

      expect(datasource.contains('DashboardSession'), isFalse);
    });

    test('every read goes through an RPC, never a table', () {
      // `clients` carries no office id, so a `.from('clients')` read would be
      // scoped only by RLS — correct today, and one policy edit from not being.
      final datasource = code(
        File(
          '${featureDir.path}/data/datasources/supabase_customers_datasource.dart',
        ),
      );

      expect(datasource.contains(".from("), isFalse);
      expect(datasource.contains("_client.rpc("), isTrue);
    });
  });

  group('sensitive payment fields', () {
    test('no processor payload is ever named in the module', () {
      // The RPC does not select these columns at all; this stops a future edit
      // from adding them to an entity and quietly putting them on screen.
      for (final file in allFiles()) {
        final source = code(file);
        for (final banned in const [
          'gateway_response',
          'gateway_transaction_id',
          'gateway_order_id',
          'card_number',
        ]) {
          expect(
            source.contains(banned),
            isFalse,
            reason: '${file.path} references $banned',
          );
        }
      }
    });
  });

  group('layer direction', () {
    test('presentation never imports data/', () {
      for (final file in dartFiles('presentation')) {
        expect(code(file).contains('/data/'), isFalse, reason: file.path);
      }
    });

    test('presentation never touches Supabase', () {
      for (final file in dartFiles('presentation')) {
        expect(
          code(file).contains('SupabaseClient'),
          isFalse,
          reason: file.path,
        );
      }
    });

    test('domain is pure Dart — no Flutter, no Supabase', () {
      for (final file in dartFiles('domain')) {
        final source = code(file);
        expect(
          source.contains('package:flutter/'),
          isFalse,
          reason: '${file.path} imports Flutter',
        );
        expect(
          source.contains('supabase'),
          isFalse,
          reason: '${file.path} imports Supabase',
        );
      }
    });

    test('data never imports presentation', () {
      for (final file in dartFiles('data')) {
        expect(code(file).contains('presentation'), isFalse, reason: file.path);
      }
    });
  });

  group('console conventions', () {
    test('no hardcoded colours in any widget', () {
      for (final file in dartFiles('presentation')) {
        expect(
          RegExp(r'Color\(0x').hasMatch(code(file)),
          isFalse,
          reason: '${file.path} hardcodes a colour',
        );
      }
    });

    test('no physical insets or alignments — the console is RTL', () {
      for (final file in dartFiles('presentation')) {
        final source = code(file);
        for (final banned in const [
          'EdgeInsets.only(left:',
          'EdgeInsets.only(right:',
          'Alignment.centerLeft',
          'Alignment.centerRight',
          'Positioned(left:',
          'Positioned(right:',
        ]) {
          expect(
            source.contains(banned),
            isFalse,
            reason: '${file.path} uses $banned instead of the directional form',
          );
        }
      }
    });

    test('nothing forces a text direction', () {
      for (final file in allFiles()) {
        expect(
          code(file).contains('TextDirection.ltr'),
          isFalse,
          reason: file.path,
        );
      }
    });
  });

  group('read-only module', () {
    test('the repository interface exposes no write', () {
      final repository = code(
        File(
          '${featureDir.path}/domain/repositories/customers_repository.dart',
        ),
      );

      // Approving a payment, adjusting a wallet and deciding a refund all have
      // audited homes with their own guards. A second write path into the same
      // rows would be a second set of preconditions to keep in step.
      for (final verb in const [
        'approve',
        'reject',
        'update',
        'delete',
        'create',
        'adjust',
        'refund',
      ]) {
        expect(
          repository.toLowerCase().contains('future<void> $verb'),
          isFalse,
          reason: 'customers is a read surface; found a $verb',
        );
      }
    });
  });
}
