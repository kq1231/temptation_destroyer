# AI Feature Enhancement Roadmap

## Core Architecture Improvements ✅
- [ ] **1. Remove Redundant AI Response Model**
  - Delete AI Response Model file
  - Update all references to use Chat Message Model
  - Modify database schema to remove related tables
  - Update repository methods and providers

- [ ] **2. Rename "AI Guidance" to "AI Chat"**
  - Global search/replace in codebase
  - Update UI strings and translations
  - Modify route names and navigation references
  - Update documentation and comments

## Chat Session Management 🗣️
- [ ] **3. Implement Chat Sessions**
  - Create Chat Session Model with:
    - session_id (UUID)
    - title (generated from first message)
    - created_at
    - updated_at
  - Add relationship between ChatSession <> ChatMessage (1-to-many)
  - Implement UI for:
    - Creating new sessions
    - Listing historical sessions
    - Archiving/Deleting sessions
  - Add session selection to chat screen

## API Key Management 🔑
- [ ] **4. Enhance AI Service Configuration**
  - Modify AIServiceConfig model to store multiple keys:
    ```dart
    Map<AIServiceType, String> apiKeys
    ```
  - Update API Key Setup Screen to:
    - Show separate key entries for each provider
    - Handle simultaneous key storage
    - Add provider-specific rate limiting
  - Modify repository to handle multi-key encryption

## Security Enhancements 🔒
- [ ] **5. Implement Message Encryption**
  - Add encryption to ChatMessageModel content field
  - Modify existing encryption helper class to:
    - Use AES-256 with device-specific key
    - Handle encryption/decryption during DB operations
  - Add migration for existing message encryption
  - Implement fallback decryption mechanism

## Code Quality & Maintenance 🛠️
- [ ] **6. Replace Problematic Enums with Strings**
  - Identify all enum usage in models:
    - AIServiceType
    - ChatMessageType
    - ResponseStatus
  - Create string-based constants
  - Update serialization/deserialization logic
  - Add validation helpers for string values

## UI/UX Improvements ✨
- [ ] **7. Implement GPT Markdown Package**
  - Add `gpt_markdown` dependency
  - Replace current Markdown renderer in ChatMessageBubble
  - Add custom CSS styling for:
    - Code blocks
    - Tables
    - Warning/admonition blocks
  - Implement syntax highlighting support

- [ ] **8. Emergency Screen Integration**
  - Add floating AI chat button to EmergencyScreen
  - Fix timer implementation:
    - Persist timer state to database
    - Add periodic auto-save
    - Handle background operation
  - Implement emergency session recording:
    - Create EmergencySession model
    - Link to related chat sessions
    - Add crisis resolution tracking

## Additional Considerations
- [ ] **Documentation Updates**
  - Update architecture diagrams
  - Add API key management flow documentation
  - Create encryption scheme documentation

- [ ] **Testing Plan**
  - Add unit tests for multi-key management
  - Implement encryption/decryption test cases
  - Add widget tests for new chat session UI
