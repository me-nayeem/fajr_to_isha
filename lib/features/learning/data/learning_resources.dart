import 'package:flutter/material.dart';

class LearningResource {
  final String title;
  final String url;
  final IconData icon;

  const LearningResource({
    required this.title,
    required this.url,
    required this.icon,
  });
}

class YoutubeResource {
  final String title;
  final String thumbnailVideoId;
  final String url;

  const YoutubeResource({
    required this.title,
    required this.thumbnailVideoId,
    required this.url,
  });

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$thumbnailVideoId/hqdefault.jpg';
}

class BookResource {
  final String title;
  final String? author;
  final String url;

  const BookResource({
    required this.title,
    this.author,
    required this.url,
  });
}

const quranLearningResources = [
  LearningResource(
    title: 'Arabic Letters',
    url: 'https://www.youtube.com/watch?v=XJzH4rzPsww&list=PLT2DqdbNqk6uEju5wpD96Nw2AwGWK6Woj',
    icon: Icons.abc,
  ),
  LearningResource(
    title: 'Basic Reading — replace with your link',
    url: 'https://quran.com',
    icon: Icons.menu_book,
  ),
  LearningResource(
    title: 'Pronunciation — replace with your link',
    url: 'https://quran.com',
    icon: Icons.record_voice_over,
  ),
  LearningResource(
    title: 'Tajweed Basics — replace with your link',
    url: 'https://quran.com',
    icon: Icons.auto_stories,
  ),
];

const youtubeClasses = [
  YoutubeResource(
    title: 'As-Sunnah Foundation Quran Shikha',
    thumbnailVideoId: 'QjlHTj_rOrw',
    url: 'https://www.youtube.com/watch?v=QjlHTj_rOrw&list=PLwPzGl54tAIvq7mS9B2I0zTIshqO6LST0',
  ),
  YoutubeResource(
    title: 'Learn to Read Quran - Full Beginners Course',
    thumbnailVideoId: 'UgjwAW6DcIQ',
    url: 'https://www.youtube.com/watch?v=UgjwAW6DcIQ&list=PLMpZpT9IRpAC3CgmxnJJxXXVXNCPi7htq',
  ),
  YoutubeResource(
    title: 'Qaida Nuraniyah to Quran - Adults Edition',
    thumbnailVideoId: 'kVusv7iSx_A',
    url: 'https://www.youtube.com/watch?v=kVusv7iSx_A&list=PL6qzEglvHszdO7eGitcmXnvdZi7ZeYhV',
  ),
];

const recommendedBooks = [
  BookResource(
    title: 'Replace with your book title',
    author: 'Replace with author name',
    url: 'https://drive.google.com/REPLACE_WITH_YOUR_LINK',
  ),
];

const usefulLinks = [
  LearningResource(
    title: 'Quran.com',
    url: 'https://quran.com',
    icon: Icons.menu_book,
  ),
  LearningResource(
    title: 'YouTube',
    url: 'https://youtube.com',
    icon: Icons.smart_display,
  ),
  LearningResource(
    title: 'Google',
    url: 'https://google.com',
    icon: Icons.language,
  ),
];