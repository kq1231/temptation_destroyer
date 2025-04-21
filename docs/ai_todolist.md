# AI Feature Enhancement Roadmap

## Core Architecture Improvements ✅
- [ ] **1. Remove Redundant AI Response Model** DONE
  - Delete AI Response Model file
  - Update all references to use Chat Message Model
  - Modify database schema to remove related tables
  - Update repository methods and providers

- [ ] **2. Rename "AI Guidance" to "AI Chat"** DONE
  - Global search/replace in codebase
  - Update UI strings and translations
  - Modify route names and navigation references
  - Update documentation and comments

## Chat Session Management
- [ ] **3. Implement Chat Sessions** DONE
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
  - Remove the AIServiceConfig model

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
- [ ] **7. Implement GPT Markdown Package** DONE
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

## Additional
- [ ] **Documentation Updates**
  - Update architecture diagrams
  - Add API key management flow documentation
  - Create encryption scheme documentation

- [ ] **Testing Plan**
  - Add unit tests for multi-key management
  - Implement encryption/decryption test cases
  - Add widget tests for new chat session UI

- [ ] **Humanize LLMS Context**
  - Make the language more approachable and empathetic
  - Use a conversational tone that's relatable and non-judgmental
  - Ensure the content is supportive and encouraging, not just informative

> If possible can you make the llms context a bit more humanistic and friendly/personal. This rn seems very ai ish. The words and sentences are way too perfect and formal to be able to make someone feel relaxed. Should definitely speak like a best friend who cares about you and is not just giving advice for advice

- Riverpod intitialization flow

- Work on EmergencyChat widget, Inshaa Allah

- Integrate VAPI into the app!

- API Error messages in the chats