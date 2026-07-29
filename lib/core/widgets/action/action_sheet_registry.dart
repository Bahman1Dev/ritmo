import 'package:flutter/widgets.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/widgets/action/action_capabilities.dart';
import 'package:ritmo/core/widgets/action/sheet_actions.dart';

/// Abstract base class for domain-specific action sheet body contents.
abstract class ActionBody extends StatelessWidget {
  const ActionBody({super.key});

  /// Declarative capabilities of this domain action body.
  ActionCapabilities get capabilities;

  /// Generate list of internal submission actions (e.g. submit, skip, revert).
  List<SubmitAction> getSubmitActions(BuildContext context);

  /// Generate list of external handoff actions (e.g. timer, edit, details).
  List<HandoffAction> getHandoffActions(BuildContext context);
}

typedef ActionBodyBuilder = ActionBody Function(AgendaItem item);

/// Registry mapping AgendaDomain enum values to domain ActionBody builders.
class ActionSheetRegistry {
  ActionSheetRegistry._();

  static final Map<AgendaDomain, ActionBodyBuilder> _registry = {};

  static void register(AgendaDomain domain, ActionBodyBuilder builder) {
    _registry[domain] = builder;
  }

  static ActionBodyBuilder? get(AgendaDomain domain) {
    return _registry[domain];
  }

  static bool isRegistered(AgendaDomain domain) {
    return _registry.containsKey(domain);
  }
}
