# BrewCrew Setup Instructions

## API Key Configuration

This app uses the Google Places API. To run the app, you need to:

1. **Create APIKeys.plist**
   - Copy `APIKeys-Sample.plist` to `APIKeys.plist`
   - Add your Google Places API key to the file
   - This file is gitignored and won't be committed

2. **Get a Google Places API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable the "Places API" in APIs & Services
   - Go to "Credentials" and create an API key
   - Restrict the key to "Places API" for security

3. **Add the API Key to Xcode**
   - In Xcode, add `APIKeys.plist` to your project
   - Make sure it's added to the BrewCrew target
   - The app will automatically load the key from this file

## Important Security Notes

- **NEVER** commit `APIKeys.plist` or `Config.swift` to git
- These files are in `.gitignore` for security
- Use `Config-Sample.swift` as a template
- Always use environment-specific configuration files

## Troubleshooting

If you see "Google Places API key not found" error:
1. Make sure `APIKeys.plist` exists in your project
2. Verify the key is correctly added to the plist
3. Ensure the plist is included in your app bundle