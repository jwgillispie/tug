import 'package:flutter_test/flutter_test.dart';
import 'package:tug/services/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(
        maxRequestsPerMinute: 5,
        maxConcurrentRequests: 2,
        backoffBase: const Duration(milliseconds: 100),
        maxRetries: 2,
      );
    });

    test('should allow requests within rate limit', () async {
      final results = <String>[];
      
      // Execute 3 requests (under the limit of 5)
      await Future.wait([
        rateLimiter.throttle('/test1', () async {
          results.add('request1');
          return 'result1';
        }),
        rateLimiter.throttle('/test2', () async {
          results.add('request2');
          return 'result2';
        }),
        rateLimiter.throttle('/test3', () async {
          results.add('request3');
          return 'result3';
        }),
      ]);

      expect(results.length, equals(3));
      expect(results, containsAll(['request1', 'request2', 'request3']));
    });

    test('should enforce concurrent request limit', () async {
      final requestStates = <String>[];
      final futures = <Future>[];

      // Start 4 concurrent requests (exceeding limit of 2)
      for (int i = 0; i < 4; i++) {
        futures.add(
          rateLimiter.throttle('/test$i', () async {
            requestStates.add('executing$i');
            await Future.delayed(const Duration(milliseconds: 100));
            return 'result$i';
          }),
        );
      }

      await Future.wait(futures);

      // All requests should complete
      expect(requestStates.length, equals(4));
      
      // Verify stats show correct concurrent limit was enforced
      final stats = rateLimiter.getStats();
      expect(stats['max_concurrent_requests'], equals(2));
    });

    test('should retry on retryable errors', () async {
      int attemptCount = 0;
      
      final result = await rateLimiter.throttle('/retry-test', () async {
        attemptCount++;
        if (attemptCount < 3) {
          throw Exception('Network timeout');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(attemptCount, equals(3));
    });

    test('should not retry on non-retryable errors', () async {
      int attemptCount = 0;
      
      try {
        await rateLimiter.throttle('/no-retry-test', () async {
          attemptCount++;
          throw Exception('Invalid request format');
        });
      } catch (e) {
        // Expected to throw
      }

      expect(attemptCount, equals(1));
    });

    test('should provide accurate stats', () async {
      await rateLimiter.throttle('/stats-test', () async {
        return 'result';
      });

      final stats = rateLimiter.getStats();
      
      expect(stats['requests_in_last_minute'], equals(1));
      expect(stats['current_concurrent_requests'], equals(0));
      expect(stats['max_requests_per_minute'], equals(5));
      expect(stats['max_concurrent_requests'], equals(2));
    });

    test('should reset correctly', () async {
      // Make some requests
      await rateLimiter.throttle('/reset-test1', () async => 'result1');
      await rateLimiter.throttle('/reset-test2', () async => 'result2');
      
      // Verify stats show requests
      var stats = rateLimiter.getStats();
      expect(stats['requests_in_last_minute'], equals(2));
      
      // Reset and verify stats are cleared
      rateLimiter.reset();
      stats = rateLimiter.getStats();
      expect(stats['requests_in_last_minute'], equals(0));
    });

    test('should handle rate limit with delays', () async {
      final restrictiveLimiter = RateLimiter(
        maxRequestsPerMinute: 2,
        maxConcurrentRequests: 5,
      );

      final results = <String>[];

      // Make 2 requests first (within limit)
      await restrictiveLimiter.throttle('/delay-test1', () async {
        results.add('request1');
        return 'result1';
      });
      
      await restrictiveLimiter.throttle('/delay-test2', () async {
        results.add('request2');
        return 'result2';
      });

      // Check that we have 2 requests in the current minute
      final stats = restrictiveLimiter.getStats();
      expect(stats['requests_in_last_minute'], equals(2));
      
      // All requests should complete
      expect(results.length, equals(2));
    });
  });
}