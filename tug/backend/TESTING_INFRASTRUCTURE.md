# Tug Backend Testing Infrastructure

## Overview
This document describes the comprehensive testing infrastructure implemented for the Tug backend application. The testing suite includes unit tests, integration tests, security tests, and provides comprehensive code coverage reporting.

## Test Coverage Summary
- **Target Coverage**: 60% minimum
- **Test Files**: 10 comprehensive test files
- **Services Covered**: All major services (Activity, User, Value, Social, etc.)
- **Test Types**: Unit, Integration, Security, Performance

## File Structure

```
backend/
├── tests/
│   ├── conftest.py                    # Test configuration and fixtures
│   ├── test_activity_service.py       # ActivityService unit tests
│   ├── test_user_service.py          # UserService unit tests
│   ├── test_value_service.py         # ValueService unit tests
│   ├── test_social_service.py        # SocialService unit tests
│   ├── test_additional_services.py   # Other services (Mood, Vice, etc.)
│   ├── test_api_endpoints.py         # API integration tests
│   ├── test_security.py              # Security and auth tests
│   ├── test_fixtures.py              # Test data factories
│   ├── test_activities.py            # Legacy placeholder
│   └── test_values.py                # Legacy placeholder
├── pytest.ini                        # Pytest configuration
├── .coveragerc                       # Coverage configuration
├── run_tests.py                      # Comprehensive test runner
├── test_basic.py                     # Basic verification script
└── .github/workflows/test.yml        # CI/CD workflow
```

## Test Categories

### 1. Unit Tests
**Files**: `test_*_service.py`
- **ActivityService**: 25+ tests covering CRUD, validation, statistics
- **UserService**: 20+ tests covering user management, authentication
- **ValueService**: 30+ tests covering values, streaks, limits
- **SocialService**: 25+ tests covering friends, posts, comments
- **Additional Services**: Tests for mood, vice, notification, analytics services

### 2. Integration Tests
**File**: `test_api_endpoints.py`
- API endpoint testing with real HTTP requests
- Authentication flow testing
- Data validation testing
- Error handling verification
- CORS and security headers testing

### 3. Security Tests
**File**: `test_security.py`
- Authentication and authorization testing
- Input validation and injection protection
- Rate limiting verification
- Security headers validation
- Error information disclosure prevention

### 4. Test Fixtures and Data
**Files**: `conftest.py`, `test_fixtures.py`
- Database setup and cleanup
- Mock Firebase authentication
- Sample data generation with Faker
- Factory classes for complex test scenarios
- Performance testing data generators

## Key Features

### Database Testing
- Isolated test database (`tug_test`)
- Automatic cleanup before/after tests
- MongoDB with Motor async driver
- Beanie ODM integration

### Authentication Testing
- Mocked Firebase authentication
- Valid/invalid token scenarios
- Authorization testing
- Session security validation

### Coverage Configuration
- Minimum 60% coverage requirement
- Branch coverage enabled
- HTML and XML report generation
- CI/CD integration

### Test Runner
**Script**: `run_tests.py`
```bash
# Run all tests with coverage
python run_tests.py

# Run specific test types
python run_tests.py --unit
python run_tests.py --integration  
python run_tests.py --security

# Generate HTML coverage report
python run_tests.py --html

# Run specific test patterns
python run_tests.py --specific "test_create_activity"
```

### CI/CD Integration
**File**: `.github/workflows/test.yml`
- Multi-Python version testing (3.9, 3.10, 3.11)
- MongoDB service container
- Coverage reporting to Codecov
- Security scanning with Bandit and Safety
- Code linting with Black, isort, flake8, mypy

## Test Data Factories

### Core Factories
```python
# User factory with realistic data
user = UserFactory()

# Activity with linked values
activity = ActivityFactory(user_id=str(user.id))

# Social network simulation
users, friendships, posts = await create_social_network(num_users=5)

# Performance testing dataset
users, activities = await create_large_dataset_for_performance_testing()
```

### Complex Scenarios
- User with complete profile and activities
- Social networks with friendships and posts
- Vice tracking with indulgences
- Mood tracking over time periods
- Large datasets for performance testing

## Coverage Targets by Component

| Component | Target Coverage | Test Files |
|-----------|----------------|------------|
| Services | 80%+ | `test_*_service.py` |
| API Endpoints | 70%+ | `test_api_endpoints.py` |
| Security | 90%+ | `test_security.py` |
| Models | 60%+ | Covered in service tests |
| Utils | 70%+ | `test_additional_services.py` |

## Running Tests

### Prerequisites
```bash
# Install dependencies
pip install -r requirements.txt

# Ensure MongoDB is running (for local testing)
# Default: mongodb://localhost:27017
```

### Quick Start
```bash
# Verify test infrastructure
python test_basic.py

# Run all tests
python run_tests.py --verbose

# Run with coverage report
python run_tests.py --html
```

### Test Commands
```bash
# Unit tests only
pytest tests/test_*_service.py -v

# Integration tests  
pytest tests/test_api_endpoints.py -v

# Security tests
pytest tests/test_security.py -v

# With coverage
pytest --cov=app --cov-report=html --cov-fail-under=60

# Specific test
pytest tests/test_user_service.py::TestUserService::test_create_user_success -v
```

## Maintenance

### Adding New Tests
1. Create test file following naming convention
2. Import fixtures from `conftest.py`  
3. Use appropriate pytest markers
4. Follow AAA pattern (Arrange, Act, Assert)
5. Add to CI/CD workflow if needed

### Test Data Management
- Use factories for consistent test data
- Clean database before/after tests
- Mock external services (Firebase)
- Use realistic but safe test data

### Coverage Monitoring
- Minimum 60% overall coverage enforced
- Branch coverage enabled
- HTML reports for detailed analysis
- CI/CD integration for automatic reporting

## Troubleshooting

### Common Issues
1. **MongoDB Connection**: Ensure MongoDB is running and accessible
2. **Firebase Credentials**: Mock credentials are used in tests
3. **Package Versions**: Check `requirements.txt` for compatibility
4. **Database Cleanup**: Tests should clean up after themselves

### Debug Commands
```bash
# Run with debug output
pytest -v -s --tb=long

# Run specific failing test
pytest tests/test_user_service.py::test_failing_test -v -s

# Check coverage details
coverage report --show-missing
```

## Performance Considerations

### Test Execution
- Parallel test execution with pytest-xdist
- Database cleanup optimization
- Mock external API calls
- Factory data generation efficiency

### Coverage Analysis
- Focus on critical business logic
- Exclude test files and migrations
- Prioritize service layer coverage
- Monitor coverage trends

## Security Testing

### Areas Covered
- Authentication bypass attempts
- Authorization validation
- Input validation (XSS, SQL injection, NoSQL injection)
- Rate limiting enforcement
- Security header validation
- Error information leakage prevention
- Session security

### Security Test Examples
```python
# Test authentication
async def test_unauthorized_access(test_client):
    response = await test_client.get("/api/v1/users/me")
    assert response.status_code == 401

# Test input validation
async def test_sql_injection_protection(test_client, mock_auth):
    malicious_input = "'; DROP TABLE users; --"
    response = await test_client.post("/api/v1/search", 
                                    json={"query": malicious_input})
    assert response.status_code == 400
```

## Future Enhancements

### Planned Improvements
1. **Performance Testing**: Add load testing with pytest-benchmark
2. **Contract Testing**: API contract validation
3. **Mutation Testing**: Code quality verification with mutmut
4. **E2E Testing**: Browser automation with Playwright
5. **Chaos Engineering**: Failure injection testing

### Monitoring Integration
1. **Test Metrics**: Track test execution time and flakiness
2. **Coverage Trends**: Monitor coverage changes over time  
3. **Quality Gates**: Automated quality enforcement
4. **Alerting**: Notify on coverage drops or test failures

---

## Getting Started Checklist

- [ ] Install dependencies: `pip install -r requirements.txt`
- [ ] Verify MongoDB is running
- [ ] Run verification script: `python test_basic.py`
- [ ] Run full test suite: `python run_tests.py`
- [ ] Check coverage report: `open htmlcov/index.html`
- [ ] Run security tests: `python run_tests.py --security`
- [ ] Verify CI/CD integration works

The testing infrastructure provides comprehensive coverage of the Tug backend application with a focus on reliability, security, and maintainability. The 60% minimum coverage target ensures adequate testing while allowing for pragmatic development practices.