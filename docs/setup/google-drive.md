# Google Drive Backup Setup Guide

To enable Google Drive backup and restore in Ritmo, the project owner needs to configure a Google Cloud Platform (GCP) project.

## Step-by-Step Instructions

1. **Create a GCP Project**:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/).
   - Create a new project named "Ritmo".

2. **Enable Google Drive API**:
   - In the GCP Console, go to **APIs & Services** > **Library**.
   - Search for **Google Drive API** and enable it for your project.

3. **Configure OAuth Consent Screen**:
   - Go to **APIs & Services** > **OAuth consent screen**.
   - Choose **External** user type and fill in the required app information (app name, support email, developer contact details).
   - In the **Scopes** step, add the following scope:
     - `https://www.googleapis.com/auth/drive.appdata` (Google Drive API - View and manage its own configuration data in your Google Drive).
   - Save and continue.

4. **Create OAuth Client ID (Android)**:
   - Go to **APIs & Services** > **Credentials**.
   - Click **Create Credentials** > **OAuth client ID**.
   - Select **Android** as the application type.
   - Set **Package name** to `com.example.ritmo`.
   - To get the SHA-1 fingerprint for your debug keystore, run:
     ```bash
     keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
     ```
     (Default password is `android`).
   - For production, run the command on your release keystore and add the release SHA-1 fingerprint as a second client ID in the same GCP project.
   - Paste the SHA-1 fingerprint into the GCP Console and click **Create**.

5. **No client secrets needed**:
   - The Flutter package `google_sign_in` automatically uses the package name and SHA-1 fingerprint for Android OAuth requests without needing a client secret or `google-services.json` file.
