import 'package:ritmo/core/domain/commands/ritmo_command.dart';

/// Defines an Assistant Persona in Ritmo AI Architecture
class AssistantPersona {
  const AssistantPersona({
    required this.id,
    required this.displayName,
    required this.systemPromptKey,
    required this.reads,
    required this.commandIds,
    this.handoffHint,
  });

  final String id;
  final String displayName;
  final String systemPromptKey;

  /// Data domains this persona is allowed to read.
  /// PRIVACY RULE: Only 'cycle' and 'health' personas may include DataDomain.cycle or DataDomain.medical.
  final Set<DataDomain> reads;

  /// Set of command IDs registered for this persona.
  final Set<String> commandIds;

  /// Optional handoff hint for switching to another specialty persona
  final String? handoffHint;

  bool canReadDomain(DataDomain domain) {
    if (domain == DataDomain.cycle && id != 'cycle') return false;
    if (domain == DataDomain.medical && id != 'health') return false;
    return reads.contains(domain);
  }
}
