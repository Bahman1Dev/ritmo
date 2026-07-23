# Audit Pre-Phase 9: AI Infrastructure

## 1. `AIGateway.sendRawCompletion` Parameters
The method signature is:
```dart
Future<String> sendRawCompletion({
  required String systemPrompt,
  required String userPrompt,
})
```
* **Parameters**: It accepts exactly two parameters, both required strings: `systemPrompt` and `userPrompt`.
* **Note**: It does not currently accept a `temperature` parameter (it hardcodes `temperature: 0.3` internally during the `_postChat` call). If we need to customize temperature, we must either update this method (by adding an optional `double? temperature` argument) or keep it at the default.

## 2. `AICacheManager.set` Default TTL
The method signature is:
```dart
void set(
  String query, 
  Map<String, dynamic> context, 
  Map<String, dynamic> response, 
  {int ttlMinutes = 10}
)
```
* **Default TTL**: The default value for `ttlMinutes` is **10 minutes**.

## 3. List of Files calling `AIGateway`
The `AIGateway` singleton (`AIGateway.instance`) is currently invoked in the following files:
* `lib/core/ai/ai_gateway.dart` (Internal calls)
* `lib/features/assistant/presentation/assistant_chat_screen.dart` (Calls `sendCopilotQueryStream` and `sendRawCompletion`)
* `lib/features/courses/logic/courses_ai_helper.dart` (Calls `sendCustomChat`)
* `lib/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart` (Calls `sendCustomChatStream`)
* `lib/features/energy/presentation/widgets/ai_energy_assistant_sheet.dart` (Calls `sendCustomChatStream`)
* `lib/features/goals/presentation/widgets/create_goal_sheet.dart` (Calls `breakDownGoal`)
* `lib/features/health/presentation/widgets/ai_health_assistant_sheet.dart` (Calls `sendCustomChatStream`)
* `lib/features/konkur/logic/konkur_ai_helper.dart` (Calls `sendCustomChat`)
* `lib/features/profile/presentation/profile_screen.dart` (Refers to `defaultBaseUrl` for settings)
* `lib/features/reflection/presentation/widgets/ai_reflection_assistant_sheet.dart` (Calls `sendCopilotQuery`)
* `lib/features/routines/presentation/routine_create_flow.dart` (Calls `parseQuickAdd`)
* `lib/features/sleep/presentation/widgets/ai_sleep_assistant_sheet.dart` (Calls `sendCustomChatStream`)
* `lib/features/today/presentation/now_dashboard_screen.dart` (Calls `sendQuery`)
* `lib/features/today/presentation/widgets/goals_management_sheet.dart` (Calls `breakDownGoal`)
* `lib/features/worship/presentation/widgets/ai_worship_assistant_sheet.dart` (Calls `sendCustomChatStream`)

## 4. Current Streaming Status for Chat
Yes, streaming is currently utilized for general chat in the Assistant module:
* In `assistant_chat_screen.dart`, line 448, the app calls `AIGateway.instance.sendCopilotQueryStream(...)` to stream responses word-by-word into the UI using a `JSONStreamFilter` and a stream subscription.
