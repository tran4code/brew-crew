# Pre-Populated Database Setup

This guide explains how to create and use a pre-populated database for BrewCrew.

## Creating a Pre-Populated Database

1. **Run the app and populate data**:
   - Open the Explore tab
   - Tap the gear icon (settings)
   - Choose your desired radius
   - Tap "Populate Database"
   - Wait for the data to load

2. **Export the database**:
   - In Database Settings, tap "Export Database"
   - The database will be saved to Documents folder
   - File name: `BrewCrew-Prepopulated.sqlite`

3. **Access the exported file**:
   - On Simulator: 
     - Print the file path from console
     - Open Finder and navigate to the path
   - On Device:
     - Use Files app
     - Or connect device and use Xcode's Devices window

## Adding Pre-Populated Database to Your App

1. **Add to Xcode Project**:
   - Drag `BrewCrew-Prepopulated.sqlite` into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to target: BrewCrew

2. **Verify Bundle Resource**:
   - Select your target in Xcode
   - Go to Build Phases → Copy Bundle Resources
   - Ensure `BrewCrew-Prepopulated.sqlite` is listed

3. **How it works**:
   - On first launch, the app checks for existing database
   - If none exists, it copies the pre-populated database
   - Users get instant access to all coffee shops

## Benefits

- **No API calls on first launch**: Saves quota and provides instant data
- **Offline functionality**: Works without internet connection
- **Consistent experience**: All users start with same data
- **Fast startup**: No loading time for initial data

## Updating Pre-Populated Data

To update the bundled database:

1. Clear existing database (Settings → Clear Database)
2. Populate with fresh data
3. Export the new database
4. Replace the file in Xcode
5. Build and distribute update

## Technical Details

The pre-populated database contains:
- Coffee shop names and addresses
- GPS coordinates
- Ratings and review counts
- Place types (coffee shop or bakery)
- Google Place IDs
- Creation timestamps

The database is automatically loaded by `CoffeeShopDatabaseManager` on first launch.