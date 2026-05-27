import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/correction_request.dart';

final correctionRepositoryProvider = Provider<CorrectionRepository>((ref) {
  return CorrectionRepository(ref.read(supabaseClientProvider));
});

class CorrectionRepository {
  CorrectionRepository(this._client);
  final SupabaseClient _client;

  /// Logs a self-applied correction as an immediately-approved history record.
  Future<CorrectionRequest> logApplied({
    required String userId,
    required DateTime targetDate,
    required CorrectionType requestType,
    required String reason,
    DateTime? requestedCheckIn,
    DateTime? requestedCheckOut,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.tableCorrectionRequests)
          .insert({
            'user_id': userId,
            'target_date': targetDate.toIso8601String().substring(0, 10),
            'request_type': requestType.dbValue,
            'reason': reason,
            'requested_check_in': requestedCheckIn?.toUtc().toIso8601String(),
            'requested_check_out':
                requestedCheckOut?.toUtc().toIso8601String(),
            'status': 'approved',
          })
          .select()
          .single();
      return CorrectionRequest.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<List<CorrectionRequest>> fetchAll(String userId) async {
    try {
      final rows = await _client
          .from(AppConstants.tableCorrectionRequests)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => CorrectionRequest.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }
}
