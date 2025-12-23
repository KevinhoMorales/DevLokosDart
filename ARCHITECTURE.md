# DevLokos Architecture Documentation

## Overview

DevLokos is a Flutter mobile application built with clean architecture principles, following the MVVM pattern with BLoC for state management. The app integrates Firebase Firestore for content metadata and YouTube API for video playback.

---

## Architecture Layers

### 1. **Presentation Layer** (UI)
- **Location**: `lib/screens/`, `lib/widgets/`
- **Responsibility**: User interface components and screens
- **Pattern**: BLoC pattern for state management
- **Key Components**:
  - `PodcastScreen` - Existing podcast content
  - `TutorialsScreen` - Tutorial videos with filtering
  - `AcademyScreen` - Structured courses
  - `EnterpriseScreen` - Services and contact form

### 2. **Domain Layer** (Business Logic)
- **Location**: `lib/bloc/`, `lib/models/`
- **Responsibility**: Business logic, state management, data models
- **Pattern**: BLoC (Business Logic Component)
- **Key Components**:
  - `TutorialBloc` - Tutorial state management
  - `AcademyBloc` - Course state management
  - `EnterpriseBloc` - Enterprise content state management
  - Data models: `Tutorial`, `Course`, `Service`, `PortfolioProject`, `ContactSubmission`

### 3. **Data Layer** (Data Access)
- **Location**: `lib/repository/`, `lib/services/`
- **Responsibility**: Data fetching, caching, external API integration
- **Pattern**: Repository pattern
- **Key Components**:
  - `TutorialRepository` - Firestore tutorial data access
  - `AcademyRepository` - Firestore course data access
  - `EnterpriseRepository` - Firestore enterprise data access
  - `YouTubeService` - YouTube API integration (existing)

---

## Data Flow

```
UI (Screen) 
  ↓ (dispatches events)
BLoC (State Management)
  ↓ (calls repository)
Repository (Data Access)
  ↓ (queries Firestore/API)
Firestore/YouTube API
  ↓ (returns data)
Repository (transforms to models)
  ↓ (returns models)
BLoC (emits states)
  ↓ (updates UI)
UI (rebuilds with new state)
```

---

## Folder Structure

```
lib/
├── bloc/
│   ├── tutorial/
│   │   ├── tutorial_bloc.dart
│   │   ├── tutorial_event.dart
│   │   ├── tutorial_state.dart
│   │   └── tutorial_bloc_exports.dart
│   ├── academy/
│   │   ├── academy_bloc.dart
│   │   ├── academy_event.dart
│   │   ├── academy_state.dart
│   │   └── academy_bloc_exports.dart
│   └── enterprise/
│       ├── enterprise_bloc.dart
│       ├── enterprise_event.dart
│       ├── enterprise_state.dart
│       └── enterprise_bloc_exports.dart
├── models/
│   ├── tutorial.dart
│   ├── course.dart
│   └── enterprise.dart
├── repository/
│   ├── tutorial_repository.dart
│   ├── academy_repository.dart
│   └── enterprise_repository.dart
├── screens/
│   ├── tutorials/
│   │   └── tutorials_screen.dart
│   ├── academy/
│   │   └── academy_screen.dart
│   └── enterprise/
│       └── enterprise_screen.dart
└── widgets/
    ├── tutorial_card.dart
    └── course_card.dart
```

---

## Key Architectural Decisions

### 1. **Separation of Concerns**
- **UI**: Only handles presentation and user interactions
- **BLoC**: Manages state and business logic
- **Repository**: Handles data access and transformation
- **Models**: Pure data classes with serialization

### 2. **State Management: BLoC Pattern**
- **Why**: Consistent with existing codebase, testable, scalable
- **Benefits**: 
  - Clear separation of business logic from UI
  - Easy to test business logic independently
  - Predictable state changes

### 3. **Data Storage Strategy**
- **Firestore**: Metadata (titles, descriptions, categories, etc.)
- **YouTube API**: Video playback only
- **Why**: 
  - Firestore provides flexible querying and filtering
  - YouTube handles video hosting and CDN
  - Separation allows independent scaling

### 4. **Repository Pattern**
- **Why**: 
  - Abstracts data source (can switch from Firestore to another DB)
  - Single responsibility: data access only
  - Easy to mock for testing

### 5. **Future-Ready Design**
- **Monetization**: `isPaid` and `price` fields in Course model
- **User Enrollment**: Structure ready for user progress tracking
- **Feature Flags**: Can be added via Firebase Remote Config
- **Scalability**: Clean architecture supports growth

---

## Firestore Collections

### Collections:
1. **tutorials** - Tutorial metadata
2. **courses** - Academy courses with nested modules/lessons
3. **services** - Enterprise services
4. **portfolio** - Portfolio projects
5. **contact_submissions** - Contact form submissions

See `FIRESTORE_EXAMPLES.md` for detailed document structures.

---

## Navigation Structure

```
MainNavigation (Bottom Navigation)
├── Podcast Tab (existing)
├── Tutorials Tab (new)
├── Academy Tab (new)
└── Enterprise Tab (new)
```

---

## Dependencies

### Core:
- `flutter_bloc` - State management
- `cloud_firestore` - Firestore database
- `firebase_core` - Firebase initialization
- `equatable` - Value equality for BLoC states/events

### UI:
- `cached_network_image` - Image caching
- `go_router` - Navigation

### YouTube:
- `youtube_player_flutter` - Video playback (existing)
- `http` - API calls (existing)

---

## Testing Strategy

### Unit Tests:
- BLoC logic (events → states)
- Repository methods
- Model serialization

### Widget Tests:
- Screen rendering
- User interactions
- State changes

### Integration Tests:
- End-to-end flows
- Firestore queries
- YouTube integration

---

## Future Enhancements

1. **User Authentication & Enrollment**
   - Track course progress
   - Save favorite tutorials
   - User profiles

2. **Monetization**
   - Paid courses
   - Subscription model
   - In-app purchases

3. **Analytics**
   - Track tutorial views
   - Course completion rates
   - User engagement metrics

4. **Offline Support**
   - Cache tutorials locally
   - Download courses for offline viewing

5. **Notifications**
   - New course announcements
   - Course reminders
   - Enterprise inquiry responses

---

## Best Practices

1. **Error Handling**: All repositories handle errors and throw exceptions
2. **Loading States**: All BLoCs emit loading states for better UX
3. **Caching**: Use `AutomaticKeepAliveClientMixin` to preserve screen state
4. **Code Reusability**: Shared widgets (cards, filters) for consistency
5. **Type Safety**: Strong typing throughout (no `dynamic` types)

---

## Security Considerations

1. **Firestore Rules**: Read-only for authenticated users, write-only for admins
2. **Contact Form**: Users can create submissions, but cannot read others
3. **API Keys**: YouTube API key stored in Firebase Remote Config (not in code)

---

## Performance Optimizations

1. **Lazy Loading**: Load content on-demand
2. **Pagination**: Implement pagination for large lists
3. **Image Caching**: Use `cached_network_image` for thumbnails
4. **State Preservation**: Keep screen state when switching tabs

---

## Maintenance Notes

- **Adding New Tutorials**: Add documents to `tutorials` collection in Firestore
- **Adding New Courses**: Add documents to `courses` collection with nested modules/lessons
- **Updating Services**: Modify `services` collection documents
- **Viewing Submissions**: Check `contact_submissions` collection (admin only)

---

## Contact & Support

For questions about the architecture or implementation, refer to:
- `FIRESTORE_EXAMPLES.md` - Firestore document structures
- Code comments in BLoC and repository files
- Flutter BLoC documentation: https://bloclibrary.dev/

