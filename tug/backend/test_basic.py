#!/usr/bin/env python3
"""
Basic test script to verify testing infrastructure
"""

import subprocess
import sys
from pathlib import Path


def run_basic_tests():
    """Run basic tests to verify infrastructure"""
    print("🧪 Running basic test verification...")
    
    # Check if pytest is available
    try:
        import pytest
        import httpx
        import faker
        print("✅ Test dependencies are available")
    except ImportError as e:
        print(f"❌ Missing test dependency: {e}")
        return False
    
    # Run a simple test
    cmd = [
        sys.executable, "-m", "pytest", 
        "tests/test_user_service.py::TestUserService::test_create_user_success",
        "-v", "--tb=short", "--no-cov"
    ]
    
    print(f"Running: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print("✅ Basic test passed!")
            print("STDOUT:", result.stdout)
            return True
        else:
            print("❌ Basic test failed!")
            print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
            return False
    except subprocess.TimeoutExpired:
        print("❌ Test timed out")
        return False
    except Exception as e:
        print(f"❌ Error running test: {e}")
        return False


def check_test_files():
    """Check if all test files are present"""
    print("📁 Checking test file structure...")
    
    test_files = [
        "tests/conftest.py",
        "tests/test_user_service.py",
        "tests/test_value_service.py",
        "tests/test_activity_service.py",
        "tests/test_social_service.py",
        "tests/test_api_endpoints.py",
        "tests/test_security.py",
        "tests/test_additional_services.py",
        "tests/test_fixtures.py"
    ]
    
    missing_files = []
    for test_file in test_files:
        if not Path(test_file).exists():
            missing_files.append(test_file)
    
    if missing_files:
        print(f"❌ Missing test files: {missing_files}")
        return False
    else:
        print(f"✅ All {len(test_files)} test files present")
        return True


def estimate_coverage():
    """Estimate potential test coverage"""
    print("📊 Analyzing potential test coverage...")
    
    # Count Python files in app directory
    app_files = list(Path("app").rglob("*.py"))
    test_files = list(Path("tests").glob("test_*.py"))
    
    print(f"📁 Found {len(app_files)} Python files in app/")
    print(f"🧪 Found {len(test_files)} test files")
    
    # Rough estimation based on test file coverage
    service_files = list(Path("app/services").glob("*.py"))
    service_test_files = [f for f in test_files if "service" in f.name]
    
    print(f"🔧 Services: {len(service_files)} files")
    print(f"🧪 Service tests: {len(service_test_files)} files")
    
    if len(service_files) > 0:
        service_coverage = len(service_test_files) / len(service_files) * 100
        print(f"📈 Estimated service coverage: {service_coverage:.1f}%")


def main():
    """Main function"""
    print("🚀 Tug Backend Testing Infrastructure Verification")
    print("=" * 50)
    
    # Change to script directory
    os.chdir(Path(__file__).parent)
    
    success = True
    
    # Check test files
    if not check_test_files():
        success = False
    
    # Estimate coverage
    estimate_coverage()
    
    # Try to run a basic test
    if not run_basic_tests():
        success = False
    
    print("\n" + "=" * 50)
    if success:
        print("🎉 Testing infrastructure verification completed successfully!")
        print("✅ Ready to run full test suite")
        print("\nNext steps:")
        print("1. pip install -r requirements.txt")
        print("2. python run_tests.py --unit")
        print("3. python run_tests.py (for full test suite)")
    else:
        print("❌ Testing infrastructure has issues")
        print("Please review the output above and fix any problems")
        sys.exit(1)


if __name__ == "__main__":
    import os
    main()