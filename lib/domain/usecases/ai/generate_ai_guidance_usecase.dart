import 'package:temptation_destroyer/data/models/ai_models.dart';

import '../../../data/repositories/ai_repository.dart';

/// Use case for generating AI guidance responses
class GenerateAIGuidanceUseCase {
  final AIRepository _aiRepository;

  GenerateAIGuidanceUseCase(this._aiRepository);

  /// Execute the use case to generate an AI response
  ///
  /// [userInput] is the user's message to respond to
  /// [context] is optional additional context
  Future<String> execute(String userInput, {String? context}) async {
    try {
      // Call the repository to generate the response
      final aiResponse = await _aiRepository.generateResponse(
        userInput: userInput,
        context: context != null
            ? [ChatMessageModel(content: context, isUserMessage: false)]
            : [],
      );

      return aiResponse.content;
    } catch (e) {
      // If there's an error, return a fallback response
      return "I apologize, but I'm having trouble generating a response right now. "
          "This could be due to connectivity issues or service limitations. "
          "Please try again later, or consider using the offline guidance available in the app.";
    }
  }
}
