import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanStatus { requested, active, returned, overdue }

class LoanModel {
  final String loanId;
  final String gameId;
  final String ownerId;
  final String borrowerId;
  final DateTime requestDate;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? returnDate;
  final LoanStatus status;
  final List<String> checkoutPhotos;
  final List<String> checkinPhotos;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanModel({
    required this.loanId,
    required this.gameId,
    required this.ownerId,
    required this.borrowerId,
    required this.requestDate,
    this.startDate,
    this.dueDate,
    this.returnDate,
    required this.status,
    required this.checkoutPhotos,
    required this.checkinPhotos,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      loanId: doc.id,
      gameId: data['gameId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      borrowerId: data['borrowerId'] ?? '',
      requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      returnDate: (data['returnDate'] as Timestamp?)?.toDate(),
      status: LoanStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => LoanStatus.requested,
      ),
      checkoutPhotos: List<String>.from(data['checkoutPhotos'] ?? []),
      checkinPhotos: List<String>.from(data['checkinPhotos'] ?? []),
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'ownerId': ownerId,
      'borrowerId': borrowerId,
      'requestDate': Timestamp.fromDate(requestDate),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'status': status.toString().split('.').last,
      'checkoutPhotos': checkoutPhotos,
      'checkinPhotos': checkinPhotos,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LoanModel copyWith({
    String? loanId,
    String? gameId,
    String? ownerId,
    String? borrowerId,
    DateTime? requestDate,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? returnDate,
    LoanStatus? status,
    List<String>? checkoutPhotos,
    List<String>? checkinPhotos,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      loanId: loanId ?? this.loanId,
      gameId: gameId ?? this.gameId,
      ownerId: ownerId ?? this.ownerId,
      borrowerId: borrowerId ?? this.borrowerId,
      requestDate: requestDate ?? this.requestDate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      checkoutPhotos: checkoutPhotos ?? this.checkoutPhotos,
      checkinPhotos: checkinPhotos ?? this.checkinPhotos,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    if (status != LoanStatus.active || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}