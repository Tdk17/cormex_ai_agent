import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

class LeadPage {
  const LeadPage({
    required this.items,
    this.nextCursor,
    this.correlationId,
  });

  final List<LeadModel> items;
  final String? nextCursor;
  final String? correlationId;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}
