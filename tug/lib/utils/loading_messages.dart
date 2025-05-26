import 'dart:math';

class LoadingMessages {
  static final Random _random = Random();

  // General loading messages
  static const List<String> _general = [
    'tugging on some data...',
    'aligning the cosmic forces...',
    'calculating your awesomeness...',
    'brewing some digital magic...',
    'summoning the quantum particles...',
    'consulting the value oracle...',
    'spinning up the hamster wheels...',
    'asking the universe nicely...',
    'untangling the cosmic strings...',
    'polishing the quantum bits...',
    'calibrating the awesome meter...',
    'loading pixels with love...',
    'downloading more RAM... just kidding!',
    'convincing electrons to behave...',
    'negotiating with the servers...',
  ];

  // Authentication specific messages
  static const List<String> _auth = [
    'verifying your magnificence...',
    'checking if you\'re really you...',
    'consulting the identity matrix...',
    'validating your cosmic signature...',
    'authenticating your awesomeness...',
    'confirming you\'re not a robot... probably...',
    'checking your vibe credentials...',
    'verifying your quantum passport...',
    'making sure you\'re the chosen one...',
    'authenticating with the universe...',
  ];

  // Values specific messages
  static const List<String> _values = [
    'aligning your moral compass...',
    'calculating value coefficients...',
    'organizing your priorities...',
    'consulting your inner wisdom...',
    'calibrating the importance meter...',
    'weighing what truly matters...',
    'discovering your core essence...',
    'mapping your value constellation...',
    'tuning your authenticity frequency...',
    'synchronizing with your true self...',
  ];

  // Activities specific messages
  static const List<String> _activities = [
    'tracking your legendary deeds...',
    'chronicling your epic journey...',
    'measuring your impact on reality...',
    'calculating your value alignment...',
    'documenting your awesome progress...',
    'analyzing your daily victories...',
    'computing your streak potential...',
    'tallying your meaningful moments...',
    'recording your life\'s greatest hits...',
    'quantifying your awesomeness...',
  ];

  // Rankings specific messages
  static const List<String> _rankings = [
    'consulting the leaderboard gods...',
    'calculating your cosmic ranking...',
    'determining your legendary status...',
    'comparing notes with the universe...',
    'checking who\'s crushing it...',
    'measuring the competition...',
    'updating the hall of fame...',
    'computing your standing among legends...',
    'ranking the value warriors...',
    'sorting the champions...',
  ];

  // Progress specific messages
  static const List<String> _progress = [
    'charting your epic journey...',
    'mapping your growth trajectory...',
    'calculating your evolution rate...',
    'measuring your transformation...',
    'plotting your success story...',
    'analyzing your improvement curve...',
    'tracking your level-up progress...',
    'documenting your glow-up...',
    'measuring your boss-level gains...',
    'charting your path to greatness...',
  ];

  static String getGeneral() => _general[_random.nextInt(_general.length)];
  static String getAuth() => _auth[_random.nextInt(_auth.length)];
  static String getValues() => _values[_random.nextInt(_values.length)];
  static String getActivities() => _activities[_random.nextInt(_activities.length)];
  static String getRankings() => _rankings[_random.nextInt(_rankings.length)];
  static String getProgress() => _progress[_random.nextInt(_progress.length)];

  // Get a message based on context
  static String getByContext(String context) {
    switch (context.toLowerCase()) {
      case 'auth':
      case 'login':
      case 'signup':
      case 'authentication':
        return getAuth();
      case 'values':
        return getValues();
      case 'activities':
      case 'activity':
        return getActivities();
      case 'rankings':
      case 'leaderboard':
        return getRankings();
      case 'progress':
        return getProgress();
      default:
        return getGeneral();
    }
  }
}