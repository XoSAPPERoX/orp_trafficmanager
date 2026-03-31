# 🚦 ORP Traffic Manager

A modern, draggable Traffic Control system for FiveM with synced zones, character-based placement, and a clean NUI that matches ox_lib styling.

---

## ✨ Features

* 🎛️ Draggable custom UI (position saved per player)
* 🌐 Fully synced traffic zones (all players see the same scene)
* 👮 Job + duty restricted (QBX supported)
* 🧑‍✈️ Displays **character name** of the officer who placed the scene
* ⏱️ Auto-expire after 10 minutes
* 📍 Minimap marker labeled **"Active Scene"**
* 📏 Adjustable radius (20m – 100m)
* 🚦 Stop / Slow / Resume traffic controls
* 🔄 Smart UI state (buttons disable when already active)
* 🔔 Uses **ox_lib notifications**

---

## 📦 Requirements

* Qbox / QBX Core
* ox_lib

---

## 📥 Installation

1. Place the resource in your server:

```bash
resources/[orp]/orp_trafficmanager
```

2. Add to your `server.cfg`:

```cfg
ensure ox_lib
ensure orp_trafficmanager
```

3. Restart your server.

---

## 🎮 Usage

### Open Menu

* Default Keybind: **F10**
* Command:

```bash
/traffic
```

You can change the keybind in:
**ESC → Settings → Key Bindings → FiveM**

---

## 🚦 How It Works

* Only **one active traffic scene** at a time
* Creating a new zone replaces the existing one
* All players receive the update instantly
* Scene auto-expires after 10 minutes
* Players joining mid-session will see the active scene

---

## 🔒 Permissions

Restricted to:

* police
* bcso
* sasp
* safr

Must be **on duty**.

---

## ⚙️ Configuration

### Allowed Jobs

Edit in `server.lua`:

```lua
local allowedJobs = {
    police = true,
    safr = true,
    bcso = true,
    sasp = true,
}
```

---

### Radius Limits

```lua
if radius < 20 then radius = 20 end
if radius > 100 then radius = 100 end
```

---

### Zone Duration

```lua
local ZONE_DURATION_MS = 10 * 60 * 1000
```

---

## 🎨 UI Features

* Clean ox_lib-inspired styling
* Active state indicator (Stopped / Slowed / None)
* Shows:

  * Placed By (Character Name)
  * Time Remaining
* Fully draggable + position saved

---

## ⚠️ Notes

* Uses GTA speed zones (AI behavior is limited by game engine)
* Notifications powered by ox_lib
* Keybinds may require reconnect after first setup

---

## 🛠️ Troubleshooting

### Menu doesn’t open

* Check job name matches exactly
* Ensure player is on duty
* Verify QBX export is correct

---

### Notifications not working

* Ensure `ox_lib` is started before this resource

---

## 📸 Preview

*(Add screenshots here if you want)*

---

## 📜 License

Feel free to use and modify. Do not resell.

---

## 👑 Credits

Developed for ORP
Built with a focus on realism, usability, and clean UI design
