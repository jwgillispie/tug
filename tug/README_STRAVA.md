# Setting Up Strava Integration for Tug

This document explains how to set up the Strava API integration for the Tug app.

## Prerequisites

1. A Strava account
2. A Strava API application (created at [Strava API Settings](https://www.strava.com/settings/api))

## Setup Instructions

### 1. Register a Strava API Application

1. Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
2. Fill in the application details:
   - **Application Name**: Tug
   - **Category**: Fitness
   - **Website**: Your website or `https://example.com` if none
   - **Authorization Callback Domain**: `tug`
   - **Description**: A brief description of your app

3. Click "Create" to register your application

### 2. Get API Credentials

After creating your application, you'll receive:
- **Client ID**: A numerical identifier for your app
- **Client Secret**: A string used to authenticate API requests

### 3. Update the .env File

Add your Strava API credentials to the `.env` file in the root of your project:

```
# Strava API Configuration
STRAVA_CLIENT_ID=YOUR_CLIENT_ID_HERE
STRAVA_CLIENT_SECRET=YOUR_CLIENT_SECRET_HERE
```

### 4. Test the Integration

1. Run the app
2. Go to the Profile screen
3. Tap "Connect to Strava" in the Connected Accounts section
4. You should be redirected to the Strava authorization page
5. After authorizing, you'll be redirected back to the app

## Troubleshooting

### OAuth Redirect Not Working

If the OAuth redirect is not working:

1. Make sure your callback domain is set to `tug` in the Strava API settings
2. Check that the URL scheme is correctly configured in AndroidManifest.xml and Info.plist
3. Verify the app is installed on the device (the redirect won't work in web browsers)

### Authentication Errors

If you're getting authentication errors:

1. Double-check your Client ID and Client Secret in the .env file
2. Ensure the .env file is properly loaded by the app
3. Check that your Strava application is approved and active

### API Rate Limits

Strava API has rate limits:
- 100 requests every 15 minutes
- 1000 requests per day

If you're hitting rate limits, implement caching or reduce the frequency of API calls.

## Additional Resources

- [Strava API Documentation](https://developers.strava.com/docs/)
- [Strava API Reference](https://developers.strava.com/docs/reference/)
- [OAuth 2.0 Flow Explanation](https://developers.strava.com/docs/authentication/)