# Category Manager

Flutter application for the **Local Hierarchical Category Manager** machine test. It uses JSONPlaceholder for user lookup and SQLite for persistent categories.

## Run

Use Flutter 3.44 or newer with an Android emulator, iOS simulator, or macOS target.

```sh
flutter pub get
flutter run
```

Enter a JSONPlaceholder user ID (for example, `1`) to log in. The app fetches that user's name, username, email, phone, website, and company from the API. JSONPlaceholder is a mock API, so the ID lookup is not password authentication.

Categories are stored on the device and remain after restarting the app. New categories are kept separate by user ID. Logging out does not delete them. Categories created before user scoping was added have no owner and remain visible to every ID so existing data is preserved.

## Features

- Create root categories and subcategories at any depth.
- Reject duplicate names under the same parent; allow the same name under different parents.
- Expand and collapse the hierarchy, with parent and child details.
- Search category names at any depth and show the complete path, parent, and direct children.
- Apply an optional result limit and navigate paginated results with page, page size, and total count.
- Show loading, validation, empty, and error states.

## Architecture

The project uses **feature based layered architecture**. Each feature groups its data models, providers, repository or service, and presentation widgets under `lib/features/`. Shared API configuration, database setup, theme, navigation, and widgets live in `lib/core/`.

Riverpod supplies dependencies and manages asynchronous login, category creation, and category queries. The UI reads provider state and displays loading, data, or errors. Dio requests JSONPlaceholder profiles. Category repositories handle validation and SQLite queries; widgets do not run SQL or HTTP requests.

SQLite (`sqflite`) provides durable local storage, transactions, foreign keys, and indexed parent lookups. A category has an ID, name, parent ID, and creation timestamp. The implementation also stores a normalized name for sibling uniqueness and a user ID to keep each user's categories separate. A null parent ID marks a root. The database is opened from sqflite's persistent database directory.

The tree loads direct children when a branch expands. A recursive SQLite query walks from each search result to its root to build the full path, so there is no fixed depth in the data model or search logic. Search matches names at any depth. The repository accepts an optional total result limit and one based page and page size; it returns the total matching count and page metadata. The UI pages large result sets instead of loading all rows at once.

## Verify

```sh
flutter analyze
flutter test
```
