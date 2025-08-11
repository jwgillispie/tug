# Security Guidelines

## 🔒 Sensitive Data Protection

### What NOT to commit to git:
- Database connection strings with credentials
- API keys and secrets
- Firebase service account keys
- Production environment variables
- Personal access tokens

### Safe Development Practices:

1. **Environment Variables**: Always use `.env` files for sensitive data
2. **Never hardcode credentials**: Use `os.getenv()` or environment variable loading
3. **Check before commit**: Review your changes with `git diff` before committing
4. **Use .env.example**: Provide templates without real credentials

### Files that should contain NO credentials:
```
*.py files - use os.getenv("VARIABLE_NAME")
*.dart files - use dotenv or secure storage
*.js files - use process.env.VARIABLE_NAME
*.json files - never store credentials
```

### Protected by .gitignore:
- `.env` and `.env.*` (except .env.example)
- `firebase-credentials.json`
- `firebase-adminsdk-*.json`
- Files matching `*credentials*`
- Test files with credentials

## ⚡ Quick Security Check

Before any commit, run:
```bash
# Check for potential credential leaks
git diff --cached | grep -E "(password|secret|key|token|mongodb\+srv)"

# Verify no sensitive files are staged
git status --porcelain | grep -E "\.(env|json|key|pem)$"
```

## 🚨 If Credentials Are Accidentally Committed:

1. **Immediately revoke/rotate** the exposed credentials
2. **Remove from current files** and use environment variables
3. **Clean git history** using git rebase or BFG Repo-Cleaner
4. **Force push** to overwrite remote history
5. **Update team** about the security incident

## 📋 Security Checklist:

- [x] All database URLs use environment variables
- [x] No hardcoded API keys in source code
- [x] Firebase credentials stored securely (not in git)
- [x] .gitignore includes all sensitive file patterns
- [ ] Team members have secure local .env files
- [ ] Production secrets managed via secure deployment systems
- [x] Docker-compose passwords use environment variables
- [ ] All exposed credentials have been rotated

## 🔄 **CREDENTIAL ROTATION REQUIRED**

If credentials were exposed, immediately rotate:
- MongoDB Atlas connection strings
- GitHub personal access tokens  
- Docker Hub tokens
- Strava API keys
- RevenueCat API keys
- Any other API keys or secrets

---

**Remember**: It's easier to prevent security issues than to clean them up after they're in git history! 🔐