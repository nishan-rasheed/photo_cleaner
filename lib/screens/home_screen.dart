import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/photo_view.dart';
import '../widgets/thumbnail_bar.dart';
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
    // Fetch assets after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().fetchAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Snap'),
        actions: [
          Consumer<PhotoProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Badge(
                  label: Text('${provider.idsToDelete.length}'),
                  isLabelVisible: provider.idsToDelete.isNotEmpty,
                  child: const Icon(Icons.delete_outline),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReviewScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasPermission) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Permission required to access photos'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAssets(),
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            );
          }

          if (provider.activeAssets.isEmpty) {
            return const Center(child: Text('No photos found'));
          }

          return Column(
            children: [
              Expanded(
                child: PhotoView(
                  assets: provider.activeAssets,
                  currentIndex: provider.currentIndex,
                  onIndexChanged: (index) {
                    provider.setCurrentIndex(index);
                  },
                  onMarkForDeletion: () {
                    final asset = provider.activeAssets[provider.currentIndex];
                    provider.markForDeletion(asset);
                  },
                ),
              ),
              const SizedBox(height: 16),
              ThumbnailBar(
                assets: provider.activeAssets,
                currentIndex: provider.currentIndex,
                onTap: (index) {
                  provider.setCurrentIndex(index);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
