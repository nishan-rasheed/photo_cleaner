import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import 'photo_details_sheet.dart';

class PhotoView extends StatefulWidget {
  final List<AssetEntity> assets;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onMarkForDeletion;

  const PhotoView({
    super.key,
    required this.assets,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onMarkForDeletion,
  });

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> with TickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  AnimationController? _animationController;
  Animation<Offset>? _animation;

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _animationController?.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;

    // Swipe Up (Delete)
    if (_dragOffset.dy < -100 || velocity.dy < -1000) {
      _animateOffScreen(const Offset(0, -1000), () {
        widget.onMarkForDeletion();
        _resetCard();
      });
    }
    // Swipe Left/Right
    else if (_dragOffset.dx.abs() > 100 || velocity.dx.abs() > 1000) {
      final isRightSwipe = _dragOffset.dx > 0;
      // User request: Slide Left -> Next, Slide Right -> Previous (Back)
      // Slide Left (dx < 0) -> Next (index + 1)
      // Slide Right (dx > 0) -> Previous (index - 1)

      int targetIndex = isRightSwipe
          ? widget.currentIndex - 1
          : widget.currentIndex + 1;

      // Check bounds
      if (targetIndex >= 0 && targetIndex < widget.assets.length) {
        final direction = isRightSwipe ? 1 : -1;
        _animateOffScreen(Offset(direction * 1000, 0), () {
          widget.onIndexChanged(targetIndex);
          _resetCard();
        });
      } else {
        // Cannot navigate that way, snap back
        _animateBackToCenter();
      }
    } else {
      _animateBackToCenter();
    }
  }

  void _animateOffScreen(Offset target, VoidCallback onComplete) {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    _animationController!.addListener(() {
      setState(() {
        _dragOffset = _animation!.value;
      });
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete();
      }
    });

    _animationController!.forward();
  }

  void _animateBackToCenter() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.elasticOut),
    );

    _animationController!.addListener(() {
      setState(() {
        _dragOffset = _animation!.value;
      });
    });

    _animationController!.forward();
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) return const SizedBox();

    final currentAsset = widget.assets[widget.currentIndex];

    // Determine background asset based on drag direction
    AssetEntity? backgroundAsset;

    // If dragging Right (dx > 0) and not swiping Up (dy > -50), show Previous
    // We check dy > -50 to ensure we prioritize "Next" if the user is primarily swiping Up to delete
    bool showPrevious =
        _dragOffset.dx > 0 && _dragOffset.dy > -50 && widget.currentIndex > 0;

    if (showPrevious) {
      backgroundAsset = widget.assets[widget.currentIndex - 1];
    } else if (widget.currentIndex < widget.assets.length - 1) {
      backgroundAsset = widget.assets[widget.currentIndex + 1];
    }

    // Calculate swipe progress (0.0 to 1.0)
    // We use a threshold of 300.0 pixels for full transition
    final double dragDistance = _dragOffset.distance;
    final double progress = (dragDistance / 300.0).clamp(0.0, 1.0);

    // Interpolate scale from 0.9 to 1.0 based on progress
    final double backgroundScale = 0.9 + (0.1 * progress);

    return Stack(
      children: [
        // Background Card
        if (backgroundAsset != null)
          Positioned.fill(
            child: Transform.scale(
              scale: backgroundScale,
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Match foreground padding
                child: _buildCard(backgroundAsset, isInteractive: false),
              ),
            ),
          ),

        // Foreground Card (Current Photo)
        Positioned.fill(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _dragOffset.dx / 1000, // Rotate based on X drag
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCard(currentAsset, isInteractive: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AssetEntity asset, {required bool isInteractive}) {
    // Access provider to get cached image
    // We need to find the provider. Since we are in a State, we can use context.read
    // But we need to be careful about rebuilds.
    // Actually, we can just use a helper widget that consumes the provider or pass the provider in.
    // For simplicity, let's use context.read inside the builder or just look it up.

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CachedAssetImage(asset: asset),

          // Metadata Overlay (Only for interactive card)
          if (isInteractive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<List<dynamic>>(
                            future: Future.wait([
                              asset.file,
                              asset.mimeTypeAsync,
                            ]),
                            builder: (context, snapshot) {
                              String sizeText = "Loading...";
                              String typeText = "IMG";

                              if (snapshot.hasData && snapshot.data != null) {
                                // File Size
                                final File? file = snapshot.data![0] as File?;
                                if (file != null) {
                                  final sizeInBytes = file.lengthSync();
                                  if (sizeInBytes < 1024 * 1024) {
                                    sizeText =
                                        "${(sizeInBytes / 1024).toStringAsFixed(0)} KB";
                                  } else {
                                    sizeText =
                                        "${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
                                  }
                                }

                                // Mime Type
                                final String? mimeType =
                                    snapshot.data![1] as String?;
                                if (mimeType != null) {
                                  // e.g. "image/jpeg" -> "JPG"
                                  typeText = mimeType
                                      .split('/')
                                      .last
                                      .toUpperCase();
                                  if (typeText == "JPEG") typeText = "JPG";
                                } else {
                                  // Fallback to title extension
                                  final ext = asset.title
                                      ?.split('.')
                                      .last
                                      .toUpperCase();
                                  if (ext != null &&
                                      ext.isNotEmpty &&
                                      ext.length < 5) {
                                    typeText = ext;
                                  }
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sizeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      typeText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                PhotoDetailsSheet(asset: asset),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isInteractive) _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    // Show "Delete" when dragging up
    if (_dragOffset.dy < -50) {
      final opacity = (-_dragOffset.dy / 200).clamp(0.0, 1.0);
      return Positioned.fill(
        child: Container(
          color: Colors.red.withValues(alpha: opacity * 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_forever,
                  color: Colors.white.withValues(alpha: opacity),
                  size: 80,
                ),
                Text(
                  "DELETE",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: opacity),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }
}

class _CachedAssetImage extends StatelessWidget {
  final AssetEntity asset;

  const _CachedAssetImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    // We need to import provider to use context.read/watch
    // But wait, PhotoView doesn't import provider yet?
    // It's better to pass the cache function or use a Consumer?
    // Let's assume we can access PhotoProvider via context if we import it.
    // But to avoid circular deps or messy imports, let's look up via Provider.of if we import provider.
    // Or we can just use the FutureBuilder pattern but optimized.

    // Actually, let's just import provider in this file.
    // If I can't easily add the import here without messing up top of file, I'll use a dynamic approach?
    // No, let's do it properly. I will add the import in a separate step if needed,
    // but for now let's assume I can use context.read if I add the import.

    // Wait, I can't add import in this block.
    // I will use a FutureBuilder that checks a static cache?
    // No, the cache is in PhotoProvider instance.

    // Let's use a Consumer-like approach or just find the provider by type?
    // Since I can't add import easily in this chunk, I'll use a trick:
    // Pass the provider/cache method from the parent?
    // No, `_buildCard` is called from `build`.

    // I will rely on `PhotoProvider` being available in context.
    // I will add `import 'package:provider/provider.dart';` and `import '../providers/photo_provider.dart';` to the top of file in next step.

    final provider = context
        .watch<PhotoProvider>(); // Use watch to rebuild if cache updates?
    // Actually read is enough if we just want to check cache, but if we trigger a load we want to rebuild when it finishes.
    // But `getThumbnail` returns a Future.

    final cached = provider.getCachedThumbnail(asset.id);
    if (cached != null) {
      return Image.memory(cached, fit: BoxFit.cover);
    }

    return FutureBuilder<Uint8List?>(
      future: provider.getThumbnail(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: Colors.grey[900],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
