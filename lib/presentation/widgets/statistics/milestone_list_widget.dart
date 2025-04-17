import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MilestoneListWidget extends StatelessWidget {
  final String milestoneDatesJson;

  const MilestoneListWidget({
    super.key,
    required this.milestoneDatesJson,
  });

  @override
  Widget build(BuildContext context) {
    if (milestoneDatesJson.isEmpty || milestoneDatesJson == '[]') {
      return const _EmptyMilestoneList();
    }

    List<Map<String, dynamic>> milestones = [];
    try {
      final List<dynamic> decoded = json.decode(milestoneDatesJson);
      milestones = decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      return Center(
        child: Text('Error parsing milestones: $e'),
      );
    }

    if (milestones.isEmpty) {
      return const _EmptyMilestoneList();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          itemCount: milestones.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final milestone = milestones[index];
            final date = DateTime.parse(milestone['date']);
            final name = milestone['name'];

            return _buildMilestoneItem(date, name);
          },
        ),
      ),
    );
  }

  Widget _buildMilestoneItem(DateTime date, String name) {
    final formattedDate = DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMilestoneList extends StatelessWidget {
  const _EmptyMilestoneList();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No milestones recorded yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                'Keep going, in sha Allah!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
