# startup.py - Handle database initialization and conflicts
import os
import sys
import subprocess

def run_index_fix():
    """Run the index fix migration"""
    try:
        # Set environment variables for the migration
        env = os.environ.copy()
        
        # Run the index fix migration
        result = subprocess.run([
            sys.executable, 
            "migrations/20250714_fix_mood_indexes.py"
        ], capture_output=True, text=True, env=env)
        
        print("Index fix migration output:")
        print(result.stdout)
        if result.stderr:
            print("Migration stderr:")
            print(result.stderr)
            
        if result.returncode != 0:
            print(f"Migration failed with return code: {result.returncode}")
            
    except Exception as e:
        print(f"Failed to run index fix migration: {e}")

if __name__ == "__main__":
    print("=== Running startup procedures ===")
    run_index_fix()
    print("=== Startup completed ===")