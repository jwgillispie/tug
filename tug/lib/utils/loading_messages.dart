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
    'yes, we know the app is slow... patience is a virtue!',
    'taking our sweet time, as usual...',
    'loading at the speed of molasses...',
    'hey, good things come to those who wait!',
    'practicing patience while we load...',
    'slow and steady wins the race... hopefully',
    'giving our servers a pep talk...',
    'waiting for the wifi hamsters to wake up...',
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
    'login taking forever? patience is a virtue...',
    'yes, this usually takes a while... hang tight!',
    'our login is slower than a sleepy sloth...',
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
    'loading values slower than usual... good things take time!',
    'patience grasshopper, your values are worth the wait...',
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
    'taking forever? try clicking another tab and coming back!',
    'loading activities at glacial pace... bear with us!',
    'our servers are having a coffee break...',
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
    'rankings loading slowly? switch tabs and come back quickly!',
    'this is taking a while... patience is your secret weapon!',
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
    'progress loading slow? try the tab-switch trick!',
    'rome wasn\'t built in a day... neither is this progress chart!',
    'loading progress at turtle speed... but we\'ll get there!',
  ];

  // Super slow loading messages with helpful tips
  static const List<String> _superSlow = [
    'okay this is taking FOREVER... try clicking another screen and coming back!',
    'seriously slow today! quick fix: tap another tab then come back to this one',
    'loading slower than a sloth on vacation... try the tab-switch trick!',
    'this is embarrassingly slow... click elsewhere and return quickly!',
    'our servers are napping... pro tip: switch screens and come back fast!',
    'taking way too long? navigate away and return - it usually helps!',
    'wow, even we\'re surprised how slow this is... try switching tabs!',
    'loading at geological timescales... the screen-switch trick might save you!',
  ];

  static String getGeneral() => _general[_random.nextInt(_general.length)];
  static String getAuth() => _auth[_random.nextInt(_auth.length)];
  static String getValues() => _values[_random.nextInt(_values.length)];
  static String getActivities() => _activities[_random.nextInt(_activities.length)];
  static String getRankings() => _rankings[_random.nextInt(_rankings.length)];
  static String getProgress() => _progress[_random.nextInt(_progress.length)];
  static String getSuperSlow() => _superSlow[_random.nextInt(_superSlow.length)];

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
      case 'superslow':
      case 'slow':
        return getSuperSlow();
      default:
        return getGeneral();
    }
  }

  // Get a message with a chance of showing super slow message for long loads
  static String getWithSlowChance(String context, {double slowChance = 0.3}) {
    if (_random.nextDouble() < slowChance) {
      return getSuperSlow();
    }
    return getByContext(context);
  }

  // Get a progressive message based on loading duration
  static String getProgressive(String context, Duration loadingTime) {
    if (loadingTime.inSeconds > 10) {
      return getSuperSlow();
    } else if (loadingTime.inSeconds > 5) {
      // Mix in some patience messages
      return getWithSlowChance(context, slowChance: 0.6);
    }
    return getByContext(context);
  }
}