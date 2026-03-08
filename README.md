# ThinkFlow

**Voice-first task intelligence app for product managers.** Record your thoughts, let AI decompose them into structured projects with epics and subtasks.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web (Riverpod, GoRouter) |
| Backend | Firebase Cloud Functions (TypeScript) |
| AI | Gemini 1.5 Pro & Flash via Vertex AI |
| Database | Cloud Firestore |
| Auth | Firebase Auth (Google Sign-In) |
| Storage | Firebase Storage |
| Billing | Stripe Checkout |

## Project Structure

```
ThinkFlow/
├── app/                    # Flutter web app
│   └── lib/
│       ├── models/         # Data models
│       ├── services/       # Firebase service wrappers
│       ├── providers/      # Riverpod state management
│       ├── core/           # Router, theme, utilities
│       └── ui/             # Screens and widgets
├── functions/              # Cloud Functions (TypeScript)
│   └── src/
│       ├── shared/         # Admin SDK, Vertex AI, plan guard, prompts
│       ├── voice/          # Voice processing
│       ├── tasks/          # Subtask generation
│       ├── kb/             # Knowledge base ingestion & recalibration
│       └── stripe/         # Billing & webhooks
├── firestore.rules         # Security rules
├── storage.rules           # Storage access rules
└── firebase.json           # Firebase config
```

## Getting Started

```bash
# Flutter app
cd app
flutter pub get
flutter run -d chrome

# Cloud Functions
cd functions
npm install
npm run build
```

## Branching Strategy

- `main` — stable production release
- `dev` — active development / staging

## License

Private — All rights reserved.
