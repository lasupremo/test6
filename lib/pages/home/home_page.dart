import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/topic_database.dart';
import '../../models/topic.dart';
import '../topic_notes_page.dart';
import '../note_editor_page.dart';
import '../../utils/date_formatter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopicDatabase>().fetchTopics();
      context.read<TopicDatabase>().refreshDueAssessmentsCount();
    });
  }

  List<Map<String, dynamic>> _getRecentNotes(List<Topic> topics) {
    List<Map<String, dynamic>> allNotes = [];
    for (Topic topic in topics) {
      if (topic.notes != null) {
        for (Note note in topic.notes!) {
          allNotes.add({'note': note, 'topic': topic});
        }
      }
    }
    allNotes.sort((a, b) {
      DateTime? aTime = a['note'].updatedAt ?? a['note'].createdAt;
      DateTime? bTime = b['note'].updatedAt ?? b['note'].createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return allNotes;
  }

  void _navigateToNote(Note note, Topic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          topicId: topic.id!,
          topicTitle: topic.text,
          note: note,
        ),
      ),
    );
  }

  void _navigateToTopic(Topic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicNotesPage(topic: topic),
      ),
    );
  }
  
  Widget _buildDueCounter(BuildContext context, int dueCount) {
    final double progressValue = (dueCount / 10).clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progressValue,
            strokeWidth: 8,
            backgroundColor: const Color(0xFFFAB906),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE56316)),
          ),
        ),
        Column(
          children: [
            Text(
              dueCount.toString(),
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            Text(
              'due',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF808080),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600]),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.inversePrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.inversePrimary),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Consumer<TopicDatabase>(
        builder: (context, topicDatabase, child) {
          final recentNotes = _getRecentNotes(topicDatabase.currentTopics);
          // ✅ FIX: Get the live dueCount from the provider's state.
          final dueCount = topicDatabase.dueAssessmentsCount;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    Text(
                      'Hi, ${user?.email?.split('@')[0] ?? 'Guest'}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF808080)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/home/due-assessments'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due assessments',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                // ✅ FIX: Replaced the old FutureBuilder with the live data.
                                child: _buildDueCounter(context, dueCount),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Color(0xFFFF6B35),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Streak',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '420',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar(20, const Color(0xFFE8D5B7)),
                                _buildBar(35, const Color(0xFFE8D5B7)),
                                _buildBar(25, const Color(0xFFE8D5B7)),
                                _buildBar(45, const Color(0xFFE8D5B7)),
                                _buildBar(60, const Color(0xFFDEB887)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Retention score',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 118,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFF32CD32),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Medium',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your retention score shows how well you\'re remembering learned topics.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6D6767),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        context.go('/home/topics');
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB000),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Manage your topics',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (recentNotes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Jump back in your notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D6767),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (int i = 0; i < recentNotes.length && i < 3; i++)
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: i == 0 ? 0 : 6,
                              right: i == recentNotes.length - 1 || i == 2 ? 0 : 6,
                            ),
                            child: _buildNoteCard(
                              recentNotes[i]['note'] as Note,
                              recentNotes[i]['topic'] as Topic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoteCard(Note note, Topic topic) {
    return GestureDetector(
      onTap: () => _navigateToNote(note, topic),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _navigateToTopic(topic),
              child: Container(
                height: 40,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCD7F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    topic.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9E0B9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      _getPlainTextContent(note.content),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatTimeAgo(note.updatedAt ?? note.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  String _getPlainTextContent(String content) {
    return content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}