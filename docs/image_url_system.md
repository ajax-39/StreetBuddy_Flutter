# Image URL Expiration and Refresh System

## Overview
The Street Buddy app now includes a robust system for handling Google Places image URLs that expire after some time. This system automatically detects expired or invalid URLs and refreshes them seamlessly in the background.

## Key Components

### 1. SmartImageWidget (`lib/widgets/smart_image_widget.dart`)
- **Purpose**: A drop-in replacement for `Image.network` and `CachedNetworkImage` that automatically handles URL expiration
- **Features**:
  - Automatic URL validation before loading
  - Seamless URL refresh when expired
  - Fallback to default images when needed
  - Caching of refreshed URLs
  - Background refresh capability

### 2. ImageUrlService (`lib/services/image_url_service.dart`)
- **Purpose**: Core service for managing image URL lifecycle
- **Features**:
  - URL expiration detection
  - Google Places API integration for URL refresh
  - Supabase database updates for new URLs
  - Batch validation and refresh operations
  - Background task support

### 3. BackgroundTaskService (`lib/services/background_task_service.dart`)
- **Purpose**: Periodic maintenance of image URLs
- **Features**:
  - Runs every 6 hours automatically
  - Validates and refreshes expired URLs
  - Batch processing for efficiency
  - Error handling and logging

### 4. ImageUrlProvider (`lib/provider/image_url_provider.dart`)
- **Purpose**: Provider pattern integration for the ImageUrlService
- **Features**:
  - Dependency injection throughout the app
  - State management for URL operations
  - Error handling and UI feedback

## Database Schema Updates

### Places Table
```sql
ALTER TABLE places ADD COLUMN photo_cached_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE places ADD COLUMN photo_expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE places ADD COLUMN photo_refresh_count INTEGER DEFAULT 0;
ALTER TABLE places ADD COLUMN photo_last_error TEXT;
```

### Locations Table
```sql
ALTER TABLE locations ADD COLUMN photo_cached_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE locations ADD COLUMN photo_expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE locations ADD COLUMN photo_refresh_count INTEGER DEFAULT 0;
ALTER TABLE locations ADD COLUMN photo_last_error TEXT;
```

## Usage

### Basic Usage
Replace any `Image.network` or `CachedNetworkImage` with `SmartImageWidget`:

```dart
// Before
Image.network(
  place.photoUrl,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) => fallbackWidget,
)

// After
SmartImageWidget(
  imageUrl: place.photoUrl,
  fit: BoxFit.cover,
  placeholder: fallbackWidget,
)
```

### Advanced Usage with Custom Refresh
```dart
SmartImageWidget(
  imageUrl: place.photoUrl,
  fit: BoxFit.cover,
  placeholder: fallbackWidget,
  enableAutoRefresh: true,
  refreshTimeoutMinutes: 30,
)
```

## Files Updated

### Core Implementation
- `lib/services/image_url_service.dart` - Main service implementation
- `lib/widgets/smart_image_widget.dart` - UI component
- `lib/provider/image_url_provider.dart` - Provider pattern integration
- `lib/services/background_task_service.dart` - Background maintenance

### Database
- `lib/database/migrations/add_image_expiration_fields.sql` - Schema updates
- `lib/models/place.dart` - Updated model with expiration fields
- `lib/models/location.dart` - Updated model with expiration fields

### UI Integration
- `lib/widgets/place_card.dart` - Updated to use SmartImageWidget
- `lib/screens/MainScreens/Locations/location_details_screen.dart` - Updated
- `lib/screens/MainScreens/Locations/explore_places_detail_screen.dart` - Updated
- `lib/widgets/guide_card_widget.dart` - Updated
- `lib/widgets/explore_place_card.dart` - Updated

### App Integration
- `lib/main.dart` - Background task initialization
- `lib/services/location_services.dart` - Google Places API integration

## How It Works

1. **URL Validation**: When `SmartImageWidget` loads an image, it first checks if the URL needs refresh
2. **Background Refresh**: If URL is expired or invalid, it triggers a background refresh
3. **Seamless Loading**: While refreshing, the widget shows a placeholder or cached version
4. **Database Update**: New URLs are saved to Supabase with expiration metadata
5. **Periodic Maintenance**: Background service runs every 6 hours to proactively refresh URLs

## Benefits

1. **User Experience**: No more broken images or loading failures
2. **Performance**: Cached URLs reduce API calls and improve loading times
3. **Reliability**: Automatic recovery from expired URLs
4. **Maintainability**: Centralized URL management system
5. **Scalability**: Batch operations and background processing

## Configuration

### Environment Variables
- `GOOGLE_PLACES_API_KEY`: Required for URL refresh
- `SUPABASE_URL`: Database connection
- `SUPABASE_ANON_KEY`: Database authentication

### Customization
- URL expiration time: Default 24 hours (configurable)
- Background refresh interval: Default 6 hours (configurable)
- Batch size for operations: Default 50 items (configurable)

## Future Enhancements

1. **Image Optimization**: Compress and resize images for better performance
2. **CDN Integration**: Store refreshed images in CDN for faster loading
3. **Analytics**: Track URL refresh patterns and failure rates
4. **Caching Strategy**: Implement more sophisticated caching mechanisms
5. **Offline Support**: Cache images locally for offline access

## Testing

The system has been tested with:
- Expired Google Places URLs
- Invalid URLs
- Network connectivity issues
- Database failures
- Background task execution

All image displays in the app now use the robust `SmartImageWidget` system for reliable image loading.
