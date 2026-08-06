import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/client_wallet.dart';

/// Reads the rider's own wallets through `client_wallet_summary()`.
///
/// One RPC rather than a table read plus an `offices` embed: the office name is
/// the label the whole screen hangs on, and the client-facing `offices` policy
/// only admits *listed* offices — so an office that left the marketplace would
/// show a real balance beside a blank name. The RPC resolves the name for
/// offices the rider demonstrably has a relationship with, and takes no
/// parameters, so there is nowhere else it can point.
class SupabaseClientWalletDatasource {
  const SupabaseClientWalletDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<ClientWalletSummary> getSummary() async {
    final json =
        await _supabase.rpc('client_wallet_summary') as Map<String, dynamic>;

    return ClientWalletSummary(
      totalBalance: _money(json['total_balance']),
      wallets: [
        for (final row in (json['wallets'] as List? ?? const []))
          _wallet(row as Map<String, dynamic>),
      ],
      generatedAt:
          DateTime.tryParse(json['generated_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  ClientWallet _wallet(Map<String, dynamic> row) => ClientWallet(
    walletId: row['wallet_id']?.toString() ?? '',
    officeId: row['office_id']?.toString() ?? '',
    officeName: (row['office_name']?.toString().trim().isNotEmpty ?? false)
        ? row['office_name'].toString()
        : 'مكتب',
    officeLogoUrl: row['office_logo_url'] as String?,
    balance: _money(row['balance']),
    availableBalance: _money(row['available_balance'] ?? row['balance']),
    status: row['status']?.toString() ?? 'active',
    entryCount: _int(row['entry_count']),
    updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '')?.toLocal(),
    entries: [
      for (final entry in (row['entries'] as List? ?? const []))
        _entry(entry as Map<String, dynamic>),
    ],
  );

  ClientWalletEntry _entry(Map<String, dynamic> row) => ClientWalletEntry(
    id: row['id']?.toString() ?? '',
    seq: _int(row['seq']),
    kind: ClientWalletEntryKind.fromDb(row['kind']?.toString() ?? ''),
    category: row['category']?.toString() ?? '',
    amount: _money(row['amount']),
    balanceAfter: _money(row['balance_after']),
    status: row['status']?.toString() ?? 'posted',
    reason: row['reason']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now(),
  );

  /// Postgres `numeric` reaches the client as `num`, `int` or `String`
  /// depending on magnitude. A balance that silently became 0 because a cast
  /// failed is the worst bug this screen could have.
  static double _money(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _int(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
