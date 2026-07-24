import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/journey_controller.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final JourneyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JourneyController();
    _controller.loadDate(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final snapshot = _controller.snapshot;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Journey Overview (${_controller.selectedDate.year}-${_controller.selectedDate.month.toString().padLeft(2, '0')}-${_controller.selectedDate.day.toString().padLeft(2, '0')})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _controller.refresh,
              ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.errorMessage != null
                  ? Center(child: Text('Error: ${_controller.errorMessage}'))
                  : snapshot == null
                      ? const Center(child: Text('No agenda data found.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rhythm Score: ${snapshot.rhythmScore}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Completed: ${snapshot.completedCount}'),
                                          Text('Remaining: ${snapshot.remainingCount}'),
                                          Text('Free Gaps: ${snapshot.freeGaps.length}'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Capacity Overload Score: ${snapshot.overloadScore}'),
                                    ],
                                  ),
                                ),
                              ),
                              if (snapshot.currentActivity != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Current Activity: ${snapshot.currentActivity!.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (snapshot.nextActivity != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Next Activity: ${snapshot.nextActivity!.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (snapshot.conflicts.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Detected Conflicts:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                                const SizedBox(height: 8),
                                for (final conflict in snapshot.conflicts)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text('• ${conflict.description}'),
                                  ),
                              ],
                              if (snapshot.suggestions.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Smart Suggestions:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                ),
                                const SizedBox(height: 8),
                                for (final suggestion in snapshot.suggestions)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text('• ${suggestion.message}'),
                                  ),
                              ],
                            ],
                          ),
                        ),
        );
      },
    );
  }
}
