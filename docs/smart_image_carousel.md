# Smart Image Carousel Widget

## Overview

The `SmartImageCarousel` widget provides intelligent image loading and display with carousel functionality for multiple images. It automatically handles expired Google Places image URLs and refreshes them in the background.

## Features

- 🔄 **Auto-refresh**: Automatically refreshes expired image URLs
- 📱 **Responsive**: Works with single or multiple images
- 🎠 **Carousel**: Beautiful carousel slider for multiple images
- 🔍 **Full-screen viewer**: Tap to view images in full-screen mode
- 📊 **Smart indicators**: Shows current image position and total count
- ⚡ **Cached images**: Uses CachedNetworkImage for optimal performance
- 🎨 **Customizable**: Configurable indicators, auto-play, and styling

## Usage

### Basic Usage

```dart
// For places
SmartImageCarousel.fromPlace(
  place: placeModel,
  height: 300,
  fit: BoxFit.cover,
)

// For locations
SmartImageCarousel.fromLocation(
  location: locationModel,
  height: 300,
  fit: BoxFit.cover,
)

// For custom URLs
SmartImageCarousel.fromUrls(
  imageUrls: ['url1', 'url2', 'url3'],
  height: 300,
  fit: BoxFit.cover,
)
```

### Advanced Usage

```dart
SmartImageCarousel.fromPlace(
  place: placeModel,
  height: 300,
  fit: BoxFit.cover,
  showIndicators: true,
  autoPlay: true,
  autoPlayInterval: Duration(seconds: 3),
  showImageCount: true,
  enableTapToView: true,
  borderRadius: 12,
  showErrorDetails: true,
  onImageTap: () {
    // Custom tap handler
    print('Image tapped!');
  },
)
```

### In Detail Screen

```dart
Widget _buildImageHeader() {
  return SizedBox(
    width: double.infinity,
    child: AspectRatio(
      aspectRatio: 1,
      child: SmartImageCarousel.fromPlace(
        place: widget.place,
        fit: BoxFit.cover,
        showErrorDetails: true,
        showIndicators: true,
        autoPlay: false,
        borderRadius: 0,
      ),
    ),
  );
}
```

## Properties

| Property           | Type               | Default        | Description                        |
| ------------------ | ------------------ | -------------- | ---------------------------------- |
| `place`            | `PlaceModel?`      | `null`         | Place model to load images from    |
| `location`         | `LocationModel?`   | `null`         | Location model to load images from |
| `imageUrls`        | `List<String>?`    | `null`         | Direct image URLs to display       |
| `height`           | `double?`          | `null`         | Height of the carousel             |
| `fit`              | `BoxFit`           | `BoxFit.cover` | How images should be fitted        |
| `borderRadius`     | `double`           | `0`            | Border radius for images           |
| `showIndicators`   | `bool`             | `true`         | Show dot indicators                |
| `autoPlay`         | `bool`             | `false`        | Enable auto-play                   |
| `autoPlayInterval` | `Duration`         | `5 seconds`    | Auto-play interval                 |
| `showImageCount`   | `bool`             | `true`         | Show image count overlay           |
| `enableTapToView`  | `bool`             | `true`         | Enable tap-to-view full-screen     |
| `showErrorDetails` | `bool`             | `false`        | Show error details                 |
| `onImageTap`       | `VoidCallback?`    | `null`         | Custom tap handler                 |
| `carouselOptions`  | `CarouselOptions?` | `null`         | Custom carousel options            |

## Implementation Details

### Auto-refresh Logic

The widget automatically detects expired image URLs and refreshes them in the background using the `ImageUrlService`. This ensures that users always see valid images even after Google Places API photo references expire.

### Error Handling

- Network errors are handled gracefully with retry logic
- Expired URLs are automatically refreshed
- Fallback to default images when no valid URLs are available
- Optional error details display for debugging

### Performance Optimizations

- Uses `CachedNetworkImage` for efficient image caching
- Lazy loading of images
- Background refresh to avoid blocking UI
- Validation cache to prevent repeated URL checks

## Full-Screen Viewer

The widget includes a built-in full-screen image viewer that opens when users tap on images. Features:

- Pinch-to-zoom functionality
- Swipe navigation between images
- Dot indicators with tap-to-jump
- Image counter display
- Smooth transitions and animations

## Migration from SmartImageWidget

If you're currently using `SmartImageWidget`, you can easily migrate:

```dart
// Old
SmartImageWidget.fromPlace(
  place: widget.place,
  fit: BoxFit.cover,
)

// New
SmartImageCarousel.fromPlace(
  place: widget.place,
  fit: BoxFit.cover,
)
```

The carousel automatically handles both single and multiple images, so no additional changes are needed.
