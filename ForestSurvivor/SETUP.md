# Forest Survivor — Xcode Setup Guide

## Quick Start

### 1. Create Xcode Project
1. Open Xcode → New Project → Game
2. Product Name: **ForestSurvivor**
3. Interface: **SwiftUI**, Game Technology: **SpriteKit**, Language: **Swift**
4. Copy all source files from this folder into the project

### 2. Project Settings
```
Build Settings:
  IPHONEOS_DEPLOYMENT_TARGET = 15.0
  TARGETED_DEVICE_FAMILY = 1  (iPhone only)
  SWIFT_VERSION = 5.0

Info.plist:
  UISupportedInterfaceOrientations → Portrait only
  UIRequiresFullScreen → YES
  UIStatusBarHidden → YES
```

### 3. Add Fonts
- Download `PressStart2P-Regular.ttf` and `VT323-Regular.ttf` from Google Fonts
- Add to Xcode target
- Add to Info.plist under `UIAppFonts`

### 4. Add Sprites (Free)
Download from https://kenney.nl:
- **Tiny Dungeon** → player & enemy sprites
- **Nature Kit** → trees, rocks, environment
- **UI Pack** → buttons, bars, panels
- **Particle Pack** → particle textures

Rename sprites to match:
```
archer_idle_00..03.png   archer_walk_00..05.png
wolf_walk_00..05.png     wolf_death_00..03.png
bat_fly_00..03.png       boar_walk_00..05.png
troll_walk_00..05.png    golem_walk_00..05.png
coin_00..03.png          arrow.png  ground_tile.png
joystick_base.png        joystick_thumb.png
upgrade_card_bg.png
```

### 5. Add Sounds
See `Resources/Sounds/README.md`

### 6. AdMob (Optional)
```
File → Add Package Dependency →
https://github.com/googleads/swift-package-manager-google-mobile-ads
```
Then in `ForestSurvivorApp.swift` and `AdManager.swift` uncomment the GAD lines
and replace placeholder ad unit IDs.

## File Structure
```
ForestSurvivor/
├── App/
│   ├── ForestSurvivorApp.swift   ← @main entry
│   └── ContentView.swift         ← SpriteKit wrapper
├── Scenes/
│   ├── SplashScene.swift
│   ├── MenuScene.swift
│   ├── GameScene.swift           ← core loop
│   ├── UpgradeScene.swift
│   └── GameOverScene.swift
├── Entities/
│   ├── Player.swift
│   ├── Arrow.swift
│   ├── Coin.swift
│   └── Enemies/
│       ├── Enemy.swift (base)
│       ├── Wolf.swift
│       ├── Bat.swift
│       ├── Boar.swift
│       ├── VineCreature.swift
│       ├── Troll.swift
│       └── AncientGolem.swift
├── Systems/
│   ├── SpawnSystem.swift
│   ├── CombatSystem.swift
│   ├── UpgradeSystem.swift
│   ├── WaveSystem.swift
│   └── CoinSystem.swift
├── Managers/
│   ├── GameManager.swift
│   ├── AudioManager.swift
│   ├── AdManager.swift
│   └── SaveManager.swift
├── UI/
│   ├── HUDNode.swift
│   ├── JoystickNode.swift
│   ├── HPBarNode.swift
│   ├── BossHPBarNode.swift
│   └── UpgradeCardNode.swift
├── Models/
│   ├── PlayerStats.swift
│   ├── EnemyData.swift
│   ├── UpgradeData.swift
│   └── GameSession.swift
└── Utils/
    ├── Constants.swift
    ├── PhysicsCategory.swift
    └── Extensions.swift
```

## Game Systems Summary
- **Player**: virtual joystick movement, auto-attack, regen, blink dash, second wind
- **Enemies**: Wolf, Bat (sinusoidal), Boar (dodge), VineCreature (slow), Troll (pack leader), Golem (boss, 2 phases, rock attack)
- **Upgrades**: 18 upgrades across attack/defense/utility, weighted random selection
- **Wave System**: upgrade every 60s, boss every 5 min, enemy scaling per wave
- **Economy**: coins from kills + minute bonuses, saved as high score
- **Ads**: interstitial after game over (every 2nd), rewarded revive
- **Save**: UserDefaults — high score, kills, games played, settings
