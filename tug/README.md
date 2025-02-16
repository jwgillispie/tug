# ValueAlign

A Flutter application that helps users track and align their daily activities with their core values.

## Project Structure

```
valuealign/
├── lib/                     # Flutter app source code
│   ├── blocs/              # BLoC state management
│   ├── models/             # Data models
│   ├── repositories/       # Data repositories
│   ├── screens/           # UI screens
│   ├── services/          # Business logic
│   ├── utils/             # Utilities
│   └── widgets/           # Reusable widgets
│
├── backend/               # FastAPI backend
│   ├── app/              # Backend application code
│   ├── tests/            # Backend tests
│   └── requirements.txt  # Python dependencies
│
├── test/                 # Flutter tests
├── assets/              # App assets
└── docs/               # Project documentation
```

## Getting Started

### Prerequisites
- Flutter 3.x
- Python 3.11+
- MongoDB 6.0+
- Firebase project

### Frontend Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/valuealign.git
cd valuealign
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Create `.env` file in project root:
```env
MONGODB_URL=your_mongodb_url
API_URL=your_api_url
```

4. Run the app:
```bash
flutter run
```

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Create and activate virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create `.env` file in backend directory:
```env
MONGODB_URL=your_mongodb_url
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
```

5. Run the server:
```bash
uvicorn main:app --reload
```

## Contributing

1. Create a new branch:
```bash
git checkout -b feature/your-feature-name
```

2. Make your changes and commit:
```bash
git add .
git commit -m "Description of changes"
```

3. Push to your branch:
```bash
git push origin feature/your-feature-name
```

4. Create a Pull Request

## Environment Setup

### Required Environment Variables

Frontend (.env):
```env
MONGODB_URL=mongodb://username:password@host:port/database
API_URL=http://localhost:8000
```

Backend (.env):
```env
MONGODB_URL=mongodb://username:password@host:port/database
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
```

## Documentation

- [Project Overview](docs/project-overview.md)
- [Architecture](docs/architecture.md)
- [API Documentation](docs/api-docs.md)
- [Testing Guide](docs/testing.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details