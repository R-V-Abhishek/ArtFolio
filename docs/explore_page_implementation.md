# Explore Page Implementation - Discovery-Focused Content

## Overview
Transformed the chronological feed into an **Explore page** that focuses on discovery through trending content, skills, and tools. This encourages users to discover new artists outside their immediate circle.

## Key Changes

### 1. **Post Model Enhancements** (`lib/models/post.dart`)
Added intelligent trending score calculations:

- **`trendingScore`**: Calculated based on:
  - Likes (1 point each)
  - Comments (3 points each - more valuable)
  - Shares (5 points each - most valuable)
  - Kudos (4 points each - professional feedback)
  - Views (0.1 points each)
  - Recency factor: Posts decay over time with exponential falloff

- **`isTrending`**: Boolean flag for posts with high engagement in the last 48 hours

- **`totalEngagement`**: Quick aggregate of all engagement metrics

### 2. **Trending Service** (`lib/services/trending_service.dart`)
New service providing discovery algorithms:

- **`sortByTrending()`**: Sort posts by trending score
- **`getTrendingPosts()`**: Get highly engaging posts from the last 7 days
- **`getDiverseTrendingPosts()`**: Curated mix of different skills and content types
- **`filterBySkills()`**: Filter content by skill tags
- **`getPopularSkills()`**: Extract most-used skills from trending content
- **`recommendByInterests()`**: Recommend posts based on user's skill interests

### 3. **Firestore Service Updates** (`lib/services/firestore_service.dart`)
Enhanced data fetching for exploration:

- **`getExplorePosts()`**: Fetch recent public posts (last 7 days) for trending analysis
- **`getPostsBySkills()`**: Fetch posts matching multiple skills (OR query simulation)

### 4. **Explore Screen** (`lib/screens/explore_screen.dart`)
Complete redesign of the discovery experience:

#### Features:
- **Three View Modes** (Tabs):
  - **Trending**: Most engaging posts from the last 7 days (sorted by trending score)
  - **Diverse**: Curated mix of different skills and content types
  - **Latest**: Chronological view of fresh content

- **Skill-Based Filtering**:
  - Horizontal scrollable chips showing popular skills
  - Multi-select filtering (posts must match at least one selected skill)
  - Clear filters button
  - Dynamic skill extraction from trending content

- **Discovery Header**:
  - Visual header for each view mode
  - Shows active filters
  - Provides context about the current view

- **Smart Fallback**:
  - Works offline with demo content
  - Graceful degradation when Firebase is unavailable

### 5. **Home Screen Updates** (`lib/screens/home_screen.dart`)
- Replaced `FeedScreen` with `ExploreScreen`
- Changed navigation label from "Feed" to "Explore"
- Updated icon from home to explore

## Benefits

### 🔍 Discovery-First Approach
- Users discover new artists based on content quality and relevance
- No need to follow users to see great content
- Algorithm surfaces trending and diverse content

### 🎯 Skill-Based Discovery
- Users can filter by specific skills (e.g., "Digital Art", "3D Modeling")
- Popular skills are automatically highlighted
- Easy to explore specific artistic disciplines

### 📈 Engagement-Driven
- Quality content surfaces naturally through engagement metrics
- Recent posts get priority through recency decay
- Multiple engagement types are weighted appropriately

### 🌈 Diverse Content
- "Diverse" mode ensures variety in content types and skills
- Prevents echo chambers
- Exposes users to different artistic styles

### ⚡ Performance
- Efficient queries with composite indexes
- Smart caching of popular skills
- Pull-to-refresh for latest content

## Algorithm Details

### Trending Score Formula
```
trendingScore = engagementScore × recencyFactor

where:
  engagementScore = (likes × 1) + (comments × 3) + (shares × 5) + (kudos × 4) + (views × 0.1)
  recencyFactor = 1.0 / (1.0 + ageInHours / 24.0)  [for posts < 7 days]
  recencyFactor = 0.1  [for posts > 7 days]
```

### Diversity Algorithm
The diverse view:
1. Takes top trending posts (2x the limit)
2. Selects one post from each unique skill/type combination
3. Fills remaining slots with highest trending
4. Ensures variety in content types and skills

## User Experience Flow

1. **Open App** → Lands on Explore tab (default)
2. **See Trending Tab** → Most engaging recent posts
3. **Browse Skill Filters** → Horizontal chips with popular skills
4. **Tap Skill** → Filter posts by that skill (can select multiple)
5. **Switch Tabs**:
   - **Diverse** → Mix of different content types
   - **Latest** → Chronological fresh content
6. **Pull to Refresh** → Get latest trending content

## Future Enhancements
- Personalized recommendations based on user's liked/saved posts
- Location-based discovery
- Collaborative filtering
- A/B testing different trending algorithms
- Time-range filters (24h, 7d, 30d, all-time)
- Category/content-type filters (images, videos, reels)

## Testing
The implementation includes:
- Offline fallback with demo content
- Timeout handling for slow connections
- Empty state handling
- Filter state management
- Tab state persistence

## Migration Notes
- Old `FeedScreen` is preserved for reference
- No breaking changes to data models
- All existing posts automatically get trending scores
- Backward compatible with existing Firebase structure
