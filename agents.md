# Habit Tracker: Guidelines and Standards for Coding Agents

This document defines the architecture, design standards, and coding conventions for the Habit Tracker application. Any subsequent development agent or Gemini session must strictly adhere to these practices.

---

## 1. Technology Stack

### Backend (`apps/backend`)
- **Framework**: NestJS (TypeScript)
- **Database Access**: TypeORM with PostgreSQL
- **Key Concepts**: Clean Controller-Service-Repository separation, JWT-based auth, dynamic score/XP tracking.

### Mobile Client (`apps/mobile_app`)
- **Framework**: Flutter (Dart)
- **Theme/Colors**: Premium dynamic themes (Dark/Light mode) controlled using `AppColors`.
- **Sizing**: `flutter_screenutil` (utilizing `.h`, `.w`, `.r`, `.sp` extensions) is used to ensure size scalability.

---

## 2. Layout and Responsive Design Standards
To prevent UI clipping and `RenderFlex overflow` issues across varying device shapes, resolutions, and font-scaling parameters:

- **Avoid Tight Bounding Boxes**: Do not wrap dynamically sized contents (like custom lists, columns with text, or badge rows) in fixed-size height widgets (e.g., hardcoded `SizedBox(height: 160.h)`) unless you are certain the content is strictly bounded and non-text-scaling.
- **Natural Constraints**: Prefer letting rows, columns, and list layouts wrap their content. Use `mainAxisSize: MainAxisSize.min` for column/row alignment where appropriate.
- **CrossAxisAlignment Alignment**: For bottom-aligned rows (like podiums or custom graphs), omit the height bounds of the row container. Let the tallest column define the row height naturally, and use `crossAxisAlignment: CrossAxisAlignment.end` in the parent `Row` to align children to the bottom.

---

## 3. Database Pagination Standards
To maintain high performance and prevent memory/latency degradation as the user database grows:

- **Database-Level Pagination**: All list-fetching endpoints (e.g., Leaderboards, global Feeds, Search results) must accept optional pagination query parameters: `page` (default 1) and `limit` (default 20).
- **No Full Scans**: Do not fetch all records into NestJS memory and sort/slice them. Pagination sorting and bounds must be enforced in the SQL query using `.limit(limit).offset(offset)` (or SQL `LIMIT`/`OFFSET`).
- **Deferred Relation Fetching**: Do not load complex relations (e.g. goal achievements, weekly missions, streak details) for the entire user database. Fetch the base entities for the current page first, extract their IDs, and then load the metadata solely for that page's subset (e.g., 20 users).

---

## 4. Mobile Client Infinite Scrolling Standard
When displaying paginated lists in Flutter:

- **State Management**: Maintain pagination states in the widget state:
  - `page`: Current page loaded (starts at 1).
  - `hasMore`: Boolean flag indicating if more data is available on the backend (set to `false` when a fetched page returns fewer items than the `limit`).
  - `loadingMore`: Boolean flag indicating if a request for the next page is currently active.
- **Scroll Listening**: Attach a `ScrollController` listener to the scrolling view (e.g., `SingleChildScrollView` or `ListView`):
  ```dart
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }
  ```
- **List Appending**: When loading page 2+, append newly returned entries to the existing tab/list data cache: `_tabData[tab]!.addAll(newEntries)`.
- **Loading Indicators**: Always display a Centered `CircularProgressIndicator` inside a padded block at the bottom of the list when `loadingMore` is `true`.

---

## 5. Skeleton Loading Standard
To ensure a premium user experience and prevent sudden layout shifts (CLS) when data fetches complete:

- **Shimmer Effects**: Use `flutter_animate` to create consistent shimmering shapes:
  ```dart
  Widget _buildSkeletonBox({double? width, double height = 16}) {
    return Container(width: width, height: height, ...)
      .animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1200.ms, color: shimmerColor);
  }
  ```
- **Layout Mirroring**: The structural layout of the skeleton loading state must mirror the final loaded list items exactly.
  - **Identical Dimensions**: Use the same exact width and height parameters (e.g. `55.w` for podium bars, `44.r` for avatar circles) as the loaded widgets.
  - **Identical Padding & Alignment**: Do not use generic structures. The skeleton rows/columns must share the same alignments (`mainAxisSize`, `crossAxisAlignment`, and list margins) as the real UI pages.

