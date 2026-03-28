// ─── models/property.dart ────────────────────────────────────────────────────

class Property {
  final String id;
  final String name;
  final String? address;
  final double? siteValue;
  final DateTime createdAt;
  final List<SiteEvaluation> evaluationHistory;

  const Property({
    required this.id,
    required this.name,
    this.address,
    this.siteValue,
    required this.createdAt,
    this.evaluationHistory = const [], // Empty list is fine as const default
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      siteValue: (json['site_value'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      evaluationHistory: (json['evaluations'] as List<dynamic>?)
              ?.map((e) => SiteEvaluation.fromJson(e))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'site_value': siteValue,
      };

  Property copyWith({
    String? name,
    String? address,
    double? siteValue,
    List<SiteEvaluation>? evaluationHistory,
  }) =>
      Property(
        id: id,
        name: name ?? this.name,
        address: address ?? this.address,
        siteValue: siteValue ?? this.siteValue,
        createdAt: createdAt,
        evaluationHistory: evaluationHistory ?? this.evaluationHistory,
      );

  double get currentValue {
    if (evaluationHistory.isNotEmpty) {
      final sorted = List<SiteEvaluation>.from(evaluationHistory)
        ..sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));
      return sorted.first.value;
    }
    return siteValue ?? 0;
  }

  double get totalAppreciation {
    if (siteValue == null || siteValue == 0) return 0;
    return currentValue - siteValue!;
  }

  double get appreciationPercentage {
    if (siteValue == null || siteValue == 0) return 0;
    return (totalAppreciation / siteValue!) * 100;
  }
}

// ─── models/monthly_expense.dart ─────────────────────────────────────────────

enum RatesFrequency { monthly, annually }

extension RatesFrequencyExtension on RatesFrequency {
  String get label {
    switch (this) {
      case RatesFrequency.monthly:
        return 'Monthly';
      case RatesFrequency.annually:
        return 'Annually';
    }
  }
}

class MonthlyExpense {
  final String? id;
  final String propertyId;
  final int year;
  final int month;
  final double water;
  final double electricity;
  final double interest;
  final double ratesTaxes;
  final double? annualLevy;
  final double paymentReceived;
  final double paymentToMunicipality;  // NEW: Track payments made to municipality
  final String? notes;
  final bool isLocked;
  final RatesFrequency ratesFrequency;
  final DateTime? ratesStartDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyExpense({
    this.id,
    required this.propertyId,
    required this.year,
    required this.month,
    this.water = 0,
    this.electricity = 0,
    this.interest = 0,
    this.ratesTaxes = 0,
    this.annualLevy,
    this.paymentReceived = 0,
    this.paymentToMunicipality = 0,  // NEW
    this.notes,
    this.isLocked = false,
    this.ratesFrequency = RatesFrequency.monthly,
    this.ratesStartDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get effectiveMonthlyRates {
    if (ratesFrequency == RatesFrequency.annually && ratesTaxes > 0) {
      return ratesTaxes / 12;
    }
    return ratesTaxes;
  }

  double get totalExpenses =>
      water +
      electricity +
      interest +
      effectiveMonthlyRates +
      (annualLevy ?? 0);

  double get netBalance => paymentReceived - totalExpenses;
  
  // NEW: Balance after municipality payments
  double get balanceAfterMunicipality => paymentReceived - totalExpenses - paymentToMunicipality;

  factory MonthlyExpense.fromJson(Map<String, dynamic> json) => MonthlyExpense(
        id: json['id'] as String?,
        propertyId: json['property_id'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        water: (json['water'] as num?)?.toDouble() ?? 0,
        electricity: (json['electricity'] as num?)?.toDouble() ?? 0,
        interest: (json['interest'] as num?)?.toDouble() ?? 0,
        ratesTaxes: (json['rates_taxes'] as num?)?.toDouble() ?? 0,
        annualLevy: (json['annual_levy'] as num?)?.toDouble(),
        paymentReceived: (json['payment_received'] as num?)?.toDouble() ?? 0,
        paymentToMunicipality: (json['payment_to_municipality'] as num?)?.toDouble() ?? 0,  // NEW
        notes: json['notes'] as String?,
        isLocked: json['is_locked'] as bool? ?? false,
        ratesFrequency: RatesFrequency.values.firstWhere(
          (e) => e.name == (json['rates_frequency'] as String? ?? 'monthly'),
          orElse: () => RatesFrequency.monthly,
        ),
        ratesStartDate: json['rates_start_date'] != null
            ? DateTime.parse(json['rates_start_date'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'year': year,
        'month': month,
        'water': water,
        'electricity': electricity,
        'interest': interest,
        'rates_taxes': ratesTaxes,
        'annual_levy': annualLevy,
        'payment_received': paymentReceived,
        'payment_to_municipality': paymentToMunicipality,  // NEW
        'notes': notes,
        // is_locked intentionally omitted — managed by the DB schema migration
        'rates_frequency': ratesFrequency.name,
        'rates_start_date': ratesStartDate?.toIso8601String(),
      };

  MonthlyExpense copyWith({
    double? water,
    double? electricity,
    double? interest,
    double? ratesTaxes,
    double? annualLevy,
    double? paymentReceived,
    double? paymentToMunicipality,  // NEW
    String? notes,
    bool? isLocked,
    RatesFrequency? ratesFrequency,
    DateTime? ratesStartDate,
  }) =>
      MonthlyExpense(
        id: id,
        propertyId: propertyId,
        year: year,
        month: month,
        water: water ?? this.water,
        electricity: electricity ?? this.electricity,
        interest: interest ?? this.interest,
        ratesTaxes: ratesTaxes ?? this.ratesTaxes,
        annualLevy: annualLevy ?? this.annualLevy,
        paymentReceived: paymentReceived ?? this.paymentReceived,
        paymentToMunicipality: paymentToMunicipality ?? this.paymentToMunicipality,  // NEW
        notes: notes ?? this.notes,
        isLocked: isLocked ?? this.isLocked,
        ratesFrequency: ratesFrequency ?? this.ratesFrequency,
        ratesStartDate: ratesStartDate ?? this.ratesStartDate,
        createdAt: createdAt,
      );
}

// ─── models/running_cost.dart ─────────────────────────────────────────────────

enum CostCategory {
  cleaning,
  garden,
  maintenance,
  levies,
  insurance,
  custom;

  String get label {
    switch (this) {
      case CostCategory.cleaning:
        return 'Cleaning';
      case CostCategory.garden:
        return 'Garden Service';
      case CostCategory.maintenance:
        return 'Maintenance';
      case CostCategory.levies:
        return 'Body Corporate Levies';
      case CostCategory.insurance:
        return 'Insurance';
      case CostCategory.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case CostCategory.cleaning:
        return 'Regular cleaning services';
      case CostCategory.garden:
        return 'Garden and landscaping services';
      case CostCategory.maintenance:
        return 'General repairs and maintenance';
      case CostCategory.levies:
        return 'Monthly body corporate or HOA fees';
      case CostCategory.insurance:
        return 'Property insurance premiums';
      case CostCategory.custom:
        return 'Other recurring costs';
    }
  }

  String get emoji {
    switch (this) {
      case CostCategory.cleaning:
        return '🧹';
      case CostCategory.garden:
        return '🌿';
      case CostCategory.maintenance:
        return '🔧';
      case CostCategory.levies:
        return '🏢';
      case CostCategory.insurance:
        return '🛡️';
      case CostCategory.custom:
        return '📋';
    }
  }

  static CostCategory fromString(String s) {
    return CostCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CostCategory.custom,
    );
  }
}

class RunningCost {
  final String? id;
  final String propertyId;
  final int year;
  final int month;
  final CostCategory category;
  final String? description;
  final double amount;
  final DateTime startDate;

  RunningCost({
    this.id,
    required this.propertyId,
    required this.year,
    required this.month,
    required this.category,
    this.description,
    required this.amount,
    DateTime? startDate,
  }) : startDate = startDate ?? DateTime.now();

  factory RunningCost.fromJson(Map<String, dynamic> json) => RunningCost(
        id: json['id'] as String?,
        propertyId: json['property_id'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        category: CostCategory.fromString(json['category'] as String),
        description: json['description'] as String?,
        amount: (json['amount'] as num).toDouble(),
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'year': year,
        'month': month,
        'category': category.name,
        'description': description,
        'amount': amount,
        'start_date': startDate.toIso8601String(),
      };
}

// ─── models/site_evaluation.dart ─────────────────────────────────────────────

class SiteEvaluation {
  final String? id;
  final String propertyId;
  final DateTime evaluationDate;
  final double value;
  final String? notes;
  final String? evaluatedBy;

  const SiteEvaluation({
    this.id,
    required this.propertyId,
    required this.evaluationDate,
    required this.value,
    this.notes,
    this.evaluatedBy,
  });

  factory SiteEvaluation.fromJson(Map<String, dynamic> json) => SiteEvaluation(
        id: json['id'] as String?,
        propertyId: json['property_id'] as String,
        evaluationDate: DateTime.parse(json['evaluation_date'] as String),
        value: (json['value'] as num).toDouble(),
        notes: json['notes'] as String?,
        evaluatedBy: json['evaluated_by'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'evaluation_date': evaluationDate.toIso8601String().substring(0, 10),
        'value': value,
        'notes': notes,
        'evaluated_by': evaluatedBy,
      };
}

// ─── models/rent_period.dart ─────────────────────────────────────────────

class RentPeriod {
  final String? id;
  final String propertyId;
  final DateTime startDate;
  final DateTime? endDate; // null means indefinite/current
  final double rentalAmount;
  final DateTime createdAt;

  const RentPeriod({
    this.id,
    required this.propertyId,
    required this.startDate,
    this.endDate,
    required this.rentalAmount,
    required this.createdAt,
  });
  
  RentPeriod copyWith({
    String? id,
    String? propertyId,
    DateTime? startDate,
    DateTime? endDate,
    double? rentalAmount,
    DateTime? createdAt,
  }) {
    return RentPeriod(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentalAmount: rentalAmount ?? this.rentalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RentPeriod.fromJson(Map<String, dynamic> json) => RentPeriod(
        id: json['id'] as String?,
        propertyId: json['property_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        rentalAmount: (json['rental_amount'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date': endDate?.toIso8601String().substring(0, 10),
        'rental_amount': rentalAmount,
      };

  bool isActiveForDate(DateTime date) {
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }
}
