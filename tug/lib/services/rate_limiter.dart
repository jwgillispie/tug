import 'dart:async';
import 'dart:collection';

class RateLimiter {
  final int maxRequestsPerMinute;
  final int maxConcurrentRequests;
  final Duration backoffBase;
  final int maxRetries;
  
  final Queue<DateTime> _requestTimes = Queue<DateTime>();
  int _currentConcurrentRequests = 0;
  final Map<String, int> _endpointRetryCount = {};
  
  RateLimiter({
    this.maxRequestsPerMinute = 60,
    this.maxConcurrentRequests = 5,
    this.backoffBase = const Duration(seconds: 1),
    this.maxRetries = 3,
  });

  Future<T> throttle<T>(
    String endpoint,
    Future<T> Function() request,
  ) async {
    await _waitForRateLimit();
    await _waitForConcurrencyLimit();
    
    _currentConcurrentRequests++;
    
    try {
      _requestTimes.add(DateTime.now());
      final result = await _executeWithRetry(endpoint, request);
      _endpointRetryCount.remove(endpoint);
      return result;
    } finally {
      _currentConcurrentRequests--;
      _cleanupOldRequests();
    }
  }

  Future<void> _waitForRateLimit() async {
    _cleanupOldRequests();
    
    while (_requestTimes.length >= maxRequestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = Duration(minutes: 1) - DateTime.now().difference(oldestRequest);
      
      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
        _cleanupOldRequests();
      } else {
        break;
      }
    }
  }

  Future<void> _waitForConcurrencyLimit() async {
    while (_currentConcurrentRequests >= maxConcurrentRequests) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<T> _executeWithRetry<T>(
    String endpoint,
    Future<T> Function() request,
  ) async {
    final retryCount = _endpointRetryCount[endpoint] ?? 0;
    
    try {
      return await request();
    } catch (e) {
      if (retryCount < maxRetries && _shouldRetry(e)) {
        _endpointRetryCount[endpoint] = retryCount + 1;
        
        final backoffDuration = Duration(
          milliseconds: backoffBase.inMilliseconds * (1 << retryCount),
        );
        
        await Future.delayed(backoffDuration);
        return await _executeWithRetry(endpoint, request);
      }
      
      rethrow;
    }
  }

  bool _shouldRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('server') ||
           errorString.contains('503') ||
           errorString.contains('502') ||
           errorString.contains('429');
  }

  void _cleanupOldRequests() {
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 1));
    
    while (_requestTimes.isNotEmpty && _requestTimes.first.isBefore(cutoffTime)) {
      _requestTimes.removeFirst();
    }
  }

  void reset() {
    _requestTimes.clear();
    _endpointRetryCount.clear();
    _currentConcurrentRequests = 0;
  }

  Map<String, dynamic> getStats() {
    _cleanupOldRequests();
    
    return {
      'requests_in_last_minute': _requestTimes.length,
      'current_concurrent_requests': _currentConcurrentRequests,
      'max_requests_per_minute': maxRequestsPerMinute,
      'max_concurrent_requests': maxConcurrentRequests,
      'endpoints_with_retries': Map.from(_endpointRetryCount),
    };
  }
}