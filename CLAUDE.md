# Sözbil Platform — Project Context for Claude

> Read this file at the start of every session. It contains all design decisions, architecture,
> file layout, and pending work for the Sözbil Turkmen game platform.

---

## 1. Project Overview

**Sözbil** is a Turkmen-language game platform (mobile app + backend) owned by **Can Abdiyev**
(canabdiyev@gmail.com). It started as a simple hangman app for Android and is being rebuilt as a
full multi-game platform targeting Turkmenistan and the Turkic diaspora.

**Target users:** Turkmen speakers in Turkmenistan, Turkey, and the diaspora. Users do not pay much
for apps and drop them easily, so the free-play limit is generous.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (cross-platform: Android, iOS, tablet) |
| State management | Riverpod (`flutter_riverpod`) |
| Navigation | GoRouter |
| HTTP | Dio |
| Local storage | SharedPreferences (via `StorageService`) |
| Backend | Django 5 + Django REST Framework |
| Database | Supabase PostgreSQL (prod) / SQLite (local dev) |
| DB URL parsing | `dj-database-url` with `DATABASE_URL` env var |
| Hosting | Render.com (backend) |
| Ads | Google AdMob (banner + rewarded video) |
| IAP | `in_app_purchase` (Google Play Billing / App Store) |
| Share | `share_plus` (Telegram share for results) |

---

## 3. Repository Layout

```
Sozbil_full/
├── CLAUDE.md                        ← this file
├── hangman_backend/                 ← Django backend
│   ├── build.sh                     ← Render deploy script (pip, migrate, seed)
│   ├── requirements.txt
│   ├── hangman_project/
│   │   ├── settings.py              ← DATABASE_URL → Supabase; SQLite fallback
│   │   └── urls.py
│   └── hangman/
│       ├── models.py
│       ├── serializers.py
│       ├── views.py
│       ├── urls.py
│       ├── admin.py
│       └── migrations/
│           ├── 0001_initial.py
│           ├── 0002_platform_upgrade.py
│           └── 0003_chat.py
└── sozbil_flutter/                  ← Flutter app
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/
        │   │   ├── app_colors.dart
        │   │   ├── app_strings.dart       (Turkmen UI strings)
        │   │   └── api_constants.dart
        │   ├── theme/app_theme.dart
        │   ├── services/
        │   │   ├── api_service.dart
        │   │   ├── storage_service.dart
        │   │   └── rewarded_ad_service.dart  ← preloads + shows rewarded ad
        │   └── widgets/
        │       └── banner_ad_widget.dart   ← ConsumerWidget, self-checks subscription
        ├── models/
        │   ├── word.dart
        │   ├── player.dart
        │   ├── leaderboard_entry.dart
        │   ├── external_app.dart
        │   ├── puzzle_image.dart
        │   ├── achievement.dart
        │   └── chat_message.dart
        ├── providers/app_providers.dart
        └── screens/
            ├── onboarding/onboarding_screen.dart
            ├── shell/shell_screen.dart           ← 4-tab bottom nav + banner ad
            ├── home/home_screen.dart
            ├── leaderboard/leaderboard_screen.dart
            ├── profile/profile_screen.dart
            ├── chat/chat_screen.dart             ← group chat
            └── games/
                ├── jellad/
                │   ├── jellad_screen.dart        ← hangman game
                │   ├── hangman_painter.dart      ← CustomPainter
                │   └── turkmen_keyboard.dart     ← 4-row Turkmen keyboard with letter states
                ├── gunluk_soz/gunluk_soz_screen.dart   ← daily word
                ├── krosword/krosword_screen.dart        ← crossword (functional)
                ├── soz_zynjyry/soz_zynjyry_screen.dart ← word chain (functional)
                ├── yatkeslik/yatkeslik_screen.dart      ← memory match (functional)
                ├── suysurme/suysurme_screen.dart        ← stub
                ├── nanogram/nanogram_screen.dart        ← stub
                ├── zehin/zehin_screen.dart              ← stub
                └── puzzle/puzzle_screen.dart            ← stub
```

**Deleted / no longer used:**
- `core/widgets/no_games_sheet.dart` — replaced by auto-trigger rewarded ad pattern

---

## 4. Backend Models

### `HangmanWord`
`word` (uppercase), `hint`, `difficulty` (easy/medium/hard), `is_active`
256 Turkmen words seeded from original app. Used by Jellad, Günlük Söz, Krosword, Söz Zynjyry.

### `PuzzleImage`
`title`, `image` (ImageField → `puzzle_images/`), `game_type` (jigsaw/sliding/memory),
`difficulty`, `is_active`. Upload via Django admin.

### `ExternalApp`
`name`, `description`, `logo` (ImageField → `app_logos/`, optional), `ios_url`, `android_url`,
`order_position`, `is_active`.
**Seeded in `build.sh`:** Miclab and Dilbil (see URLs in section 7).
**Logo upload:** manual via Django admin → External Apps → logo field.

### `Player`
`uuid` (UUID4, device-generated — no passwords), `display_name`, `location` (freetext city/country),
`avatar_key` (10 preset emojis: eagle🦅 wolf🐺 lion🦁 horse🐎 fox🦊 owl🦉 bear🐻 tiger🐯 dragon🐉 star⭐),
`xp`, `level`, `streak_days`, `longest_streak`, `last_active`, `last_streak_date`

### `GameSession`
`player` FK, `game_type` (jellad/gunluk_soz/krosword/suysurme/yatkeslik/nanogram/zehin/puzzle/soz_zynjyry),
`word` FK (nullable), `won`, `wrong_guesses`, `score`, `played_at`

Score formula: `100 + (6 - wrongGuesses) * 15 + difficulty_bonus` (easy:0 medium:20 hard:40). 0 if lost.
XP = score ÷ 10.

### `DailyWord`
`word` FK, `date` (unique). Auto-assigned if none exists for today.

### `Achievement`
`name`, `name_tk`, `description_tk`, `icon` (emoji), `condition_type` (streak_days/games_won/total_xp/perfect_games/daily_wins), `condition_value`, `xp_reward`
8 achievements seeded in `build.sh`.

### `PlayerAchievement`
`player` + `achievement` join, `earned_at`. Checked and awarded on every score submission.

### `ChatMessage`
`player` FK, `message` (max 500 chars), `created_at`. Global group chat, no moderation yet.

---

## 5. API Endpoints

Base URL: `https://sozbil-hangman-backend.onrender.com`

| Method | Path | Description |
|---|---|---|
| GET | `/api/word/` | Random word (legacy Android app) |
| GET | `/api/words/` | All active words (used by Krosword, Söz Zynjyry) |
| GET | `/api/daily/` | Today's daily word |
| POST | `/api/player/register/` | Register player (sends uuid+name+location+avatar_key) |
| GET/PUT | `/api/player/<uuid>/` | Get or update player profile |
| POST | `/api/score/` | Submit game result (updates XP, streak, achievements) |
| GET | `/api/leaderboard/` | Top 100 players (`?filter=weekly` or `?location=...`) |
| GET | `/api/puzzles/<game_type>/` | Puzzle images for a game type |
| GET | `/api/apps/` | External partner apps (Miclab, Dilbil) |
| GET | `/api/achievements/` | All active achievements |
| GET | `/api/chat/` | Latest 60 chat messages (oldest-first, `?before_id=N` for pagination) |
| POST | `/api/chat/` | Send chat message (`{player_uuid, message}`) |
| GET | `/api/stats/` | Platform stats |
| GET | `/health/` | Health check |

---

## 6. Flutter Key Details

### Identity
Device generates a UUID on first launch (via `StorageService`). Stored in SharedPreferences.
No passwords, no sign-in. UUID sent with every API call.

### Game limits & ad monetisation logic

**Core rules (never show credit counts to the user — they must never know):**
- 20 free games/day, resets at midnight
- When free games run out → rewarded ad plays **automatically** (no prompt, no dialog)
- Watching the ad grants +10 bonus games
- No cap on number of ads per day
- Subscribers (`isSubscribed = true`) → unlimited games, no ads of any kind

**Banner ad (`BannerAdWidget`):**
- Appears on **every screen** — all 4 shell tabs (home, leaderboard, chat, profile) and all game screens
- Placed in `shell_screen.dart` above the bottom nav bar (covers all tabs automatically)
- Also included individually in each game screen's column above safe-area padding
- `BannerAdWidget` is a `ConsumerWidget` — it checks `storageServiceProvider.isSubscribed` itself
  and returns `SizedBox.shrink()` for subscribers. No external wrapper needed.
- Uses `AdSize.banner` (320×50). Silent failure if ad not loaded.
- Test ID in `kDebugMode`, real IDs in release.

**Rewarded ad (`RewardedAdService`):**
- Called `load()` in `initState` of every game screen to preload
- When credits run out: `_rewardedAd.show(onRewarded: ..., onFailed: ...)` fires immediately
  with no user-facing prompt
- `onRewarded`: calls `storage.addRewardGames(gamesPerAd, gamesPerAd)` then retries the game
- `onFailed` (ad not ready): `Navigator.pop(context)` — screen closes silently
- Rewarded ads **never trigger for subscribers** because `storage.canPlay()` always returns
  `true` for them (returns 999999 remaining games), so the ad gate is never reached

**Implementation pattern (same in all game screens):**
```dart
void _autoShowRewardedAd() {
  _rewardedAd.show(
    onRewarded: () {
      storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
      ref.read(gameLimitProvider.notifier).refresh();
      _loadGame(); // retry
    },
    onFailed: () { if (mounted) Navigator.pop(context); },
  );
}
```

**`StorageService` game-limit methods:**
- `canPlay(isSubscribed, dailyLimit)` → bool
- `consumeGame(isSubscribed)` — deducts from reward pool first, then daily count
- `addRewardGames(count, gamesPerAd)` — adds to reward pool
- `getRemainingGames(isSubscribed, dailyLimit)` → int (999999 for subscribers)

**`ApiConstants` relevant values:**
- `dailyFreeGames = 20`
- `gamesPerAd = 10`

### No-repeat words (Jellad)
Used word IDs stored as `Set<String>` in SharedPreferences. Cleared after 40 words to prevent
exhaustion. Managed by `StorageService.addUsedWord()` / `getUsedWords()` / `clearUsedWords()`.

### XP Levels
| Level key | Display | XP range |
|---|---|---|
| baslangyc | Başlangyç | 0–99 |
| okuwcy | Okuwçy | 100–299 |
| oyuncy | Oýunçy | 300–599 |
| ustat | Ussат | 600–999 |
| meshur | Meşhur | 1000–1999 |
| legenda | Legenda | 2000+ |

### Turkmen keyboard layout
Row 1: Ä W E R T Y U I O P
Row 2: Ö A S D F G H J K L
Row 3: Ň Ş Z Ü Ç Ý B N M Ž
Row 4: C V X Q

Jellad uses `TurkmenKeyboard` (shows correct/wrong/unused letter states via `LetterState` enum).
Söz Zynjyry and Krosword use their own inline `_WordKeyboard` / `_CrosswordKeyboard` widgets
(same layout, no letter-state colouring, ⌫ delete key, last row slightly different).

### Colors (`AppColors`)
- Primary: `#5B5BD6` (purple)
- PrimaryLight: `#EEEDF E` (light purple, used for selected crossword cells)
- Accent: `#EF9F27` (amber)
- Success: `#1D9E75` (green)
- SuccessLight: `#E1F5EE`
- Error: `#E24B4A` (red)
- ErrorLight: `#FCEBEB`
- Background: `#F7F6F3` (warm off-white)
- Surface: `#FFFFFF`
- SurfaceSecondary: `#F1EFE8`
- Border: `#D3D1C7`
- BorderLight: `#ECFAE3`
- TextPrimary: `#1A1A2E`
- TextSecondary: `#5F5E5A`
- TextHint: `#888780`
- Streak: `#FF6B35`

### UI Design principles (Emil Kowalski style)
- No visible borders on cards — use `boxShadow` instead
- Font weight 700–800 for headings and key labels
- `AnimatedScale` press feedback on tappable cards (scale: 0.96 on press)
- Active game cards: white surface + shadow. Stub games: muted `surfaceSecondary`, no shadow
- Streak shown as compact `🔥 N` badge (no "games remaining" counter anywhere)
- Premium label only shown for subscribers

### Bottom nav tabs (4 tabs)
1. Oýunlar (`/home`) — game grid
2. Reýting (`/leaderboard`) — leaderboard
3. Söhbet (`/chat`) — group chat
4. Profil (`/profile`) — player profile

### Tablet layout
Home grid `crossAxisCount`: `isTablet` (width > 600) ? 4 : 3
Ýatkeşlik grid columns: width > 900 → 6, width > 600 → 5, else → 4

### Chat screen
Polls every 5 seconds for new messages. My messages: right side, purple bubble.
Others: left side, white bubble + emoji avatar. Max message length: 500 chars.

---

## 7. Partner Apps

| App | iOS | Android |
|---|---|---|
| Miclab (karaoke) | https://apps.apple.com/tr/app/miclab/id6755495875 | https://play.google.com/store/apps/details?id=com.miclab.app |
| Dilbil (language learning) | https://apps.apple.com/tr/app/dilbil/id6760611346 | https://play.google.com/store/apps/details?id=com.dilbil.app |

Logos must be uploaded manually via Django admin → External Apps → logo field.
build.sh seeds the records with URLs but leaves logo blank.

---

## 8. Deployment

### Backend (Render.com)
1. Set env var: `DATABASE_URL=postgresql://...` (Supabase connection string)
2. Render runs `build.sh` on every deploy: installs deps, collectstatic, migrate, seeds achievements + partner apps
3. Word data: local `sample_data.json` → `python manage.py loaddata sample_data.json`

### Flutter
```bash
cd sozbil_flutter
flutter pub get
flutter run                    # debug
flutter build apk --release    # Android
flutter build ipa              # iOS (requires Mac + Xcode)
```

Bundle ID: `com.sozbil.app.SozBil`

---

## 9. AdMob IDs

- Banner Android: `ca-app-pub-7668467791782601/XXXXXXXX` ← **fill in real ID**
- Rewarded Android: `ca-app-pub-7668467791782601/5377390036`
- iOS IDs: not yet filled in
- Test banner: `ca-app-pub-3940256099942544/6300978111`
- Test rewarded: `ca-app-pub-3940256099942544/5224354917`
- AdMob App ID (iOS Info.plist `GADApplicationIdentifier`): `ca-app-pub-3940256099942544~1458002511` (test)

During development, test IDs are used (`kDebugMode` check in both `BannerAdWidget` and `RewardedAdService`).
Switch to real IDs before release.

---

## 10. In-App Purchase IDs

- Monthly subscription: `sozbil_premium_monthly` ($1.99/month)
- Yearly subscription: `sozbil_premium_yearly` ($7.99/year)
Must be created in Google Play Console and App Store Connect before use.
`isSubscribed` flag stored in SharedPreferences via `StorageService.setSubscribed()`.

---

## 11. Games Status

| Game | Turkmen name | Status |
|---|---|---|
| Jellad | Jellad (Hangman) | ✅ Functional |
| Daily word | Günlük Söz | ✅ Functional |
| Crossword | Krosword | ✅ Functional |
| Word chain | Söz Zynjyry | ✅ Functional |
| Memory match | Ýatkeşlik | ✅ Functional |
| Sliding puzzle | Süýşürme | 🔲 Stub |
| Picross | Nanogram | 🔲 Stub |
| IQ puzzles | Zehin Oýunlary | 🔲 Stub |
| Jigsaw | Puzzle | 🔲 Stub |
| Partner tile | Miclab | ✅ Links to store |
| Partner tile | Dilbil | ✅ Links to store |

The 256 Turkmen words from the original hangman app (`/api/words/`, `allWordsProvider`) are the
single shared vocabulary pool used by Jellad, Günlük Söz, Krosword, and Söz Zynjyry.

---

## 12. Game Implementation Notes

### Jellad (Hangman)
- Fetches random word from `/api/word/` (legacy) via `api.getRandomWord()`
- 6 wrong guesses allowed; `HangmanPainter` draws the figure step by step
- No-repeat: used word strings stored in SharedPreferences, cleared after 40
- Win dialog shows score + XP gained; share button sends Telegram-ready text via `share_plus`
- Keyboard: `TurkmenKeyboard` widget with per-letter `LetterState` (correct/wrong/unused)

### Günlük Söz (Daily Word)
- Fetches from `/api/daily/`; same word for all users each day
- One attempt per day enforced client-side

### Söz Zynjyry (Word Chain)
- Dictionary loaded from `assets/words/turkmen_dict.txt` via `rootBundle.loadString`
- Format: one word per line, plain text, any case (uppercased on load)
- Words must be ≥ 2 characters; stored as `Set<String>` for O(1) lookup
- Rules: each word must start with the last letter of the previous word; 3 lives; 30-second turn timer
- Game starts with a random seed word from the pool
- Custom `_WordKeyboard` (Turkmen layout + ⌫ + ✓ submit)

### Ýatkeşlik (Memory Match)
- 12 hardcoded emoji↔Turkmen-word pairs (24 cards total, 6×4 grid)
- Pairs: 🦅 BÜRGÜT, ☀️ GÜN, 🏔️ DAG, 🌹 GÜL, 🌊 TOLKUN, ⭐ ÝYLDYZ, 💧 SUW, 🏠 ÖÝ, 🦁 ARYSLAN, 🌲 AGAÇ, 🐟 BALYK, 🔥 ALAW
- `LayoutBuilder` responsive grid: 4 cols phone / 5 tablet / 6 large tablet
- Card size = `(screenW - hPad*2 - gap*(cols-1)) / cols`; emoji font = `cardSize * 0.42`

### Krosword (Crossword)
- Word source: `allWordsProvider` → `GET /api/words/` (same 256-word HangmanWord pool, includes hints)
- **Generator algorithm** (`_Puzzle.generate`):
  - 15×15 grid, cell size 36px, `InteractiveViewer` for pinch-zoom
  - Places first word across the centre row
  - Greedy: for each candidate word, tries to intersect (perpendicularly) with every already-placed word
  - Runs up to 10 shuffle attempts; accepts first result with ≥ 6 words; caps at 14 words
- **Strict crossword rules enforced in `_canPlace`:**
  1. No letter immediately before the start or after the end of a word (no extensions)
  2. No adjacent parallel words — each non-intersection cell's perpendicular neighbours must be empty
  3. **No same-direction cell sharing** — tracked via `acrossSet` and `downSet` (`Set<(int,int)>`).
     Even if two parallel words share the same letter at the same position, the placement is
     rejected. Only a perpendicular (across↔down) crossing is valid.
  4. Every placed word must cross at least one existing word
- Clue numbers assigned left-to-right, top-to-bottom (standard crossword convention)
- **UI:** `CustomPaint` grid painter; tap a cell → selects the word through it; tap a crossing cell
  again → toggles between across/down; cursor auto-advances on letter input
- Clue bar above keyboard shows `3A` / `7D` badge + hint text
- Keyboard: `_CrosswordKeyboard` (Turkmen layout + ⌫, no submit key)

---

## 13. Known Facts / Decisions

- **No provinces dropdown** — location is pure freetext (users write "Aşgabat", "Ankara", "Berlin", etc.)
- **SQLite on Render is ephemeral** — all production data must live in Supabase PostgreSQL
- **Old Android app** exists at `/sozbil/` subfolder — keep `/api/word/` endpoint working for it
- **Telegram share** is the main retention hook (Central Asian market uses Telegram heavily)
- The `hangman_backend/` folder is what's deployed to Render — not the `sozbil/` subfolder (old app)
- `build.sh` is idempotent — safe to run on every deploy
- **Never tell users their game credit count** — the credit system is invisible to users
- **`no_games_sheet.dart` is dead code** — delete it. The correct pattern is to call
  `_rewardedAd.show(...)` directly when `!storage.canPlay(...)` returns false

---

## 14. Pending / Future Work

- [ ] Implement Süýşürme (sliding tile puzzle) with images from PuzzleImage API
- [ ] Implement Nanogram (picross)
- [ ] Implement Zehin Oýunlary (IQ/logic puzzles)
- [ ] Implement Puzzle (jigsaw) with images
- [ ] Upload Miclab and Dilbil logos via Django admin
- [ ] Fill in real AdMob banner Android ID in `api_constants.dart`
- [ ] Fill in real AdMob iOS IDs in `api_constants.dart`
- [ ] Replace test `GADApplicationIdentifier` in `ios/Runner/Info.plist` with real App ID
- [ ] Create IAP products in Google Play Console + App Store Connect
- [ ] Wire up `isSubscribed` toggle when IAP purchase is confirmed
- [ ] Chat moderation (admin can delete messages; already in Django admin)
- [ ] Push notifications for streaks / daily word reminders
- [ ] Telegram share result button in Jellad (share_plus — partially wired, needs deep link)
- [ ] Delete `core/widgets/no_games_sheet.dart` (orphaned)
