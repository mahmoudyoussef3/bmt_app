import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_document.dart';

sealed class FleetDocumentsState {
  const FleetDocumentsState();
}

class FleetDocumentsLoading extends FleetDocumentsState {
  const FleetDocumentsLoading();
}

class FleetDocumentsError extends FleetDocumentsState {
  final String message;
  const FleetDocumentsError(this.message);
}

class FleetDocumentsLoaded extends FleetDocumentsState {
  final List<FleetDocument> documents;
  final String searchQuery;
  final String filter;

  const FleetDocumentsLoaded({
    required this.documents,
    this.searchQuery = '',
    this.filter = 'الكل',
  });

  FleetDocumentsLoaded copyWith({
    List<FleetDocument>? documents,
    String? searchQuery,
    String? filter,
  }) {
    return FleetDocumentsLoaded(
      documents: documents ?? this.documents,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  List<FleetDocument> get filteredDocuments {
    var result = documents;
    if (filter != 'الكل') {
      result = result.where((d) => d.status.label == filter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (d) =>
                d.ownerName.toLowerCase().contains(q) ||
                d.type.label.toLowerCase().contains(q) ||
                d.referenceNumber.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }
}
