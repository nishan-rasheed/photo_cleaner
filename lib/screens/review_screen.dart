import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../providers/photo_provider.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final markedIds = provider.idsToDelete;
    
    // Filter assets to show only marked ones
    final markedAssets = provider.assets.where((a) => markedIds.contains(a.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Deletion (${markedAssets.length})'),
      ),
      body: markedAssets.isEmpty
          ? const Center(child: Text('No photos marked for deletion'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: markedAssets.length,
              itemBuilder: (context, index) {
                final asset = markedAssets[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<List<int>?>(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(200, 200),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data as dynamic,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(color: Colors.grey[800]);
                      },
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          provider.undoMark(asset.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restore,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: markedAssets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Photos?'),
                    content: Text(
                        'Are you sure you want to permanently delete ${markedAssets.length} photos? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await provider.deleteMarkedAssets();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              label: const Text('Delete All'),
              icon: const Icon(Icons.delete_forever),
              backgroundColor: Colors.redAccent,
            )
          : null,
    );
  }
}
