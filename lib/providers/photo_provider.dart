import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetEntity> _assets = [];
  final Set<String> _idsToDelete = {};
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _hasPermission = false;

  List<AssetEntity> get assets => _assets;
  List<AssetEntity> get activeAssets =>
      _assets.where((a) => !_idsToDelete.contains(a.id)).toList();

  Set<String> get idsToDelete => _idsToDelete;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;

  AssetEntity? get currentAsset =>
      activeAssets.isNotEmpty && _currentIndex < activeAssets.length
      ? activeAssets[_currentIndex]
      : null;

  Future<void> fetchAssets() async {
    _isLoading = true;
    notifyListeners();

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    // isAuth returns true for authorized and limited (iOS)
    if (ps.isAuth || ps.hasAccess) {
      _hasPermission = true;
      // Fetch all photos, sorted by latest first
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (paths.isNotEmpty) {
        // Usually the first path is "Recent" or "All"
        final List<AssetEntity> entities = await paths[0].getAssetListRange(
          start: 0,
          end:
              10000, // Fetch a reasonable amount, or implement pagination later
        );
        _assets = entities;
      }
    } else {
      _hasPermission = false;
      // Only open settings if strictly denied, but for now let's just log
      debugPrint("Permission denied: $ps");
      // await openAppSettings(); // Optional: don't force open settings immediately loop
    }

    _isLoading = false;
    notifyListeners();
  }

  final Map<String, Uint8List> _thumbnailCache = {};
  final Map<String, Uint8List> _smallThumbnailCache = {};

  Uint8List? getCachedThumbnail(String id) => _thumbnailCache[id];
  Uint8List? getCachedSmallThumbnail(String id) => _smallThumbnailCache[id];

  Future<Uint8List?> getThumbnail(AssetEntity asset) async {
    if (_thumbnailCache.containsKey(asset.id)) {
      return _thumbnailCache[asset.id];
    }

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1080, 1920),
      quality: 90,
    );

    if (data != null) {
      _thumbnailCache[asset.id] = data;
    }
    return data;
  }

  Future<Uint8List?> getSmallThumbnail(AssetEntity asset) async {
    if (_smallThumbnailCache.containsKey(asset.id)) {
      return _smallThumbnailCache[asset.id];
    }

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 90,
    );

    if (data != null) {
      _smallThumbnailCache[asset.id] = data;
    }
    return data;
  }

  void markForDeletion(AssetEntity asset) {
    _idsToDelete.add(asset.id);

    // Adjust index if needed
    // If we deleted the last item, move back
    if (_currentIndex >= activeAssets.length) {
      _currentIndex = activeAssets.isNotEmpty ? activeAssets.length - 1 : 0;
    }
    // If we deleted an item before the current one (unlikely in this flow but possible), adjust
    // But for "Swipe Up" on current, the next item slides in, so index stays same.

    notifyListeners();
  }

  void undoMark(String id) {
    if (_idsToDelete.contains(id)) {
      _idsToDelete.remove(id);
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index == _currentIndex) return;
    if (index >= 0 && index < activeAssets.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> deleteMarkedAssets() async {
    if (_idsToDelete.isEmpty) return;

    final List<String> ids = _idsToDelete.toList();
    try {
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

      // Remove deleted assets from the local list
      _assets.removeWhere((asset) => result.contains(asset.id));
      _idsToDelete.clear();

      _currentIndex = 0;

      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting assets: $e");
      // Handle error
    }
  }

  // Helper to check if an asset is marked
  bool isMarked(String id) {
    return _idsToDelete.contains(id);
  }
}
