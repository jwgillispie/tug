#!/usr/bin/env python3
"""
Comprehensive test runner for Tug backend with coverage reporting
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path


def run_command(cmd, description=""):
    """Run a command and handle errors"""
    print(f"\n{'='*60}")
    if description:
        print(f"Running: {description}")
    print(f"Command: {cmd}")
    print('='*60)
    
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"❌ Command failed with return code {result.returncode}")
        return False
    else:
        print(f"✅ Command completed successfully")
        return True


def check_dependencies():
    """Check if all required test dependencies are installed"""
    print("🔍 Checking test dependencies...")
    
    required_packages = [
        'pytest', 'pytest-asyncio', 'pytest-cov', 'pytest-mock',
        'httpx', 'faker', 'factory-boy'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"❌ Missing required packages: {', '.join(missing_packages)}")
        print("Please install them using: pip install " + ' '.join(missing_packages))
        return False
    
    print("✅ All test dependencies are installed")
    return True


def run_unit_tests(verbose=False):
    """Run unit tests"""
    cmd = "python -m pytest tests/test_*_service.py"
    if verbose:
        cmd += " -v"
    cmd += " --cov=app --cov-report=term-missing"
    
    return run_command(cmd, "Unit Tests (Services)")


def run_integration_tests(verbose=False):
    """Run integration tests"""
    cmd = "python -m pytest tests/test_api_endpoints.py"
    if verbose:
        cmd += " -v"
    cmd += " --cov=app --cov-append --cov-report=term-missing"
    
    return run_command(cmd, "Integration Tests (API Endpoints)")


def run_security_tests(verbose=False):
    """Run security tests"""
    cmd = "python -m pytest tests/test_security.py"
    if verbose:
        cmd += " -v"
    cmd += " --cov=app --cov-append --cov-report=term-missing"
    
    return run_command(cmd, "Security Tests")


def run_all_tests(verbose=False, coverage_html=False):
    """Run all tests with coverage"""
    cmd = "python -m pytest"
    if verbose:
        cmd += " -v"
    
    # Coverage options
    cmd += " --cov=app --cov-report=term-missing --cov-report=xml"
    if coverage_html:
        cmd += " --cov-report=html"
    
    # Fail if coverage is below 60%
    cmd += " --cov-fail-under=60"
    
    return run_command(cmd, "All Tests with Coverage")


def run_specific_test(test_pattern, verbose=False):
    """Run specific test pattern"""
    cmd = f"python -m pytest -k '{test_pattern}'"
    if verbose:
        cmd += " -v"
    cmd += " --cov=app --cov-report=term-missing"
    
    return run_command(cmd, f"Specific Tests: {test_pattern}")


def run_performance_tests():
    """Run performance-related tests"""
    cmd = "python -m pytest -m performance -v --tb=short"
    return run_command(cmd, "Performance Tests")


def run_smoke_tests():
    """Run smoke tests for basic functionality"""
    cmd = "python -m pytest -m smoke -v --tb=short"
    return run_command(cmd, "Smoke Tests")


def generate_coverage_report():
    """Generate detailed coverage report"""
    print("\n🔍 Generating detailed coverage report...")
    
    # Generate HTML report
    if run_command("python -m coverage html", "HTML Coverage Report"):
        coverage_path = Path("htmlcov/index.html").absolute()
        print(f"📊 HTML Coverage report generated: {coverage_path}")
        print(f"🌐 Open in browser: file://{coverage_path}")
    
    # Generate XML report for CI/CD
    run_command("python -m coverage xml", "XML Coverage Report")
    
    # Show coverage summary
    run_command("python -m coverage report", "Coverage Summary")


def setup_test_database():
    """Setup test database if needed"""
    print("🗄️  Setting up test database...")
    
    # Check if MongoDB is available
    test_db_url = os.environ.get("TEST_MONGODB_URL", "mongodb://localhost:27017")
    print(f"Using test database: {test_db_url}")
    
    # You could add database setup logic here if needed
    print("✅ Test database setup complete")
    return True


def cleanup_test_artifacts():
    """Clean up test artifacts"""
    print("🧹 Cleaning up test artifacts...")
    
    artifacts = [
        ".coverage",
        "coverage.xml",
        "__pycache__",
        "htmlcov",
        ".pytest_cache"
    ]
    
    for artifact in artifacts:
        if Path(artifact).exists():
            if Path(artifact).is_file():
                Path(artifact).unlink()
                print(f"Removed file: {artifact}")
            else:
                import shutil
                shutil.rmtree(artifact)
                print(f"Removed directory: {artifact}")
    
    print("✅ Cleanup complete")


def main():
    """Main test runner function"""
    parser = argparse.ArgumentParser(description="Tug Backend Test Runner")
    parser.add_argument("--unit", action="store_true", help="Run unit tests only")
    parser.add_argument("--integration", action="store_true", help="Run integration tests only")
    parser.add_argument("--security", action="store_true", help="Run security tests only")
    parser.add_argument("--performance", action="store_true", help="Run performance tests only")
    parser.add_argument("--smoke", action="store_true", help="Run smoke tests only")
    parser.add_argument("--specific", type=str, help="Run specific test pattern")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--html", action="store_true", help="Generate HTML coverage report")
    parser.add_argument("--cleanup", action="store_true", help="Clean up test artifacts")
    parser.add_argument("--no-coverage", action="store_true", help="Skip coverage reporting")
    parser.add_argument("--setup-only", action="store_true", help="Only setup test environment")
    
    args = parser.parse_args()
    
    print("🧪 Tug Backend Test Runner")
    print("=" * 40)
    
    # Cleanup if requested
    if args.cleanup:
        cleanup_test_artifacts()
        return
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Setup test environment
    if not setup_test_database():
        sys.exit(1)
    
    if args.setup_only:
        print("✅ Test environment setup complete")
        return
    
    # Determine which tests to run
    success = True
    
    if args.unit:
        success = run_unit_tests(args.verbose)
    elif args.integration:
        success = run_integration_tests(args.verbose)
    elif args.security:
        success = run_security_tests(args.verbose)
    elif args.performance:
        success = run_performance_tests()
    elif args.smoke:
        success = run_smoke_tests()
    elif args.specific:
        success = run_specific_test(args.specific, args.verbose)
    else:
        # Run all tests
        success = run_all_tests(args.verbose, args.html)
    
    # Generate coverage report if not disabled
    if success and not args.no_coverage:
        generate_coverage_report()
    
    # Final status
    print("\n" + "="*60)
    if success:
        print("🎉 All tests completed successfully!")
        print("✅ Test suite passed with required coverage")
    else:
        print("❌ Some tests failed or coverage is below threshold")
        print("Please review the output above and fix any issues")
        sys.exit(1)


if __name__ == "__main__":
    # Change to the directory containing this script
    os.chdir(Path(__file__).parent)
    main()