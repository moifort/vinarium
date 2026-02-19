# Cave-a-Vin

A purely functional approach to wine cellar management.

<p align="center">
  <img src="screenshots/dashboard.png" width="250" alt="Dashboard">
  <img src="screenshots/cellar.png" width="250" alt="Cellar">
  <img src="screenshots/wine-list.png" width="250" alt="Wine list">
</p>

## Features

- **AI scan** — photograph a label, get structured wine data + price estimate (Claude Sonnet 4.5 vision + Gemini 2.0 Flash web search)
- **Cellar grid** — physical position tracking by row and column
- **Journal** — entry/exit history with tasting notes and ratings
- **Dashboard** — cellar stats, total value, ready-to-drink alerts, recent activity
- **Wine catalog** — full metadata, grape varieties, appellations, drink windows

<p align="center">
  <img src="screenshots/wine-detail.png" width="250" alt="Wine detail">
  <img src="screenshots/journal.png" width="250" alt="Journal">
</p>

## Tech Stack

| Layer | Stack |
|-------|-------|
| iOS | SwiftUI, Swift 6, iOS 26 |
| Backend | Nitro, TypeScript, Zod, file-based storage |
| AI | Claude Sonnet 4.5 (vision), Gemini 2.0 Flash (web search) |

## Getting Started

### Backend

The server is available on Docker Hub at [moifort/cave-a-vin](https://hub.docker.com/r/moifort/cave-a-vin).

```yaml
services:
  cave-a-vin:
    image: moifort/cave-a-vin:latest
    container_name: cave-a-vin
    restart: unless-stopped
    environment:
      HOST: 0.0.0.0
      PORT: "3000"
      NITRO_ANTHROPIC_API_KEY: "sk-ant-..."
      NITRO_GOOGLE_API_KEY: "..."
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/.data
```

```bash
docker compose up -d
```

Or run locally with Bun:

```bash
bun install
bun run dev
```

### iOS App

Open `ios/CaveAVin.xcodeproj` in Xcode, set the server URL in settings, and run on your device or simulator.
