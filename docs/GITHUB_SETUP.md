# Putting the app on GitHub (one-time setup, ~10 minutes)

After this, every time you push a change GitHub builds the app and publishes
`WantokRadioLight.apk` as a Release. Your website's download button always gets the newest one.

## 1. Create the repository
1. Go to https://github.com/new
2. Name: **wantok-radio-flutter** · Visibility: **Public** · leave "Add a README" **unticked**
3. Click **Create repository**

> Why public? GitHub only lets the public download Release files from public repositories.
> Your source code becomes visible, but your signing key stays secret (it's in Secrets, step 3,
> and is never committed). If you must keep it private, see "Private repository" at the bottom.

## 2. Upload the project
Easiest — **GitHub Desktop** (https://desktop.github.com):
1. File → Clone repository → `mmyolto/wantok-radio-flutter` → choose a folder
2. Unzip `WantokRadio_GitHub_Project.zip` and copy everything **inside** the
   `wantok-radio-flutter` folder into the cloned folder (include the hidden `.github` folder and
   `.gitignore` — on Windows turn on View → Hidden items)
3. In GitHub Desktop: write "First version" in Summary → **Commit to main** → **Push origin**

Or with the command line, inside the unzipped `wantok-radio-flutter` folder:
```bash
git init -b main
git add .
git commit -m "Wantok Radio Light Flutter app"
git remote add origin https://github.com/mmyolto/wantok-radio-flutter.git
git push -u origin main
```

## 3. Add the signing secrets (do this BEFORE the first build finishes, or re-run it after)
Repository → **Settings → Secrets and variables → Actions → New repository secret**.
Create these 4 secrets using the values in `SIGNING_KEY_KEEP_PRIVATE/secrets.txt`:

| Name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the long text in `keystore_base64.txt` (copy all of it) |
| `ANDROID_STORE_PASSWORD` | password from secrets.txt |
| `ANDROID_KEY_PASSWORD` | same password |
| `ANDROID_KEY_ALIAS` | `upload` |

The same key must sign **every** future version, otherwise phones can't update the app.
Keep `upload-keystore.jks` and the password backed up somewhere safe (not in GitHub).

## 4. Build
Repository → **Actions** → *Build & Release* → **Run workflow** (or just push a change).
About 10 minutes later you'll find it under **Releases**:

- `WantokRadioLight.apk` — for the website / phones
- `WantokRadioLight-vX.Y.Z-googleplay.aab` — for Google Play

The website link that always gives the newest APK:
```
https://github.com/mmyolto/wantok-radio-flutter/releases/latest/download/WantokRadioLight.apk
```

## Releasing an update
1. Make your change
2. In `pubspec.yaml` raise the version, e.g. `version: 1.0.1+2` (the number after `+` must always go up)
3. Commit and push → a new Release is published and the website button serves it automatically

## Private repository (optional)
Keep the repo private, download `WantokRadioLight.apk` from the finished Actions run
(Actions → run → Artifacts), and upload it to your website's `downloads/` folder instead.
Then change `APK_URL` at the top of `app.html` to `downloads/WantokRadioLight.apk`.
