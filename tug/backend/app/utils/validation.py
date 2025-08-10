# app/utils/validation.py
import re
import html
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
import logging

logger = logging.getLogger(__name__)

# Security patterns
SUSPICIOUS_PATTERNS = [
    # SQL injection patterns
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)",
    # XSS patterns
    r"(<script|javascript:|on\w+\s*=)",
    # Command injection patterns
    r"(;|\||&|`|\$\()",
    # Directory traversal
    r"(\.\./|\.\.\\)",
    # NoSQL injection patterns
    r"(\$where|\$regex|\$ne|\$gt|\$lt)",
]

COMPILED_PATTERNS = [re.compile(pattern, re.IGNORECASE) for pattern in SUSPICIOUS_PATTERNS]

class InputValidator:
    """Comprehensive input validation and sanitization utility"""
    
    @staticmethod
    def sanitize_string(value: str, max_length: int = 1000, allow_html: bool = False) -> str:
        """Sanitize string input with length limits and HTML escaping"""
        if not isinstance(value, str):
            return str(value)
        
        # Remove null bytes and control characters
        value = ''.join(char for char in value if ord(char) >= 32 or char in ['\n', '\r', '\t'])
        
        # Trim whitespace
        value = value.strip()
        
        # Enforce length limits
        if len(value) > max_length:
            logger.warning(f"String truncated from {len(value)} to {max_length} characters")
            value = value[:max_length]
        
        # HTML escape unless explicitly allowed
        if not allow_html:
            value = html.escape(value)
        
        return value
    
    @staticmethod
    def detect_injection_attempts(value: str) -> List[str]:
        """Detect potential injection attempts in string values"""
        detected_patterns = []
        
        for i, pattern in enumerate(COMPILED_PATTERNS):
            if pattern.search(value):
                detected_patterns.append(SUSPICIOUS_PATTERNS[i])
        
        return detected_patterns
    
    @staticmethod
    def validate_email(email: str) -> str:
        """Validate and sanitize email address"""
        email = InputValidator.sanitize_string(email, max_length=254).lower()
        
        # Basic email regex
        email_pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        if not email_pattern.match(email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "invalid_email",
                    "message": "Invalid email format"
                }
            )
        
        return email
    
    @staticmethod
    def validate_display_name(name: str) -> str:
        """Validate and sanitize display name"""
        name = InputValidator.sanitize_string(name, max_length=100)
        
        if len(name) < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "invalid_display_name",
                    "message": "Display name cannot be empty"
                }
            )
        
        # Check for suspicious patterns
        suspicious = InputValidator.detect_injection_attempts(name)
        if suspicious:
            logger.warning(f"Suspicious patterns detected in display name: {suspicious}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "invalid_input",
                    "message": "Display name contains invalid characters"
                }
            )
        
        return name
    
    @staticmethod
    def validate_bio(bio: str) -> str:
        """Validate and sanitize user bio"""
        bio = InputValidator.sanitize_string(bio, max_length=500)
        
        # Check for suspicious patterns
        suspicious = InputValidator.detect_injection_attempts(bio)
        if suspicious:
            logger.warning(f"Suspicious patterns detected in bio: {suspicious}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "invalid_input",
                    "message": "Bio contains invalid content"
                }
            )
        
        return bio
    
    @staticmethod
    def validate_url(url: str) -> str:
        """Validate and sanitize URL"""
        url = InputValidator.sanitize_string(url, max_length=2048)
        
        # Basic URL validation
        url_pattern = re.compile(
            r'^https?://'  # http:// or https://
            r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
            r'localhost|'  # localhost...
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
            r'(?::\d+)?'  # optional port
            r'(?:/?|[/?]\S+)$', re.IGNORECASE)
        
        if url and not url_pattern.match(url):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "invalid_url",
                    "message": "Invalid URL format"
                }
            )
        
        return url
    
    @staticmethod
    def validate_json_payload(payload: Dict[str, Any], max_keys: int = 50) -> Dict[str, Any]:
        """Validate JSON payload structure and content"""
        if not isinstance(payload, dict):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "invalid_payload",
                    "message": "Payload must be a JSON object"
                }
            )
        
        if len(payload) > max_keys:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "payload_too_complex",
                    "message": f"Payload cannot have more than {max_keys} keys"
                }
            )
        
        # Recursively validate string values
        def validate_nested(obj, depth=0):
            if depth > 10:  # Prevent deep nesting attacks
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail={
                        "error": "payload_too_nested",
                        "message": "Payload nesting too deep"
                    }
                )
            
            if isinstance(obj, dict):
                return {k: validate_nested(v, depth + 1) for k, v in obj.items()}
            elif isinstance(obj, list):
                if len(obj) > 1000:  # Prevent large array attacks
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail={
                            "error": "array_too_large",
                            "message": "Array too large"
                        }
                    )
                return [validate_nested(item, depth + 1) for item in obj]
            elif isinstance(obj, str):
                # Check for injection attempts in all string values
                suspicious = InputValidator.detect_injection_attempts(obj)
                if suspicious:
                    logger.warning(f"Suspicious patterns detected in payload: {suspicious}")
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail={
                            "error": "invalid_input",
                            "message": "Payload contains suspicious content"
                        }
                    )
                return InputValidator.sanitize_string(obj, max_length=10000)
            else:
                return obj
        
        return validate_nested(payload)

    @staticmethod
    def validate_id_format(id_value: str, field_name: str = "id") -> str:
        """Validate ID format (ObjectId or UUID)"""
        id_value = InputValidator.sanitize_string(id_value, max_length=100)
        
        # Check for ObjectId format (24 hex characters) or UUID format
        objectid_pattern = re.compile(r'^[0-9a-fA-F]{24}$')
        uuid_pattern = re.compile(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        
        if not (objectid_pattern.match(id_value) or uuid_pattern.match(id_value)):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": f"invalid_{field_name}",
                    "message": f"Invalid {field_name} format"
                }
            )
        
        return id_value

class SecurityHeaders:
    """Security headers for API responses"""
    
    @staticmethod
    def get_security_headers() -> Dict[str, str]:
        """Get standard security headers"""
        return {
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            "Referrer-Policy": "strict-origin-when-cross-origin",
            "Content-Security-Policy": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';",
            "Permissions-Policy": "geolocation=(), microphone=(), camera=()",
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains"
        }

def sanitize_text_content(content: str, max_length: int = 4000) -> str:
    """Sanitize text content for messages"""
    return InputValidator.sanitize_string(content, max_length=max_length)

def validate_message_content(content: str) -> str:
    """Validate message content with enhanced security checks"""
    content = sanitize_text_content(content)
    
    # Check for suspicious patterns
    suspicious = InputValidator.detect_injection_attempts(content)
    if suspicious:
        logger.warning(f"Suspicious patterns detected in message content: {suspicious}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "invalid_content",
                "message": "Message contains invalid content"
            }
        )
    
    return content