import '../entities/support_data.dart';

abstract class SupportRepository {
  Future<SupportData> getSupportData();
}
