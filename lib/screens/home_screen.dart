import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/photo_view.dart';
import '../widgets/thumbnail_bar.dart';
import '../widgets/tutorial_overlay.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().checkTutorialStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Bar (Back button & Title)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        "${provider.currentIndex + 1} / ${provider.activeAssets.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReviewScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Main Photo View
              Expanded(
                child: provider.activeAssets.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : PhotoView(
                        assets: provider.activeAssets,
                        currentIndex: provider.currentIndex,
                        onIndexChanged: (index) =>
                            provider.setCurrentIndex(index),
                        onMarkForDeletion: () {
                          final asset =
                              provider.activeAssets[provider.currentIndex];
                          provider.markForDeletion(asset);
                        },
                      ),
              ),

              // Thumbnail Bar
              const SizedBox(height: 16),
              ThumbnailBar(
                assets: provider.activeAssets,
                currentIndex: provider.currentIndex,
                onTap: (index) => provider.setCurrentIndex(index),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Tutorial Overlay
          if (provider.showTutorial)
            TutorialOverlay(
              onDismiss: () {
                provider.completeTutorial();
              },
            ),
        ],
      ),
    );
  }
}
