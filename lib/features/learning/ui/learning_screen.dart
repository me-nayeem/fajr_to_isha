import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/learning_resources.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 20),
          Text('Video Class', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final video in youtubeClasses)
            Card(
              child: InkWell(
                onTap: () => _open(video.url),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                      child: Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.play_circle, size: 48),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(video.title),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Text('Useful Links', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final link in usefulLinks)
            Card(
              child: ListTile(
                leading: Icon(link.icon),
                title: Text(link.title),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(link.url),
              ),
            ),
        ],
      ),
    );
  }
}