import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/Location/bookmark_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/connectivity_util.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late BookmarkProvider _bookmarkProvider;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isOffline = false;
  Map<String, Map<String, List<PlaceModel>>> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _bookmarkProvider = BookmarkProvider();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check connectivity
      final connectivityStatus = await ConnectivityUtils.getCurrentConnectivity();
      _isOffline = connectivityStatus.contains('No Internet');
      
      // Load bookmarks
      final bookmarks = await _bookmarkProvider.getBookmarkedPlacesHierarchy();
      
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
      
      debugPrint('Bookmarks loaded: ${_bookmarks.length} locations');
      for (var location in _bookmarks.keys) {
        debugPrint('Location: $location, Categories: ${_bookmarks[location]!.length}');
        for (var category in _bookmarks[location]!.keys) {
          debugPrint('  Category: $category, Places: ${_bookmarks[location]![category]!.length}');
        }
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _bookmarkProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Bookmarks',
              style: AppTypography.headline.copyWith(
                color: Colors.white,
                fontSize: 20,
              )),
          backgroundColor: AppColors.primary,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBookmarks,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Stack(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_hasError)
                _buildErrorState(context, _isOffline)
              else if (_bookmarks.isEmpty)
                _buildEmptyState(_isOffline)
              else
                RefreshIndicator(
                  onRefresh: _loadBookmarks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final location = _bookmarks.keys.elementAt(index);
                      final categories = _bookmarks[location]!;
                      return _buildLocationCard(context, location, categories);
                    },
                  ),
                ),
              
              if (_isOffline)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.orange.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'Offline Mode - Showing cached bookmarks',
                      style: AppTypography.caption
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isOffline) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOffline
                ? 'No internet connection\nShowing cached bookmarks'
                : 'Error loading bookmarks',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _loadBookmarks,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isOffline) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.bookmark_border,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOffline ? 'No cached bookmarks available' : 'No bookmarks yet',
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isOffline
                ? 'Connect to internet to see your bookmarks'
                : 'Start exploring and save your favorite places',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String location,
      Map<String, List<PlaceModel>> categories) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          gradient: const LinearGradient(
            colors: [Colors.white, AppColors.surfaceBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ExpansionTile(
          title: Text(
            location,
            style: AppTypography.subtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          leading: const Icon(Icons.location_city, color: AppColors.primary),
          initiallyExpanded: true, // Show categories by default
          children: categories.entries.map((category) {
            return _buildCategoryTile(context, category.key, category.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      BuildContext context, String category, List<PlaceModel> places) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: Icon(
        _getCategoryIcon(category),
        color: AppColors.primary,
      ),
      title: Text(
        category,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${places.length} ${places.length == 1 ? 'place' : 'places'}',
        style: AppTypography.caption,
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: const Icon(
          Icons.chevron_right,
          color: AppColors.primary,
        ),
      ),
      onTap: () {
        context.push('/locations/bookmarks/category', extra: {
          'category': category,
          'places': places,
        });
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurants':
        return Icons.restaurant;
      case 'attractions':
        return Icons.attractions;
      case 'hotels':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.place;
    }
  }
}