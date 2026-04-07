<div align="center">
  <h1>⚔️ SOVEREIGN PROTOCOL (Habit Quest) ⚔️</h1>
  <p><i>Level up your life in the real world. A gamified habit-tracking application built with Flutter.</i></p>
</div>

<br />

## 🌟 About The Project

**Sovereign Protocol** (also known as Habit Quest) transforms your daily routines into epic RPG quests. Drawing aesthetic inspiration from litRPG/system interfaces (e.g., Solo Leveling), this application visualizes your real-life progress as hard **Stats**, **Levels**, and **Ranks**!

Abandon the boring checklists and step into the System. Drink water to boost your Stamina; read a book to increase your Intellect; complete quests to witness your "Hunter Class" rise.

---

## 🚀 Key Features

- **Gamified Progression**: Complete tasks and instantly watch your Core Stats (`STRENGTH`, `AGILITY`, `INTELLECT`, `VITALITY`) increase using dynamic point scaling.
- **Hunter Profiles**: A fully animated Profile dashboard showcasing your total Level, Rank, overall aggregate ratings, and individual XP bars for different traits.
- **Dynamic Task Icons**: Automatically categorized tasks represented by distinct minimalist icons.
- **Visual Feedback**: Every completed quest triggers explosive `Confetti` celebrations to build healthy dopamine loops.
- **Terminal UI/UX**: Striking Monospaced typography, bold borders (`pureBlack`), and striking highlight colors (`neonGreen`, `deepRed`) that deliver an immersive "System" prompt illusion.
- **Authentication Flow**: Quick and elegant account creation with simulated login handling and personalized routing.

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Typography:** `google_fonts` (Roboto Mono)
- **Animations:** `flutter_animate` (Sleek fade-ins and slides)
- **Visuals:** `percent_indicator` (Progress bars), `confetti` (Celebration particle systems)

---

## 🔑 Test Credentials (Demo Mode)

The app ships with a local authentication prototype. You can register a new account on the splash screen, or use any of the existing demo agents:

| Full Name         | Username        | Password    |
|-------------------|-----------------|-------------|
| Faizan Ahmad      | `faizan`        | `shadow123` |
| Admin Route       | `admin`         | `admin`     |
| Sharjeel Farsheed | `sharjeel`      | `sharj`     |
| Nouman Ahmed      | `wannabenomi`   | `nomi`      |

---

## 💻 Getting Started

To run this application locally, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/QuestHabit.git
   ```
2. **Navigate to the directory:**
   ```bash
   cd QuestHabit
   ```
3. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🔮 Future Roadmap (v2.0)

- [ ] **Data Persistence:** Migrate local stat tracking to a persistent database (e.g., `Hive` or `SQLite`).
- [ ] **Global State Management:** Introduce `Riverpod` or `Provider` to synchronize live Dashboard stats across the Profile rendering instantly.
- [ ] **Dynamic Quest Creation:** Implement a floating action button and modal for hunters to create and tag custom daily objectives.
- [ ] **Leaderboards:** Activate the `RANKING` tab with global top performers.

---

<div align="center">
  <p><b>"Arise, Player."</b></p>
  <i>Built with ❤️ using Flutter.</i>
</div>
