import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/assessment_card.dart';
import '../models/assessment.dart';
import '../models/topic_database.dart';

class DueAssessmentsPage extends StatefulWidget {
  const DueAssessmentsPage({super.key});

  @override
  State<DueAssessmentsPage> createState() => _DueAssessmentsPageState();
}

class _DueAssessmentsPageState extends State<DueAssessmentsPage> {
  late final Future<List<Assessment>> _assessmentsFuture;

  @override
  void initState() {
    super.initState();
    // Use your existing TopicDatabase provider to fetch the data
    _assessmentsFuture = context.read<TopicDatabase>().fetchAssessmentsWithDueDates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Assessments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25.0, top: 20.0, bottom: 20.0),
            child: Text(
              'Your Assessments',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Assessment>>(
              future: _assessmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('An error occurred: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('You have no scheduled assessments.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                final assessments = snapshot.data!;
                return ListView.builder(
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    return AssessmentCard(assessment: assessments[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}