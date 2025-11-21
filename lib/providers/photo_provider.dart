import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  DateTime? _startDate;
  DateTime? _endDate;

  List<AssetPathEntity> get albums => _albums;
  AssetPathEntity? get selectedAlbum => _selectedAlbum;

  Future<void> fetchAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) {
      _hasPermission = true;
      _albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      notifyListeners();
    } else {
      _hasPermission = false;
    }
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setAlbumFilter(AssetPathEntity? album) {
    _selectedAlbum = album;
    notifyListeners();
  }

  Future<void> fetchAssets() async {
    _isLoading = true;
    notifyListeners();

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) {
      _hasPermission = true;

      // 1. Construct Filter
      final FilterOptionGroup filter = FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      );

      if (_startDate != null && _endDate != null) {
        filter.createTimeCond = DateTimeCond(min: _startDate!, max: _endDate!);
      }

      // 2. Fetch Paths (Albums) with Filter
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filter,
      );

      if (paths.isNotEmpty) {
        // 3. Determine Target Album
        AssetPathEntity targetPath = paths[0]; // Default to Recent

        if (_selectedAlbum != null) {
          // Try to find selected album in the new list
          try {
            targetPath = paths.firstWhere((p) => p.id == _selectedAlbum!.id);
          } catch (_) {
            // Fallback to Recent
            targetPath = paths[0];
          }
        }

        // 4. Fetch Assets
        final List<AssetEntity> entities = await targetPath.getAssetListRange(
          start: 0,
          end: 10000,
        );
        _assets = entities;
        _currentIndex = 0; // Reset index to avoid RangeError
      } else {
        _assets = [];
        _currentIndex = 0;
      }
    } else {
      _hasPermission = false;
      debugPrint("Permission denied: $ps");
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

  // Tutorial State
  bool _showTutorial = false;
  bool get showTutorial => _showTutorial;

  Future<void> checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _showTutorial = !(prefs.getBool('hasSeenTutorial') ?? false);
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    _showTutorial = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
  }

  // Helper to check if an asset is marked
  bool isMarked(String id) {
    return _idsToDelete.contains(id);
  }
}
