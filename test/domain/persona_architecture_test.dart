import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/commands/commands_registry.dart';
import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/ritmo_command_bus.dart';
import 'package:ritmo/core/domain/personas/assistant_persona.dart';
import 'package:ritmo/core/domain/personas/persona_registry.dart';

void main() {
  setUpAll(() {
    registerAllRitmoCommands();
    PersonaRegistry.instance.initStandardPersonas();
  });

  group('Phase C Structural Tests — Persona & Command Architecture', () {
    test('1. Every registered RitmoCommand belongs to at least one persona', () {
      final allCmdIds = RitmoCommandBus.instance.registeredCommandIds;
      final registeredPersonaCmdIds = <String>{};

      for (final persona in PersonaRegistry.instance.allPersonas) {
        registeredPersonaCmdIds.addAll(persona.commandIds);
      }

      for (final cmdId in allCmdIds) {
        expect(
          registeredPersonaCmdIds.contains(cmdId),
          isTrue,
          reason: 'Command "$cmdId" is not assigned to any AssistantPersona.',
        );
      }
    });

    test('2. All commandIds declared in personas actually exist in RitmoCommandBus', () {
      final validCmdIds = RitmoCommandBus.instance.registeredCommandIds;

      for (final persona in PersonaRegistry.instance.allPersonas) {
        for (final cmdId in persona.commandIds) {
          expect(
            validCmdIds.contains(cmdId),
            isTrue,
            reason: 'Persona "${persona.id}" references non-existent command "$cmdId".',
          );
        }
      }
    });

    test('3. Privacy Guard: ONLY cycle and health personas read sensitive domains (DataDomain.cycle and DataDomain.medical)', () {
      for (final persona in PersonaRegistry.instance.allPersonas) {
        if (persona.id != 'cycle') {
          expect(
            persona.reads.contains(DataDomain.cycle),
            isFalse,
            reason: 'Persona "${persona.id}" is illegally allowed to read DataDomain.cycle.',
          );
        }
        if (persona.id != 'health') {
          expect(
            persona.reads.contains(DataDomain.medical),
            isFalse,
            reason: 'Persona "${persona.id}" is illegally allowed to read DataDomain.medical.',
          );
        }
      }
    });
  });
}
