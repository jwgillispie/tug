# app/utils/security_audit.py
"""
Security audit utilities for the Tug application
Comprehensive security vulnerability scanner and recommendations
"""
import os
import re
import logging
from typing import List, Dict, Any, Tuple
from pathlib import Path

logger = logging.getLogger(__name__)

class SecurityAudit:
    """Comprehensive security audit for the Tug application"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.findings = {
            "critical": [],
            "high": [],
            "medium": [],
            "low": [],
            "info": []
        }
    
    def add_finding(self, severity: str, category: str, description: str, 
                   file_path: str = None, line_number: int = None, 
                   recommendation: str = None):
        """Add a security finding"""
        finding = {
            "category": category,
            "description": description,
            "file": file_path,
            "line": line_number,
            "recommendation": recommendation
        }
        self.findings[severity].append(finding)
        
        # Log critical and high severity findings
        if severity in ["critical", "high"]:
            logger.warning(f"[{severity.upper()}] {category}: {description}")
    
    def scan_auth_vulnerabilities(self):
        """Scan for authentication vulnerabilities"""
        logger.info("Scanning for authentication vulnerabilities...")
        
        # Check for manual token extraction
        for py_file in self.project_root.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        # Check for unsafe token extraction
                        if re.search(r"auth_header\.split\(\s*['\"]\\s['\"]\\s*\)\[1\]", line):
                            self.add_finding(
                                "critical",
                                "Unsafe Token Extraction",
                                "Manual token extraction without proper validation",
                                str(py_file),
                                i,
                                "Use secure authentication middleware instead"
                            )
                        
                        # Check for hardcoded credentials
                        if re.search(r"(password|secret|key|token)\s*=\s*['\"][^'\"]{8,}['\"]", line, re.IGNORECASE):
                            self.add_finding(
                                "high",
                                "Hardcoded Credentials",
                                "Potential hardcoded credentials found",
                                str(py_file),
                                i,
                                "Use environment variables for sensitive data"
                            )
                        
                        # Check for Firebase admin key exposure
                        if "firebase-adminsdk" in line.lower():
                            self.add_finding(
                                "medium",
                                "Firebase Credentials",
                                "Firebase admin SDK credentials reference found",
                                str(py_file),
                                i,
                                "Ensure Firebase credentials are properly secured"
                            )
                            
            except Exception as e:
                logger.error(f"Error scanning {py_file}: {e}")
    
    def scan_injection_vulnerabilities(self):
        """Scan for injection vulnerabilities"""
        logger.info("Scanning for injection vulnerabilities...")
        
        # Patterns for different injection types
        patterns = {
            "SQL Injection": [
                r"execute\(['\"].*\+.*['\"]",
                r"query\(['\"].*%s.*['\"]",
                r"SELECT.*\+.*FROM"
            ],
            "NoSQL Injection": [
                r"\{\s*['\"]?\$regex['\"]?\s*:\s*[^}]*['\"]?\s*\}",
                r"\{\s*['\"]?\$where['\"]?\s*:",
                r"find\(\{.*\$regex.*query.*\}\)"
            ],
            "Command Injection": [
                r"os\.system\([^)]*\+",
                r"subprocess\.[^(]*\([^)]*\+",
                r"exec\([^)]*\+"
            ]
        }
        
        for py_file in self.project_root.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        for injection_type, pattern_list in patterns.items():
                            for pattern in pattern_list:
                                if re.search(pattern, line, re.IGNORECASE):
                                    self.add_finding(
                                        "high",
                                        injection_type,
                                        f"Potential {injection_type.lower()} vulnerability",
                                        str(py_file),
                                        i,
                                        "Use parameterized queries and input validation"
                                    )
                                    
            except Exception as e:
                logger.error(f"Error scanning {py_file}: {e}")
    
    def scan_cors_configuration(self):
        """Scan for CORS misconfigurations"""
        logger.info("Scanning CORS configuration...")
        
        for py_file in self.project_root.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    # Check for wildcard CORS
                    if re.search(r"allow_origins\s*=\s*\[\s*['\"]\\*['\"]", content):
                        self.add_finding(
                            "medium",
                            "CORS Misconfiguration",
                            "Wildcard CORS origin found",
                            str(py_file),
                            recommendation="Restrict CORS to specific domains"
                        )
                    
                    # Check for allow_headers = ["*"]
                    if re.search(r"allow_headers\s*=\s*\[\s*['\"]\\*['\"]", content):
                        self.add_finding(
                            "low",
                            "CORS Headers",
                            "Wildcard CORS headers allowed",
                            str(py_file),
                            recommendation="Restrict allowed headers to necessary ones"
                        )
                        
            except Exception as e:
                logger.error(f"Error scanning {py_file}: {e}")
    
    def scan_input_validation(self):
        """Scan for missing input validation"""
        logger.info("Scanning for input validation issues...")
        
        for py_file in self.project_root.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        # Check for direct request.json() without validation
                        if re.search(r"request\.json\(\)", line) and "validate" not in content:
                            self.add_finding(
                                "medium",
                                "Missing Input Validation",
                                "Direct JSON parsing without validation",
                                str(py_file),
                                i,
                                "Add input validation and sanitization"
                            )
                        
                        # Check for base64.b64decode without validation
                        if re.search(r"base64\.b64decode\([^)]*\)", line) and "validate" not in line:
                            self.add_finding(
                                "medium",
                                "Unsafe Base64 Decoding",
                                "Base64 decoding without validation",
                                str(py_file),
                                i,
                                "Add validate=True parameter to base64.b64decode"
                            )
                            
            except Exception as e:
                logger.error(f"Error scanning {py_file}: {e}")
    
    def scan_error_handling(self):
        """Scan for information disclosure in error handling"""
        logger.info("Scanning error handling...")
        
        for py_file in self.project_root.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        # Check for detailed error messages
                        if re.search(r"detail\\s*=\\s*f['\"].*\\{.*e.*\\}['\"]", line):
                            self.add_finding(
                                "low",
                                "Information Disclosure",
                                "Detailed error message may expose sensitive information",
                                str(py_file),
                                i,
                                "Use generic error messages for client responses"
                            )
                        
                        # Check for print/console.log statements
                        if re.search(r"print\\s*\\(.*password|secret|token", line, re.IGNORECASE):
                            self.add_finding(
                                "medium",
                                "Sensitive Data Logging",
                                "Sensitive data may be logged",
                                str(py_file),
                                i,
                                "Remove or mask sensitive data in logs"
                            )
                            
            except Exception as e:
                logger.error(f"Error scanning {py_file}: {e}")
    
    def scan_file_operations(self):
        """Scan for unsafe file operations"""
        logger.info("Scanning file operations...")
        
        for py_file in self.project_root.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        # Check for path traversal vulnerabilities
                        if re.search(r"open\\s*\\([^)]*\\+[^)]*\\)", line):
                            self.add_finding(
                                "high",
                                "Path Traversal",
                                "Potential path traversal vulnerability in file operations",
                                str(py_file),
                                i,
                                "Validate and sanitize file paths"
                            )
                        
                        # Check for file uploads without validation
                        if "upload" in line.lower() and "validate" not in content.lower():
                            self.add_finding(
                                "medium",
                                "File Upload",
                                "File upload without proper validation",
                                str(py_file),
                                i,
                                "Add file type and size validation"
                            )
                            
            except Exception as e:
                logger.error(f"Error scanning {py_file}: {e}")
    
    def check_dependencies(self):
        """Check for vulnerable dependencies"""
        logger.info("Checking dependencies...")
        
        requirements_files = list(self.project_root.rglob("requirements*.txt"))
        requirements_files.extend(list(self.project_root.rglob("Pipfile")))
        requirements_files.extend(list(self.project_root.rglob("pyproject.toml")))
        
        if not requirements_files:
            self.add_finding(
                "low",
                "Missing Dependency File",
                "No dependency files found",
                recommendation="Create requirements.txt with pinned versions"
            )
        
        # Known vulnerable packages (this should be updated regularly)
        vulnerable_packages = {
            "pillow": ["<8.2.0", "Vulnerable to buffer overflow"],
            "urllib3": ["<1.26.5", "Vulnerable to CRLF injection"],
            "requests": ["<2.25.1", "Vulnerable to SSRF"]
        }
        
        for req_file in requirements_files:
            try:
                with open(req_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    for package, (version, desc) in vulnerable_packages.items():
                        if package in content:
                            self.add_finding(
                                "medium",
                                "Vulnerable Dependency",
                                f"Potentially vulnerable {package} dependency: {desc}",
                                str(req_file),
                                recommendation=f"Update {package} to version {version} or higher"
                            )
                            
            except Exception as e:
                logger.error(f"Error checking {req_file}: {e}")
    
    def run_full_audit(self) -> Dict[str, List[Dict[str, Any]]]:
        """Run comprehensive security audit"""
        logger.info("Starting comprehensive security audit...")
        
        # Run all security scans
        self.scan_auth_vulnerabilities()
        self.scan_injection_vulnerabilities()
        self.scan_cors_configuration()
        self.scan_input_validation()
        self.scan_error_handling()
        self.scan_file_operations()
        self.check_dependencies()
        
        # Generate summary
        total_findings = sum(len(findings) for findings in self.findings.values())
        logger.info(f"Security audit completed. Total findings: {total_findings}")
        
        for severity, findings in self.findings.items():
            if findings:
                logger.info(f"{severity.upper()}: {len(findings)} findings")
        
        return self.findings
    
    def generate_report(self, output_file: str = None) -> str:
        """Generate a security audit report"""
        report = []
        report.append("# Security Audit Report")
        report.append(f"Generated on: {__import__('datetime').datetime.now().isoformat()}")
        report.append("")
        
        # Summary
        total = sum(len(findings) for findings in self.findings.values())
        report.append(f"## Summary")
        report.append(f"Total findings: {total}")
        report.append("")
        
        for severity in ["critical", "high", "medium", "low", "info"]:
            count = len(self.findings[severity])
            if count > 0:
                report.append(f"- {severity.upper()}: {count}")
        
        report.append("")
        
        # Detailed findings
        for severity in ["critical", "high", "medium", "low", "info"]:
            findings = self.findings[severity]
            if not findings:
                continue
                
            report.append(f"## {severity.upper()} Severity Findings")
            report.append("")
            
            for i, finding in enumerate(findings, 1):
                report.append(f"### {i}. {finding['category']}")
                report.append(f"**Description:** {finding['description']}")
                
                if finding['file']:
                    location = finding['file']
                    if finding['line']:
                        location += f":{finding['line']}"
                    report.append(f"**Location:** {location}")
                
                if finding['recommendation']:
                    report.append(f"**Recommendation:** {finding['recommendation']}")
                
                report.append("")
        
        report_text = "\\n".join(report)
        
        if output_file:
            try:
                with open(output_file, 'w', encoding='utf-8') as f:
                    f.write(report_text)
                logger.info(f"Security report saved to {output_file}")
            except Exception as e:
                logger.error(f"Error saving report: {e}")
        
        return report_text

def run_security_audit(project_root: str = None) -> Dict[str, List[Dict[str, Any]]]:
    """Run security audit and return findings"""
    if not project_root:
        project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    audit = SecurityAudit(project_root)
    findings = audit.run_full_audit()
    
    # Generate report
    report_path = os.path.join(project_root, "security_audit_report.md")
    audit.generate_report(report_path)
    
    return findings

if __name__ == "__main__":
    # Run audit when script is executed directly
    findings = run_security_audit()
    print(f"Security audit completed. Check security_audit_report.md for details.")