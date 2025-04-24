# 15 Common Mistakes in Flutter and Dart Development (and How to Avoid Them)

## 1. Memory Leaks from Missed Disposal

**Problem**: Not disposing resources like `AnimationController`, `TextEditingController`, `ScrollController`, `FocusNode`, and `StreamSubscription` that Dart's garbage collector doesn't automatically clean up.

**Solution**:
- Always implement `dispose()` method in `StatefulWidget` classes
- Cancel stream subscriptions with `cancel()`
- Remove listeners with `removeListener()`
- Use DCM's `dispose-fields` rule to detect these issues

**Findings in Our Codebase**:

Most of our StatefulWidget classes properly dispose of their resources. Here are some examples of good practices:

- `lib/presentation/screens/ai/ai_guidance_screen.dart`: Properly disposes `TextEditingController`, `ScrollController`, and `FocusNode` in the `dispose()` method.
- `lib/presentation/widgets/emergency_chat_widget.dart`: Correctly disposes `TextEditingController` and `ScrollController`.
- `lib/presentation/screens/auth/password_recovery_screen.dart`: Properly disposes multiple `TextEditingController` and `FocusNode` objects.
- `lib/presentation/widgets/aspirations/dua_input.dart`: Correctly disposes `FocusNode`.

Potential issues:

- `lib/core/services/vapi_service.dart`: Contains a `StreamSubscription<List<int>>? _audioSub` that is properly canceled in the `_stopArecord()` method, but we should ensure this method is always called when needed.
- `lib/presentation/screens/voice/voice_chat_screen.dart`: Initializes `VapiService` but doesn't explicitly dispose it. We should verify if the service's resources are properly cleaned up when the screen is disposed.

## 2. Unnecessary Rebuilds via `setState`

**Problem**: Misusing `setState()` leads to poor performance, unnecessary widget rebuilds, or runtime errors.

**Solution**:
- Isolate dynamic parts into their own widgets
- Avoid calling `setState()` within lifecycle methods like `initState` or `build`
- Check if widget is still mounted before calling `setState()` after async operations
- Use more targeted state management solutions like ValueNotifier or state management libraries

**Findings in Our Codebase**:

We found several instances where setState() could be improved:

1. **Missing mounted checks after async operations**:
   - `lib/presentation/widgets/hobby_suggestions_widget.dart`: The `_loadSuggestions()` method calls setState() after an await without checking if the widget is still mounted.
   - `lib/presentation/screens/voice/voice_chat_screen.dart`: Some methods like `_stopCall()` call setState() after async operations without consistently checking mounted.

2. **Good practices found**:
   - `lib/presentation/screens/triggers/trigger_form_screen.dart`: Properly checks `if (mounted)` before navigating after an async operation.
   - Most of our codebase uses Riverpod for state management, which avoids many setState-related issues.
   - We're using AsyncNotifier in many places which handles loading states properly.

3. **Recommendations**:
   - Add mounted checks to all setState calls after async operations
   - Consider using more StatelessWidget with Riverpod instead of StatefulWidget with setState
   - For simple UI state that doesn't affect the business logic, consider using ValueNotifier with ValueListenableBuilder

## 3. Deep Widget Trees & Excessive Rebuilds

**Problem**: Deeply nested or unbalanced widget trees can become a performance concern, especially when paired with unnecessary rebuilds.

**Solution**:
- Flatten widget structures where possible
- Use specific widgets instead of generic `Container` (e.g., `Padding`, `Align`)
- Mark widgets as `const` when possible
- Use `RepaintBoundary` to isolate frequently updated parts
- Extract repeated widget patterns into their own widget classes

**Findings in Our Codebase**:

Our codebase has a mix of well-structured and potentially problematic widget trees:

1. **Good practices**:
   - Many screens are broken down into smaller widget components (e.g., `lib/presentation/widgets/statistics/emergency_stats_widget.dart`)
   - We use dedicated widget files for reusable components
   - Most of our UI is organized by feature

2. **Areas for improvement**:
   - `lib/presentation/widgets/markdown/enhanced_markdown.dart`: The `_buildWithLatex` method contains complex conditional logic and widget building that could be extracted into smaller methods
   - `lib/presentation/screens/splash_screen.dart`: Contains duplicated gradient code in both `_buildLoadingScreen` and `_buildErrorScreen` that could be extracted
   - `lib/presentation/widgets/voice/voice_chat_messages.dart`: Has nested animations that could be extracted into a dedicated message item widget

3. **Recommendations**:
   - Extract complex UI building logic into separate methods or widgets
   - Create a shared gradient background widget for screens that use the same gradient
   - Use more `const` constructors for static UI elements
   - Consider using `RepaintBoundary` around frequently updating parts of the UI, especially in chat and voice interfaces

## 4. Poor Async Handling

**Problem**: Improper handling of asynchronous operations leads to memory leaks, uncaught errors, and UI inconsistencies.

**Solution**:
- Check `mounted` before calling `setState()` after async operations
- Properly handle errors in async code
- Use `await` with `try/catch` blocks
- Preserve stack traces when rethrowing exceptions
- Abstract common error handling patterns

**Findings in Our Codebase**:

Our codebase shows a mix of good and problematic async handling patterns:

1. **Good practices**:
   - Most of our providers using AsyncNotifier properly handle errors in try/catch blocks
   - `lib/presentation/providers/chat_async_notifier.dart` has comprehensive error handling for async operations
   - Many screens use Riverpod's AsyncValue.when pattern to handle loading, error, and data states

2. **Areas for improvement**:
   - `lib/presentation/widgets/hobby_suggestions_widget.dart`: The `_loadSuggestions()` method doesn't have error handling for its async operation
   - As mentioned in the setState section, some async operations don't check mounted before updating state
   - Some error messages are displayed directly from exceptions without formatting or user-friendly messages

3. **Recommendations**:
   - Add try/catch blocks to all async methods in StatefulWidget classes
   - Ensure all setState calls after async operations check the mounted property
   - Consider creating a common error handling utility for formatting error messages
   - Continue using Riverpod's AsyncValue pattern for handling async states consistently

## 5. Poor Images Optimization

**Problem**: Unoptimized images lead to increased memory consumption, slower load times, and larger app sizes.

**Solution**:
- Specify `cacheWidth` and `cacheHeight` for images
- Use `cached_network_image` package for network images
- Use vector graphics (SVG) for logos and icons
- Apply opacity directly to images instead of wrapping in `Opacity` widget
- Use DCM's `analyze-assets` command to identify oversized images

**Findings in Our Codebase**:

Our codebase has minimal image usage, which is good for performance, but there are still some areas for improvement:

1. **Limited image assets**:
   - The app primarily uses icon fonts (Material Icons) rather than image assets, which is good for performance
   - We have sound assets but very few image assets in the project

2. **Areas for improvement**:
   - No `cached_network_image` package is used, which would be important if we add network images in the future
   - App icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset` and `web/icons/` should be optimized if they aren't already
   - No `cacheWidth` and `cacheHeight` parameters are used in the few places where images might be loaded

3. **Recommendations**:
   - Add the `cached_network_image` package before implementing any features that load images from the network
   - Use SVG for any logos or icons that might be added in the future
   - Optimize app icons and splash screen images for different platforms
   - Consider using a tool like `flutter_gen` to generate type-safe asset references

## 6. Poor Error Handling

**Problem**: Relying on basic `try/catch` blocks or inconsistent patterns leads to silent failures and difficult debugging.

**Solution**:
- Always handle errors meaningfully instead of empty catch blocks
- Preserve stack traces when rethrowing exceptions
- Abstract common error handling patterns
- Use Dart's pattern matching for structured error handling
- Throw meaningful exception types

**Findings in Our Codebase**:

Our codebase shows a mix of good and problematic error handling patterns:

1. **Good practices**:
   - `lib/data/repositories/ai_repository.dart`: Has detailed error handling with specific exception types (AIServiceException) and meaningful error messages
   - `lib/core/services/vapi_service.dart`: Logs detailed error information including error type, message, and stack trace
   - Many AsyncNotifier providers properly handle errors and update state accordingly

2. **Areas for improvement**:
   - `lib/domain/usecases/challenge/get_active_challenges_usecase.dart`: Catches exceptions but returns an empty list without propagating the error, which could hide issues
   - Some error messages are displayed directly from exceptions without user-friendly formatting
   - Inconsistent error handling patterns across the codebase (some methods rethrow, others return empty results, others log and continue)

3. **Recommendations**:
   - Create a centralized error handling utility for consistent error formatting and logging
   - Ensure stack traces are preserved when rethrowing exceptions (use `rethrow` instead of `throw e`)
   - Consider creating custom exception types for different error categories
   - Add more user-friendly error messages instead of showing raw exception details
   - Avoid empty catch blocks or catch blocks that silently fail

## 7. Ineffective Testing

**Problem**: Tests without assertions, duplicate assertions, or incorrect matchers lead to false positives and missed bugs.

**Solution**:
- Ensure every test has meaningful assertions
- Avoid duplicate assertions in the same test
- Use appropriate test matchers instead of literal values
- Use `expectLater` for asynchronous tests
- Follow DCM's testing rules for better test quality

**Findings in Our Codebase**:

Our codebase has limited test coverage with some good practices but significant room for improvement:

1. **Good practices**:
   - `test/data/models/chat_session_model_test.dart`: Has comprehensive tests for the ChatSession model with multiple assertions
   - `test/core/security/secure_storage_service_test.dart`: Tests key functionality of the SecureStorageService
   - Tests use appropriate matchers like `equals()`, `isTrue`, `isFalse`, etc.

2. **Areas for improvement**:
   - Very limited test coverage overall - only a few test files exist
   - No widget tests for actual UI components (only a default counter test)
   - No integration tests for critical user flows
   - No mocking of dependencies in tests
   - No test coverage for providers, repositories, or use cases

3. **Recommendations**:
   - Create a test plan that prioritizes critical components and user flows
   - Add unit tests for all providers, especially AsyncNotifier providers
   - Add widget tests for key UI components
   - Implement integration tests for critical user journeys
   - Use mocking frameworks to isolate components during testing
   - Set up CI/CD with test coverage reporting

## 8. Package Overload

**Problem**: Adding too many packages increases app size, maintenance burden, and security risks.

**Solution**:
- Evaluate packages carefully before adding them
- Consider writing custom implementations for simple functionality
- Regularly audit and update dependencies
- Avoid packages with native dependencies unless necessary
- Be cautious with packages that encourage global access patterns

**Findings in Our Codebase**:

Our codebase has a moderate number of dependencies with some potential issues:

1. **Good practices**:
   - Core dependencies are well-organized by category (State Management, Local Database, Security, etc.)
   - Using established packages for critical functionality (Riverpod, ObjectBox, etc.)
   - Dev dependencies are appropriate for the development workflow

2. **Areas for improvement**:
   - Some packages have unspecified versions (using `any` for `just_audio`, `just_audio_media_kit`, and `media_kit_libs_linux`)
   - Multiple audio-related packages that may have overlapping functionality (flutter_tts, speech_to_text, audioplayers, just_audio)
   - Both `http` and `dio` packages for HTTP requests, which is redundant
   - Some packages may have native dependencies that increase app size and complexity

3. **Recommendations**:
   - Specify exact versions for all dependencies to ensure consistent builds
   - Evaluate if all audio-related packages are necessary or if some can be consolidated
   - Choose either `http` or `dio` as the primary HTTP client and remove the other
   - Regularly run `flutter pub outdated` to identify and update dependencies
   - Consider using dependency analysis tools to identify unused packages

## 9. Ignoring Screen Variability

**Problem**: Hardcoded dimensions, fixed paddings, and rigid layouts don't adapt to different screen sizes.

**Solution**:
- Avoid hardcoded dimensions
- Base layouts on screen dimensions using `MediaQuery`
- Use `LayoutBuilder` to adapt UI based on available space
- Leverage adaptive widgets like `Expanded`, `Flexible`, and `FractionallySizedBox`
- Test on various screen sizes and orientations

**Findings in Our Codebase**:

Our codebase has several instances of hardcoded dimensions and fixed layouts that could cause issues on different screen sizes:

1. **Good practices**:
   - `lib/presentation/widgets/chat/chat_message_bubble.dart`: Uses `MediaQuery` to set maximum width as a percentage of screen width
   - Many screens use `SingleChildScrollView` to handle content overflow
   - Consistent use of `const EdgeInsets.all()` and `symmetric()` for padding

2. **Areas for improvement**:
   - `lib/presentation/widgets/statistics/streak_counter_widget.dart`: Uses fixed width and height (80x80) for streak counters
   - `lib/presentation/widgets/emergency/emergency_widgets.dart`: Uses fixed width (100) for emergency action buttons
   - `lib/presentation/screens/splash_screen.dart`: Uses fixed sizes for icons and text without considering screen dimensions
   - `lib/presentation/widgets/emergency/floating_help_button.dart`: Uses hardcoded sizes (maxSize = 120.0, minSize = 70.0)
   - Many widgets use fixed `SizedBox` heights for spacing (8, 16, 24, etc.) instead of responsive spacing

3. **Recommendations**:
   - Use `MediaQuery` to scale dimensions based on screen size
   - Implement a responsive spacing system instead of fixed `SizedBox` heights
   - Use `LayoutBuilder` for widgets that need to adapt to their parent's constraints
   - Replace fixed-width containers with `Expanded`, `Flexible`, or percentage-based sizing
   - Test the app on various screen sizes and orientations to identify layout issues

## 10. Misusing `BuildContext`

**Problem**: Using `BuildContext` outside its valid scope leads to runtime exceptions or unpredictable behavior.

**Solution**:
- Check if widget is still mounted before using context after async operations
- Avoid using context in `initState()`
- Use `WidgetsBinding.instance.addPostFrameCallback` for context operations after initialization
- Don't store context for later use in other classes
- Use the closest context when multiple are available

**Findings in Our Codebase**:

Our codebase has a mix of good practices and potential BuildContext issues:

1. **Good practices**:
   - `lib/presentation/screens/splash_screen.dart`: Uses `WidgetsBinding.instance.addPostFrameCallback` for navigation after state changes
   - Most screens use Riverpod's ConsumerWidget or ConsumerStatefulWidget which helps avoid context issues
   - No instances of storing BuildContext for later use were found

2. **Areas for improvement**:
   - `lib/presentation/widgets/hobby_suggestions_widget.dart`: Calls setState() after async operations in `_loadSuggestions()` without checking if the widget is still mounted
   - `lib/presentation/widgets/emergency_chat_widget.dart`: Performs async operations in `didChangeDependencies()` without proper mounted checks
   - Some screens might be using context for navigation after async operations without checking mounted

3. **Recommendations**:
   - Add mounted checks before all setState calls after async operations
   - Use `WidgetsBinding.instance.addPostFrameCallback` for any context operations in initState
   - Consider using Riverpod's AsyncValue pattern more consistently to handle async state changes
   - Use Go Router or other navigation solutions that don't rely on BuildContext

## 11. Inefficient Code Structure

**Problem**: Mixing UI, state, and logic directly inside widgets makes code harder to test, debug, and scale.

**Solution**:
- Separate UI, logic, and state
- Extract complex widgets into smaller components
- Organize code by feature rather than just by type
- Use state management solutions to decouple UI from logic
- Use DCM's structure analysis to identify architectural issues

**Findings in Our Codebase**:

Our codebase shows a mix of good architectural patterns and some areas that could be improved:

1. **Good practices**:
   - Using Riverpod for state management, which helps separate UI from business logic
   - Following a layered architecture with data, domain, and presentation layers
   - Organizing code by feature rather than by type
   - Using dedicated provider files for state management

2. **Areas for improvement**:
   - `lib/presentation/widgets/emergency_chat_widget.dart`: Contains a lot of UI building, state management, and business logic in a single file (over 300 lines)
   - `lib/presentation/widgets/hobby_suggestions_widget.dart`: Mixes UI rendering with data fetching and navigation logic
   - `lib/presentation/screens/ai/ai_guidance_screen.dart`: Has many responsibilities including UI rendering, state management, and handling complex interactions
   - Some widgets have large build methods that could be broken down into smaller, more focused methods

3. **Recommendations**:
   - Break down large widget classes into smaller, more focused components
   - Extract business logic from widgets into dedicated service or utility classes
   - Move navigation logic to a centralized router or navigation service
   - Consider implementing a more strict separation between UI and business logic
   - Use more StatelessWidget components with Riverpod for state management

## 12. Improper Use of `GlobalKey`

**Problem**: Unnecessary use of `GlobalKey` introduces bugs, degrades performance, and signals architectural issues.

**Solution**:
- Avoid reusing keys across multiple widgets
- Don't store keys long-term or reference them outside the widget tree
- Use callbacks, controllers, or state managers instead when possible
- Consider refactoring if you find yourself needing many global keys

**Findings in Our Codebase**:

Our codebase has limited use of GlobalKey, which is generally a good sign:

1. **Good practices**:
   - Most widgets use Riverpod for state management instead of relying on GlobalKey
   - No instances of storing GlobalKey for later use outside the widget tree
   - No instances of reusing the same GlobalKey across multiple widgets

2. **Areas for improvement**:
   - `lib/presentation/widgets/challenge/challenge_form.dart`: Uses a GlobalKey<FormState> for form validation, which is a common pattern but could potentially be replaced with a more state-management focused approach
   - `lib/presentation/screens/triggers/trigger_form_screen.dart`: Also uses GlobalKey<FormState> for form validation
   - Some form screens might be using GlobalKey unnecessarily when Riverpod could handle the state

3. **Recommendations**:
   - Continue using Riverpod for business logic state management
   - For forms and animations, use local state with StatefulWidget when appropriate
   - Use GlobalKey<FormState> for form validation as needed - this is a standard pattern for forms in Flutter
   - Only use Riverpod for form state when the state needs to persist beyond the form's lifecycle

## 13. Abusing `FutureBuilder` & `StreamBuilder`

**Problem**: Creating new futures or streams on every rebuild causes repeated network calls, flickering, and memory leaks.

**Solution**:
- Store futures and streams in variables (e.g., in `initState()`)
- Don't create new async operations in the `build()` method
- Use DCM's rules to detect async calls in sync methods
- Consider more structured state management for complex async flows

**Findings in Our Codebase**:

Our codebase has limited use of FutureBuilder and StreamBuilder, with a mix of good and problematic patterns:

1. **Good practices**:
   - Most of the codebase uses Riverpod's AsyncValue pattern instead of FutureBuilder/StreamBuilder
   - `lib/presentation/providers/chat_async_notifier.dart`: Properly handles streaming responses with AsyncNotifier
   - `lib/data/repositories/ai_repository.dart`: Uses proper stream handling for AI responses

2. **Areas for improvement**:
   - `lib/presentation/widgets/daily_hadith_card.dart`: Creates a new future in the build method with `FutureBuilder<HadithModel?>(future: ref.watch(getDailyHadithUseCaseProvider).execute(),...)`
   - `lib/presentation/screens/hadith_management_screen.dart`: Also creates a new future in the build method
   - `lib/presentation/screens/ai/ai_settings_screen.dart`: Creates a new future in a dialog builder
   - `lib/presentation/widgets/hobby_suggestions_widget.dart`: Was using manual state management with StatefulWidget and async operations in initState

3. **Recommendations**:
   - Replace FutureBuilder instances with Riverpod's AsyncValue pattern
   - For any remaining FutureBuilder usage, store the future in a variable in initState() or didChangeDependencies()
   - Consider using AsyncNotifier for all async operations to handle loading, error, and data states consistently
   - Use Riverpod's .when() pattern for handling async states in the UI

4. **Improvements Made**:
   - Refactored `HobbySuggestionsWidget` from a StatefulWidget with manual loading state to a simpler ConsumerWidget
   - Created a dedicated `hobbySuggestionsProvider` using `FutureProvider.family` that takes a trigger ID
   - Used Riverpod's `.when()` pattern to handle loading, error, and data states in a clean way
   - Improved error handling with user-friendly error messages
   - Reduced boilerplate code by eliminating initState(), setState(), and manual state tracking

## 14. Improper Use of Widget Lifecycle Methods

**Problem**: Misusing lifecycle methods leads to performance issues, unexpected rebuilds, or runtime errors.

**Solution**:
- Don't access context-dependent APIs in `initState()`
- Use post-frame callbacks for context operations after initialization
- Guard expensive operations in `didChangeDependencies()`
- Properly implement `didUpdateWidget()` to respond to parameter changes
- Follow DCM's lifecycle-related rules

**Findings in Our Codebase**:

Our codebase shows a mix of good practices and some potential lifecycle method issues:

1. **Good practices**:
   - Most AsyncNotifier providers properly initialize state in their build method
   - `lib/presentation/screens/ai/ai_guidance_screen.dart`: Properly implements all lifecycle methods including didChangeDependencies
   - Most StatefulWidget classes properly implement dispose() to clean up resources
   - `lib/presentation/widgets/aspirations/dua_input.dart`: Correctly handles initialization and disposal of focus nodes

2. **Areas for improvement**:
   - `lib/presentation/widgets/hobby_suggestions_widget.dart`: Calls an async method directly in initState without using Future.microtask
   - `lib/presentation/widgets/emergency_chat_widget.dart`: Performs potentially expensive operations in didChangeDependencies without checking if dependencies actually changed
   - Some widgets don't implement didUpdateWidget() when they receive parameters that might change
   - Some StatefulWidget classes might be using initState for operations that should be in didChangeDependencies

3. **Recommendations**:
   - Implement didUpdateWidget() in widgets that receive parameters that might change
   - Move context-dependent operations from initState to didChangeDependencies
   - Use AsyncNotifier's build method for initialization rather than manual lifecycle management with Future.microTask in initState
   - Add checks in didChangeDependencies to only run expensive operations when dependencies actually change
   - For remaining StatefulWidget classes, ensure proper lifecycle method implementation

## 15. Unmaintained Code and Files

**Problem**: Unused code and files add weight to the codebase, slow down onboarding, and clutter pull requests.

**Solution**:
- Use DCM's `check-unused-code` to detect unused classes, methods, etc.
- Use `check-unused-files` to find entire unused Dart files
- Clean up unused localization keys with `check-unused-l10n`
- Detect code duplication with `check-code-duplication`
- Regularly audit and clean up the codebase

**Findings in Our Codebase**:

Our codebase has some potential unmaintained code and files:

1. **Good practices**:
   - Most of the codebase appears to be actively maintained
   - The project structure is well-organized by feature
   - The .gitignore file properly excludes generated files and build artifacts

2. **Areas for improvement**:
   - `lib/main.dart` contains an unused `MyApp` class that appears to be a remnant of the default Flutter template
   - `lib/data/models/islamic_content_model.dart` defines a model that might not be fully utilized in the application
   - Some repositories like `lib/data/repositories/hadith_repository.dart` might have methods that aren't being used
   - The codebase might have some commented-out code or TODO comments that need to be addressed

3. **Recommendations**:
   - Run a code coverage tool to identify unused code and files
   - Remove the unused `MyApp` class from `lib/main.dart`
   - Audit models and repositories to ensure they're actively used
   - Address TODO comments or convert them to GitHub issues for tracking
   - Consider implementing a regular code cleanup process as part of the development workflow
   - Use static analysis tools to identify dead code

## Conclusion

Most of these mistakes are preventable through better architectural decisions, smarter state management, and respecting Flutter's widget lifecycle. Tools like DCM can help catch these issues early by enforcing best practices and highlighting potential problems before they become serious.
