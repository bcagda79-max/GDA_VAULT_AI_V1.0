import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/services/api_service.dart';

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiService.instance.getDashboardStats();
});

