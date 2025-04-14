/// App string constants
class AppStrings {
  /// Private constructor to prevent instantiation
  AppStrings._();

  // App-wide strings
  static const String appName = 'Temptation Destroyer';
  static const String appSlogan =
      'Strength through struggle, victory through persistence';

  // General UI strings
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String ok = 'OK';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';
  static const String settings = 'Settings';
  static const String helpButtonText = 'HELP NOW';
  static const String cancelButtonText = 'Cancel';
  static const String startSessionButtonText = 'Start Emergency Session';

  // Authentication strings
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String createPassword = 'Create Password';
  static const String enterPassword = 'Enter Password';
  static const String passwordMismatch = 'Passwords do not match';
  static const String passwordTooShort = 'Password is too short';
  static const String securityWarning = 'Important Security Notice';
  static const String securityWarningMessage =
      'Your data is protected by this password. If you forget it, your data cannot be recovered. Please write it down in a safe place.';
  static const String typeToConfirm = 'Type "I understand" to confirm';
  static const String forgotPassword = 'Forgot Password';
  static const String resetPassword = 'Reset Password';
  static const String passwordUpdated = 'Password Updated Successfully';

  // Emergency response strings
  static const String emergencyDialogTitle = 'Need help right now?';
  static const String emergencyDialogContent =
      'We\'ll start an emergency session to help you through this. Stay strong, you can do this!';
  static const String emergencyScreenTitle = 'Emergency Response';
  static const String emergencyTimerLabel = 'Time Since Activating Help';
  static const String endSessionButtonText = 'End Session';
  static const String endSessionDialogTitle = 'End Emergency Session';
  static const String endSessionDialogContent =
      'How did this session go? Your honest answers help us improve your experience.';
  static const String successQuestion = 'Were you successful in resisting?';
  static const String sessionNotesHint = 'What happened? (Optional)';
  static const String sessionHelpfulStrategiesHint =
      'What helped you? (Optional)';
  static const String intensityQuestion = 'How intense was the temptation?';
  static const String lowIntensity = 'Low';
  static const String mediumIntensity = 'Medium';
  static const String highIntensity = 'High';
  static const String veryHighIntensity = 'Very High';
  static const String emergencyTipsHeading = 'Emergency Tips';
  static const String emergencyActionsHeading = 'Quick Actions';

  // Trigger management strings
  static const String triggers = 'Triggers';
  static const String addTrigger = 'Add Trigger';
  static const String editTrigger = 'Edit Trigger';
  static const String deleteTrigger = 'Delete Trigger';
  static const String triggerDescription = 'Description';
  static const String triggerType = 'Type';
  static const String triggerIntensity = 'Intensity (1-10)';
  static const String triggerTime = 'Time of Day';
  static const String triggerLocation = 'Location';
  static const String triggerEmotion = 'Emotional State';
  static const String triggerSocial = 'Social Situation';
  static const String triggerCustom = 'Custom';
  static const String triggerNotes = 'Additional Notes';
  static const String noTriggersAdded = 'No triggers added yet';
  static const String addFirstTrigger =
      'Add your first trigger to better understand your patterns';

  // Statistics and progress strings
  static const String statistics = 'Statistics';
  static const String progress = 'Progress';
  static const String currentStreak = 'Current Streak';
  static const String bestStreak = 'Best Streak';
  static const String totalSessions = 'Total Sessions';
  static const String successRate = 'Success Rate';
  static const String days = 'Days';
  static const String hours = 'Hours';
  static const String minutes = 'Minutes';
  static const String seconds = 'Seconds';
  static const String today = 'Today';
  static const String week = 'This Week';
  static const String month = 'This Month';
  static const String year = 'This Year';
  static const String allTime = 'All Time';

  // Error messages
  static const String errorGeneric = 'Something went wrong';
  static const String errorNoInternet = 'No internet connection';
  static const String errorTimeout = 'Request timed out';
  static const String errorAuthentication = 'Authentication failed';
  static const String errorPermission = 'Permission denied';
  static const String errorStorage = 'Storage error';
}
