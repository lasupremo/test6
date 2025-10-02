import 'package:flutter/material.dart';
import '../components/topic_settings.dart';
import '../models/topic.dart';
import '../pages/topic_notes_page.dart';
import 'package:popover/popover.dart';

class TopicTile extends StatelessWidget {
  final Topic topic;
  final void Function()? onEditPressed;
  final void Function()? onDeletePressed;

  const TopicTile({
    super.key,
    required this.topic,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final noteCount = topic.notes?.length ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 10, left: 25, right: 25,),
      child: ListTile(
        title: Text(topic.text),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic.desc != null && topic.desc!.isNotEmpty) ...[
              Text(
                topic.desc!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            if (noteCount > 0)
              Text(
                '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to topic notes page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicNotesPage(topic: topic),
            ),
          );
        },
        trailing: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showPopover(
              width: 100,
              height: 100,
              backgroundColor: Theme.of(context).colorScheme.surface,
              context: context,
              bodyBuilder: (context) => TopicSettings(
                onEditTap: onEditPressed,
                onDeleteTap: onDeletePressed,
              ),
            ),
          )
        ),
      ),
    );
  }
}