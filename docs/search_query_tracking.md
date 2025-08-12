# Search Query Tracking Feature

This feature tracks user search queries when they click on search results and stores them in a Supabase database table.

## Database Setup

1. **Run the SQL script**: Execute the SQL commands in `docs/search_queries_table.sql` in your Supabase SQL editor to create the required table and functions.

2. **Table Structure**: The `search_queries` table includes:
   - `id`: UUID primary key
   - `username`: Username from the users table
   - `query_text`: The search query text
   - `result_type`: Type of result clicked ('location', 'place', 'history_search', 'suggested_search')
   - `result_name`: Name of the clicked result
   - `executed_at`: Timestamp when the query was executed

## How It Works

### Search Query Logging
- When a user searches and clicks on any result, the query is logged to the database
- Logging respects the user's privacy settings (only logs if search history is enabled)
- Different result types are tracked:
  - `location`: City/location results
  - `place`: Restaurant/hotel/place results
  - `history_search`: Clicks on search history items
  - `suggested_search`: Clicks on suggested searches

### Privacy Considerations
- Only logs searches if the user has search history enabled in preferences
- Uses username instead of UID for better data organization
- Includes Row Level Security (RLS) policies to protect user data

### Components Added

1. **SearchService** (`lib/services/search_service.dart`):
   - Handles all database operations for search queries
   - Includes privacy checks and error handling
   - Provides methods for analytics (future use)

2. **SearchProvider Updates** (`lib/provider/MainScreen/search_provider.dart`):
   - Added `logSearchQuery()` method
   - Integrates with SearchService

3. **Search Page Updates** (`lib/screens/MainScreens/Explore/search_page_screen.dart`):
   - Updated all click handlers to log search queries
   - Maintains existing functionality while adding logging

## Usage

The feature works automatically once implemented. Every time a user:
1. Searches for something
2. Clicks on a search result
3. Has search history enabled in preferences

The search query will be logged to the database with details about what they searched for and what result they clicked on.

## Future Enhancements

The database structure supports future analytics features:
- Popular searches tracking
- User search behavior analytics
- Search result effectiveness metrics
- Personalized search suggestions

## Error Handling

- All database operations are wrapped in try-catch blocks
- Failures in logging don't affect the user experience
- Debug logs help with troubleshooting

## Performance

- Minimal impact on app performance
- Async operations don't block UI
- Indexed database queries for fast analytics
