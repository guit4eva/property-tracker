import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ─── Properties ────────────────────────────────────────────────────────────

  static Future<List<Property>> fetchProperties() async {
    final data = await _client
        .from('properties')
        .select('*, evaluations:site_evaluations(*)')
        .order('created_at', ascending: true);
    return (data as List).map((e) => Property.fromJson(e)).toList();
  }

  static Future<Property> createProperty(Property p) async {
    final data = await _client
        .from('properties')
        .insert(p.toJson())
        .select()
        .single();
    return Property.fromJson(data);
  }

  static Future<Property> updateProperty(Property p) async {
    final data = await _client
        .from('properties')
        .update(p.toJson())
        .eq('id', p.id)
        .select()
        .single();
    return Property.fromJson(data);
  }

  static Future<void> deleteProperty(String id) async {
    await _client.from('properties').delete().eq('id', id);
  }

  // ─── Monthly Expenses ───────────────────────────────────────────────────────

  static Future<List<MonthlyExpense>> fetchExpensesForProperty(
      String propertyId) async {
    final data = await _client
        .from('monthly_expenses')
        .select()
        .eq('property_id', propertyId)
        .order('year', ascending: true)
        .order('month', ascending: true);
    return (data as List).map((e) => MonthlyExpense.fromJson(e)).toList();
  }

  static Future<MonthlyExpense?> fetchExpenseForMonth(
      String propertyId, int year, int month) async {
    final data = await _client
        .from('monthly_expenses')
        .select()
        .eq('property_id', propertyId)
        .eq('year', year)
        .eq('month', month)
        .maybeSingle();
    if (data == null) return null;
    return MonthlyExpense.fromJson(data);
  }

  static Future<MonthlyExpense> upsertExpense(MonthlyExpense e) async {
    final json = e.toJson();
    if (e.id != null) {
      final data = await _client
          .from('monthly_expenses')
          .update(json)
          .eq('id', e.id!)
          .select()
          .single();
      return MonthlyExpense.fromJson(data);
    } else {
      final data = await _client
          .from('monthly_expenses')
          .upsert(json, onConflict: 'property_id,year,month')
          .select()
          .single();
      return MonthlyExpense.fromJson(data);
    }
  }

  // ─── Running Costs ──────────────────────────────────────────────────────────

  static Future<List<RunningCost>> fetchRunningCostsForProperty(
      String propertyId) async {
    final data = await _client
        .from('running_costs')
        .select()
        .eq('property_id', propertyId)
        .order('year', ascending: true)
        .order('month', ascending: true);
    return (data as List).map((e) => RunningCost.fromJson(e)).toList();
  }

  static Future<List<RunningCost>> fetchRunningCostsForMonth(
      String propertyId, int year, int month) async {
    final data = await _client
        .from('running_costs')
        .select()
        .eq('property_id', propertyId)
        .eq('year', year)
        .eq('month', month)
        .order('created_at');
    return (data as List).map((e) => RunningCost.fromJson(e)).toList();
  }

  static Future<RunningCost> createRunningCost(RunningCost c) async {
    final data = await _client
        .from('running_costs')
        .insert(c.toJson())
        .select()
        .single();
    return RunningCost.fromJson(data);
  }

  static Future<RunningCost> updateRunningCost(RunningCost c) async {
    final data = await _client
        .from('running_costs')
        .update(c.toJson())
        .eq('id', c.id!)
        .select()
        .single();
    return RunningCost.fromJson(data);
  }

  static Future<void> deleteRunningCost(String id) async {
    await _client.from('running_costs').delete().eq('id', id);
  }

  // ─── Site Evaluations ───────────────────────────────────────────────────────

  static Future<List<SiteEvaluation>> fetchEvaluationsForProperty(
      String propertyId) async {
    final data = await _client
        .from('site_evaluations')
        .select()
        .eq('property_id', propertyId)
        .order('evaluation_date', ascending: true);
    return (data as List).map((e) => SiteEvaluation.fromJson(e)).toList();
  }

  static Future<SiteEvaluation> createEvaluation(SiteEvaluation e) async {
    final data = await _client
        .from('site_evaluations')
        .insert(e.toJson())
        .select()
        .single();
    return SiteEvaluation.fromJson(data);
  }

  static Future<void> deleteEvaluation(String id) async {
    await _client.from('site_evaluations').delete().eq('id', id);
  }

  // ─── Rent Periods ───────────────────────────────────────────────────────────

  static Future<List<RentPeriod>> fetchRentPeriodsForProperty(
      String propertyId) async {
    final data = await _client
        .from('rent_periods')
        .select()
        .eq('property_id', propertyId)
        .order('start_date', ascending: true);
    return (data as List).map((e) => RentPeriod.fromJson(e)).toList();
  }

  static Future<RentPeriod> createRentPeriod(RentPeriod r) async {
    final data = await _client
        .from('rent_periods')
        .insert(r.toJson())
        .select()
        .single();
    return RentPeriod.fromJson(data);
  }

  static Future<RentPeriod> updateRentPeriod(RentPeriod r) async {
    final data = await _client
        .from('rent_periods')
        .update(r.toJson())
        .eq('id', r.id!)
        .select()
        .single();
    return RentPeriod.fromJson(data);
  }

  static Future<void> deleteRentPeriod(String id) async {
    await _client.from('rent_periods').delete().eq('id', id);
  }
}
