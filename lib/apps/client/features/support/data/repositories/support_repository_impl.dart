import '../../domain/entities/support_data.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/mock_support_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._datasource);

  final MockSupportDatasource _datasource;

  @override
  Future<SupportData> getSupportData() async {
    final categories = await _datasource.getCategories();
    final tickets = await _datasource.getTickets();
    return SupportData(
      categories: categories,
      tickets: tickets.map((ticket) => ticket.toEntity()).toList(),
    );
  }
}
