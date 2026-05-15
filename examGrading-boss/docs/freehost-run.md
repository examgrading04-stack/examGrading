# Deploy Backend to FreeHost.run

FreeHost.run advertises free Docker container hosting with no credit card, automatic SSL, GitHub/GitLab integration, direct upload, FTP/SFTP, and CLI deployment options.

## 1. Prepare Firebase Secret

Do not commit `serviceAccountKey.json`.

Open the Firebase service account JSON file and copy the entire JSON content into one environment variable:

```text
FIREBASE_SERVICE_ACCOUNT_JSON={...full firebase admin sdk json...}
```

Also set:

```text
FIREBASE_STORAGE_BUCKET=examgradings.firebasestorage.app
PORT=8000
```

## 2. Create FreeHost.run Project

1. Sign up at `https://www.freehost.run/`.
2. Open the dashboard.
3. Click `New Project`.
4. Choose a project name such as `exam-grading-api`.
5. Choose `Docker` or `Python` with Dockerfile support.

## 3. Deploy Code

Recommended path:

1. Push this repo to GitHub.
2. Connect the GitHub repository in FreeHost.run.
3. Select the `examGrading-boss` project root.
4. Use the root `Dockerfile`.
5. Deploy.

If FreeHost.run asks for a start command, use:

```bash
uvicorn backend.main:app --host 0.0.0.0 --port $PORT
```

## 4. Configure Environment Variables

In FreeHost.run project settings, add:

```text
FIREBASE_SERVICE_ACCOUNT_JSON=<full JSON>
FIREBASE_STORAGE_BUCKET=examgradings.firebasestorage.app
PORT=8000
```

## 5. Test

After deploy, FreeHost.run should give an HTTPS URL like:

```text
https://exam-grading-api.freehost.run
```

Test:

```text
https://exam-grading-api.freehost.run/api/health
```

Expected:

```json
{"ok":true,"service":"exam-grading-omr"}
```

## 6. Point Web and Mobile to the Hosted API

Mobile `.env`:

```text
FASTAPI_URL=https://exam-grading-api.freehost.run
```

Frontend `.env`:

```text
VITE_API_BASE_URL=https://exam-grading-api.freehost.run
```

Then rebuild/restart the apps.
