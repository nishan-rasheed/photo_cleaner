import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

class ThumbnailBar extends StatefulWidget {
  final List<AssetEntity> assets;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ThumbnailBar({
    super.key,
    required this.assets,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<ThumbnailBar> createState() => _ThumbnailBarState();
}

class _ThumbnailBarState extends State<ThumbnailBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(ThumbnailBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToIndex(widget.currentIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (_scrollController.hasClients) {
      // Simple calculation to center the item:
      // itemWidth = 60 + 8 margin = 68
      // screenWidth / 2
      double offset =
          (index * 68.0) - (MediaQuery.of(context).size.width / 2) + 34;
      if (offset < 0) offset = 0;
      if (offset > _scrollController.position.maxScrollExtent) {
        offset = _scrollController.position.maxScrollExtent;
      }

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.assets.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final asset = widget.assets[index];
          final isSelected = index == widget.currentIndex;
          final isMarked = provider.isMarked(asset.id);

          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _CachedSmallThumbnail(asset: asset),
                  ),
                  if (isMarked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CachedSmallThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const _CachedSmallThumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final cached = provider.getCachedSmallThumbnail(asset.id);

    if (cached != null) {
      return Image.memory(cached, fit: BoxFit.cover);
    }

    return FutureBuilder<Uint8List?>(
      future: provider.getSmallThumbnail(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: Colors.grey[800]);
      },
    );
  }
}
