import 'package:flutter/material.dart';

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

enum CostFrequency {
  onceOff,
  daily,
  weekly,
  monthly,
  yearly,
  everyXDays,
  everyXWeeks,
  everyXMonths
}

extension CostFrequencyExtension on CostFrequency {
  String get label {
    switch (this) {
      case CostFrequency.onceOff:
        return 'Once-off';
      case CostFrequency.daily:
        return 'Daily';
      case CostFrequency.weekly:
        return 'Weekly';
      case CostFrequency.monthly:
        return 'Monthly';
      case CostFrequency.yearly:
        return 'Yearly';
      case CostFrequency.everyXDays:
        return 'Every X Days';
      case CostFrequency.everyXWeeks:
        return 'Every X Weeks';
      case CostFrequency.everyXMonths:
        return 'Every X Months';
    }
  }

  String get labelWithEmoji {
    switch (this) {
      case CostFrequency.onceOff:
        return '📅 Once-off';
      case CostFrequency.daily:
        return '📆 Daily';
      case CostFrequency.weekly:
        return '📆 Weekly';
      case CostFrequency.monthly:
        return '📆 Monthly';
      case CostFrequency.yearly:
        return '📆 Yearly';
      case CostFrequency.everyXDays:
        return '🔁 Every X Days';
      case CostFrequency.everyXWeeks:
        return '🔁 Every X Weeks';
      case CostFrequency.everyXMonths:
        return '🔁 Every X Months';
    }
  }

  String get value {
    switch (this) {
      case CostFrequency.onceOff:
        return 'once_off';
      case CostFrequency.daily:
        return 'daily';
      case CostFrequency.weekly:
        return 'weekly';
      case CostFrequency.monthly:
        return 'monthly';
      case CostFrequency.yearly:
        return 'yearly';
      case CostFrequency.everyXDays:
        return 'every_x_days';
      case CostFrequency.everyXWeeks:
        return 'every_x_weeks';
      case CostFrequency.everyXMonths:
        return 'every_x_months';
    }
  }
}

CostFrequency costFrequencyFromString(String s) {
  switch (s) {
    case 'once_off':
      return CostFrequency.onceOff;
    case 'daily':
      return CostFrequency.daily;
    case 'weekly':
      return CostFrequency.weekly;
    case 'monthly':
      return CostFrequency.monthly;
    case 'yearly':
      return CostFrequency.yearly;
    case 'every_x_days':
      return CostFrequency.everyXDays;
    case 'every_x_weeks':
      return CostFrequency.everyXWeeks;
    case 'every_x_months':
      return CostFrequency.everyXMonths;
    default:
      return CostFrequency.monthly;
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
  final double
      paymentToMunicipality; // NEW: Track payments made to municipality
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
    this.paymentToMunicipality = 0, // NEW
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

  // Get the end date of the annual rates period (12 months from start)
  DateTime? get annualRatesEndDate {
    if (ratesFrequency != RatesFrequency.annually || ratesStartDate == null) {
      return null;
    }
    // Add 12 months to start date, then subtract 1 day to get last day of 12th month
    final startYear = ratesStartDate!.year;
    final startMonth = ratesStartDate!.month;
    // Add 12 months
    int endYear = startYear + 1;
    int endMonth = startMonth;
    // Return last day of the month before the anniversary month
    return DateTime(endYear, endMonth, 0);
  }

  double get totalExpenses =>
      water +
      electricity +
      interest +
      effectiveMonthlyRates +
      (annualLevy ?? 0);

  double get netBalance => paymentReceived - totalExpenses;

  // NEW: Balance after municipality payments
  double get balanceAfterMunicipality =>
      paymentReceived - totalExpenses - paymentToMunicipality;

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
        paymentToMunicipality:
            (json['payment_to_municipality'] as num?)?.toDouble() ?? 0, // NEW
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
        'payment_to_municipality': paymentToMunicipality, // NEW
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
    double? paymentToMunicipality, // NEW
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
        paymentToMunicipality:
            paymentToMunicipality ?? this.paymentToMunicipality, // NEW
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
      case CostCategory.insurance:
        return '🛡️';
      case CostCategory.custom:
        return '📋';
    }
  }

  IconData get icon {
    switch (this) {
      case CostCategory.cleaning:
        return Icons.cleaning_services;
      case CostCategory.garden:
        return Icons.yard;
      case CostCategory.maintenance:
        return Icons.build;
      case CostCategory.insurance:
        return Icons.security;
      case CostCategory.custom:
        return Icons.receipt_long;
    }
  }

  Color get color {
    switch (this) {
      case CostCategory.cleaning:
        return const Color(0xFF42A5F5);
      case CostCategory.garden:
        return const Color(0xFF66BB6A);
      case CostCategory.maintenance:
        return const Color(0xFFAB47BC);
      case CostCategory.insurance:
        return const Color(0xFFEF5350);
      case CostCategory.custom:
        return const Color(0xFF78909C);
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
  final CostFrequency frequency;
  final int? interval; // For every X days/weeks/months
  final int? dayOfWeek; // Optional: 1-7 (Monday-Sunday)
  final int? dayOfMonth; // Optional: 1-31
  final DateTime startDate;
  final DateTime? endDate;

  RunningCost({
    this.id,
    required this.propertyId,
    required this.year,
    required this.month,
    required this.category,
    this.description,
    required this.amount,
    CostFrequency? frequency,
    this.interval,
    this.dayOfWeek,
    this.dayOfMonth,
    DateTime? startDate,
    this.endDate,
  })  : frequency = frequency ?? CostFrequency.monthly,
        startDate = startDate ?? DateTime.now();

  factory RunningCost.fromJson(Map<String, dynamic> json) => RunningCost(
        id: json['id'] as String?,
        propertyId: json['property_id'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        category: CostCategory.fromString(json['category'] as String),
        description: json['description'] as String?,
        amount: (json['amount'] as num).toDouble(),
        frequency: json['frequency'] != null
            ? costFrequencyFromString(json['frequency'] as String)
            : CostFrequency.monthly,
        interval: json['interval'] as int?,
        dayOfWeek: json['day_of_week'] as int?,
        dayOfMonth: json['day_of_month'] as int?,
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : DateTime(json['year'] as int, json['month'] as int, 1),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'year': year,
        'month': month,
        'category': category.name,
        'description': description,
        'amount': amount,
        'frequency': frequency.value,
        'interval': interval,
        'day_of_week': dayOfWeek,
        'day_of_month': dayOfMonth,
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
      };

  double get monthlyEquivalent {
    switch (frequency) {
      case CostFrequency.onceOff:
        return amount;
      case CostFrequency.daily:
        return amount * 30;
      case CostFrequency.weekly:
        return amount * 4;
      case CostFrequency.monthly:
        return amount;
      case CostFrequency.yearly:
        return amount / 12;
      case CostFrequency.everyXDays:
        // If every X days, calculate how many times per month (30 days)
        final daysInterval = interval ?? 1;
        return amount * (30 / daysInterval);
      case CostFrequency.everyXWeeks:
        // If every X weeks, calculate how many times per month (4 weeks)
        final weeksInterval = interval ?? 1;
        return amount * (4 / weeksInterval);
      case CostFrequency.everyXMonths:
        // If every X months, divide the amount by the interval
        final monthsInterval = interval ?? 1;
        return amount / monthsInterval;
    }
  }

  String get frequencyDisplay {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (interval != null && interval! > 1) {
      switch (frequency) {
        case CostFrequency.everyXDays:
          return 'Every $interval days';
        case CostFrequency.everyXWeeks:
          final dayStr = dayOfWeek != null ? ' (${days[dayOfWeek! - 1]})' : '';
          return 'Every $interval weeks$dayStr';
        case CostFrequency.everyXMonths:
          return 'Every $interval months';
        default:
          break;
      }
    }
    if (dayOfWeek != null) {
      return 'Every ${frequency.label.toLowerCase()} (${days[dayOfWeek! - 1]})';
    }
    if (dayOfMonth != null) {
      final suffix = _getOrdinalSuffix(dayOfMonth!);
      return 'On the $dayOfMonth$suffix';
    }
    return frequency.label;
  }

  String _getOrdinalSuffix(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ─── models/site_evaluation.dart ─────────────────────────────────────────────

class SiteEvaluation {
  final String? id;
  final String propertyId;
  final DateTime evaluationDate;
  final double value;
  final String? notes;

  const SiteEvaluation({
    this.id,
    required this.propertyId,
    required this.evaluationDate,
    required this.value,
    this.notes,
  });

  factory SiteEvaluation.fromJson(Map<String, dynamic> json) => SiteEvaluation(
        id: json['id'] as String?,
        propertyId: json['property_id'] as String,
        evaluationDate: DateTime.parse(json['evaluation_date'] as String),
        value: (json['value'] as num).toDouble(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'evaluation_date': evaluationDate.toIso8601String().substring(0, 10),
        'value': value,
        'notes': notes,
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
