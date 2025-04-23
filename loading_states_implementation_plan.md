# Loading States Implementation Plan

## Bismillah ar-Rahman ar-Rahim

## Overview
The app currently has issues with loading states, causing a "flashing effect" where incorrect screens or UI elements are briefly shown before the correct ones are loaded. This plan outlines how to implement proper loading states to create a smooth user experience.

## Current Issues
1. Password screen: Shows "set new password" screen briefly before showing the login screen
2. AI guidance screen: Shows offline mode banner briefly before showing the correct service type

## Available Loading Indicators
1. `LoadingIndicator` in `lib/presentation/widgets/common/loading_indicator.dart`
2. `AppLoadingIndicator` in `lib/presentation/widgets/app_loading_indicator.dart`
3. Loading animation widgets from the `loading_animation_widget` package

## Implementation Plan

### 1. Auth Flow Improvements
- Modify `AuthProvider` to ensure loading state is properly managed
- Update `app.dart` to show a proper loading screen while determining auth status
- Ensure the correct screen is shown only after the auth state is fully loaded

### 2. AI Service Provider Improvements
- Update `AIServiceNotifier` to properly handle loading states
- Ensure the AI guidance screen shows a loading indicator while the service configuration is being loaded
- Prevent the offline banner from showing until the service type is confirmed

### 3. Create a Splash Screen
- Implement a proper splash screen that shows while the app is initializing
- Use this time to load necessary configurations and determine the auth state

### 4. Create a Loading Overlay Widget
- Create a reusable loading overlay widget that can be used throughout the app
- This widget should show a visually appealing loading animation

## Implementation Details

### 1. Auth Flow Improvements
- Update `AuthProvider` to set `isLoading` to true during initialization and authentication operations
- Modify `app.dart` to show a loading screen with a nice animation while determining auth status
- Only navigate to the appropriate screen after the auth state is fully loaded

### 2. AI Service Provider Improvements
- Update `AIServiceNotifier` to properly handle loading states during initialization
- Modify `ai_guidance_screen.dart` to show a loading indicator while the service configuration is being loaded
- Use a conditional rendering approach to only show UI elements when data is available

### 3. Create a Splash Screen
- Create a new `splash_screen.dart` file
- Implement a visually appealing splash screen with the app logo and a loading animation
- Use this screen as the initial route in the app

### 4. Create a Loading Overlay Widget
- Create a new `loading_overlay.dart` file
- Implement a reusable loading overlay widget that can be used throughout the app
- This widget should show a visually appealing loading animation from the `loading_animation_widget` package

## Testing Plan
1. Test the auth flow to ensure smooth transitions between screens
2. Test the AI guidance screen to ensure the correct service type is shown without flashing
3. Test the app startup to ensure the splash screen works correctly
4. Test various loading scenarios to ensure the loading overlay works correctly

## Implementation Order
1. Create the loading overlay widget
2. Update the auth flow
3. Update the AI service provider
4. Create the splash screen
