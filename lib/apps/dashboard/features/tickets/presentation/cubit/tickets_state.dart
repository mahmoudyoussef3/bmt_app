import '../../domain/entities/complaint.dart';

sealed class TicketsState {
  const TicketsState();
}

class TicketsLoading extends TicketsState {
  const TicketsLoading();
}

class TicketsError extends TicketsState {
  final String message;
  const TicketsError(this.message);
}

class TicketsLoaded extends TicketsState {
  final List<Complaint> complaints;
  final String? selectedComplaintId;
  final ComplaintStatus? filterStatus;
  final ComplaintPriority? filterPriority;
  final ComplaintCategory? filterCategory;
  final String searchQuery;
  final bool actionLoading;
  final String? actionMessage;

  const TicketsLoaded({
    required this.complaints,
    this.selectedComplaintId,
    this.filterStatus,
    this.filterPriority,
    this.filterCategory,
    this.searchQuery = '',
    this.actionLoading = false,
    this.actionMessage,
  });

  Complaint? get selectedComplaint {
    if (selectedComplaintId == null || complaints.isEmpty) return null;
    for (final c in complaints) {
      if (c.id == selectedComplaintId) return c;
    }
    return complaints.first;
  }

  List<Complaint> get filteredComplaints {
    return complaints.where((c) {
      // 1. Status Filter
      if (filterStatus != null && c.status != filterStatus) return false;

      // 2. Priority Filter
      if (filterPriority != null && c.priority != filterPriority) return false;

      // 3. Category Filter
      if (filterCategory != null && c.category != filterCategory) return false;

      // 4. Search Query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesId = c.id.toLowerCase().contains(query);
        final matchesClient = c.clientName.toLowerCase().contains(query);
        final matchesTrip = c.tripCode.toLowerCase().contains(query);
        final matchesDesc = c.description.toLowerCase().contains(query);
        if (!matchesId && !matchesClient && !matchesTrip && !matchesDesc) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Summary Metrics
  int get newCount {
    return complaints.where((c) => c.status == ComplaintStatus.newlyCreated).length;
  }

  int get inProgressCount {
    return complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
  }

  int get resolvedCount {
    return complaints.where((c) => c.status == ComplaintStatus.resolved).length;
  }

  int get delayedCount {
    final limit = DateTime.now().subtract(const Duration(hours: 24));
    return complaints.where((c) {
      final isUnresolved = c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.closed;
      final isDelayed = c.createdAt.isBefore(limit);
      return isUnresolved && isDelayed;
    }).length;
  }

  TicketsLoaded copyWith({
    List<Complaint>? complaints,
    String? selectedComplaintId,
    ComplaintStatus? filterStatus,
    ComplaintPriority? filterPriority,
    ComplaintCategory? filterCategory,
    String? searchQuery,
    bool? actionLoading,
    String? actionMessage,
    bool clearStatusFilter = false,
    bool clearPriorityFilter = false,
    bool clearCategoryFilter = false,
    bool clearMessage = false,
  }) {
    return TicketsLoaded(
      complaints: complaints ?? this.complaints,
      selectedComplaintId: selectedComplaintId ?? this.selectedComplaintId,
      filterStatus: clearStatusFilter ? null : filterStatus ?? this.filterStatus,
      filterPriority: clearPriorityFilter ? null : filterPriority ?? this.filterPriority,
      filterCategory: clearCategoryFilter ? null : filterCategory ?? this.filterCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      actionLoading: actionLoading ?? this.actionLoading,
      actionMessage: clearMessage ? null : actionMessage ?? this.actionMessage,
    );
  }
}
