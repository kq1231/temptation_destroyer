import 'package:objectbox/objectbox.dart';

/// UserModel entity for storing user authentication data
///
/// This model stores the user's authentication information such as
/// hashed password, security questions, and API key for AI services.
@Entity()
class User {
  /// Unique identifier for the user
  @Id()
  int id = 0;

  /// Hashed password for authentication
  @Property()
  String hashedPassword;

  /// Optional salt for password hashing
  @Property()
  String? passwordSalt;

  /// Last login date
  @Property(type: PropertyType.date)
  DateTime? lastLoginDate;

  /// Security questions for password recovery (stored as JSON string)
  @Property()
  String? securityQuestions;

  /// Recovery codes for password reset (stored as JSON string)
  @Property()
  String? recoveryCodes;

  /// Custom API key for AI services
  @Property()
  String? customApiKey;

  /// API service type (e.g., OpenAI, Anthropic)
  @Property()
  String? apiServiceType;

  /// Flag to determine if this is the first login
  @Property()
  bool isFirstLogin;

  /// Count of failed recovery attempts
  @Property()
  int failedRecoveryAttempts;

  /// Timestamp of last failed recovery attempt
  @Property(type: PropertyType.date)
  DateTime? lastFailedRecoveryAttempt;

  /// Constructor
  User({
    this.id = 0,
    required this.hashedPassword,
    this.passwordSalt,
    this.lastLoginDate,
    this.securityQuestions,
    this.recoveryCodes,
    this.customApiKey,
    this.apiServiceType,
    this.isFirstLogin = true,
    this.failedRecoveryAttempts = 0,
    this.lastFailedRecoveryAttempt,
  });
}
