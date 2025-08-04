# Green Market - Developer Guide

## Overview
Green Market is an eco-friendly marketplace app built with Flutter and Firebase. This guide covers project structure, development workflow, and key logic.

## Project Structure
- `lib/models/` : Data models (Product, AppUser, Order, etc.)
- `lib/services/` : Business logic and Firebase integration
- `lib/providers/` : State management (Provider)
- `lib/screens/` : UI screens for buyer, seller, admin
- `lib/widgets/` : Reusable UI components
- `lib/utils/` : Utility functions (validation, security, error handling)
- `test/` : Unit and widget tests

## Development Workflow
1. **Clone the repo**
2. Run `flutter pub get`
3. Configure Firebase (`lib/firebase_options.dart`)
4. Run tests: `flutter test`
5. Start app: `flutter run`

## Key Logic & Comments
- All main classes and methods include docstring and inline comments explaining logic and parameters.
- Error handling uses `ErrorHandler` for dialogs/snackbars/logging.
- Security and validation handled in `security_utils.dart` and `validation_utils.dart`.
- UI widgets use responsive, accessible design and animation.

## Testing
- All business logic, UI, and edge cases covered by unit/widget tests in `test/`
- Run `flutter test` before every commit

## Contribution
- Follow code style and add docstring/comments for all new logic
- Write tests for new features
- Document changes in README and this guide

## Contact
- For questions, contact project owner or open an issue in the repo
