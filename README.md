# EncumbranceTracker for D&D 5E (Fantasy Grounds Unity & Classic)

[![GitHub](https://img.shields.io/badge/GitHub-JustinFreitas%2FEncumbranceTracker-blue.svg)](https://github.com/JustinFreitas/EncumbranceTracker)

**EncumbranceTracker** is a Fantasy Grounds extension for the **D&D 5E** ruleset that automates encumbrance tracking (both standard and 5E variant encumbrance) in the Combat Tracker. It applies automated speed and penalty effects, validates carrying capacity multipliers, and outputs SRD encumbrance rule reminders to the GM.

---

## Key Features

1. **Automated Combat Tracker Encumbrance Effects**:
   * On every turn activation in the Combat Tracker (or manual command), EncumbranceTracker evaluates player carrying weight against their Strength score.
   * Automatically applies appropriate automated status effects to the CT entry:
     * **Lightly Encumbered**: `Speed -10 ft`
     * **Heavily Encumbered**: `Speed -20 ft; DISCHK: strength, dexterity, constitution; DISSAV: strength, dexterity, constitution; DISATK;`
     * **Over Encumbered**: `Speed 5 ft; DISCHK: strength, dexterity, constitution; DISSAV: strength, dexterity, constitution; DISATK;`
     * **Unencumbered**: Automatically clears stale encumbrance effects.

2. **5E Standard & Variant Encumbrance Support**:
   * Seamlessly detects whether the campaign is using Standard or Variant 5E encumbrance (`House Rules: Encumbrance` option).
   * Fully implements the three tiers of Variant Encumbrance (`5x STR`, `10x STR`, `15x STR`).

3. **Carrying Capacity Multipliers**:
   * Evaluates racial traits, class features, and feats that double or increase carrying capacity:
     * **Equine Build** (e.g. Centaur): Multiplier of 2x.
     * **Aspect of the Beast: Bear** (Barbarian Level 6+): Multiplier of 2x.
     * **Beast of Burden**: Multiplier of 2x.
   * Includes GM override options to toggle specific multipliers.
   * Fully accounts for creatures with the "No Encumbrance" trait (exempt from encumbrance penalties).

4. **Inventory Auditing & Statistics**:
   * Optional GM alerts for zero-weight items (e.g. tracking containers or missing gear weight).
   * Optional counts for uncarried items (stored in containers or on mounts/vehicles).

5. **Host-Only Privacy & Database Resilience**:
   * Chat output stays local to the GM (`bSecret = true`), keeping inventory management clean and private.
   * Options lookups fall back to database values (`options.*`), ensuring stable performance across all client and host configurations.

---

## Chat Commands

| Command | Description |
| :--- | :--- |
| `/et` or `/encumbrance` | Runs an immediate encumbrance analysis across all PCs in the Combat Tracker, updating effects and reporting status to the GM. |

---

## Configuration Settings (GM Options)

Located under the **Options** window in the **EncumbranceTracker (GM)** section:

| Option | Values | Default | Description |
| :--- | :--- | :--- | :--- |
| **CT: Use Effects** | `On` / `Off` | `On` | When enabled, applies encumbrance status effects to CT entries. |
| **Chat: Extension Verbosity** | `Off` / `Standard` / `Max` | `Standard` | Controls overall chat output volume. |
| **Chat: Show rule detail** | `On` / `Off` | `On` | Displays SRD encumbrance rule reminders when encumbrance state changes. |
| **Chat: Show stats** | `On` / `Off` | `On` | Displays carrying load vs max capacity numbers in chat. |
| **Chat: Show zero weight count** | `On` / `Off` | `Off` | Reports the number of items with zero or unrecorded weight. |
| **Chat: Show uncarried items count**| `On` / `Off` | `Off` | Reports the number of inventory items marked uncarried. |
| **Override: Aspect of the Bear multiplier** | `On` / `Off` | `On` | Toggles the 2x carrying capacity multiplier for Barbarians with Bear Aspect. |
| **Override: Equine Build multiplier** | `On` / `Off` | `On` | Toggles the 2x carrying capacity multiplier for Centaurs and equine races. |
| **Override: Beast of Burden multiplier** | `On` / `Off` | `On` | Toggles the 2x multiplier for Beast of Burden traits. |

---

## Compatibility

* **Fantasy Grounds Unity (FGU)** & **Fantasy Grounds Classic (FGC)**
* **Ruleset**: D&D 5E (2014 & 2024 compatible)
* Fully interoperable with **StealthTracker**, **MountTracker**, and **LanguageTracker**.

---

## Version History

* **v1.6.2** (October 2026):
  * Added database fallback for encumbrance option helpers.
  * Standardized build package script and Forge documentation.
* **v1.6.1** (September 2026): Restored dual FGC/FGU compatibility, resolved single-argument actor resolution on FGC, added defensive nil guards, and protected `/reload` idempotency.
* **v1.6** (June 2026): Exempted 0 multiplier traits ("No Encumbrance"), cleaned up stale effects, and fixed nil actor guards.
* **v1.5** (May 2026): Modern CoreRPG functions (`StringManager.isBlank`), safe helper patterns, and typo fixes.
* **v1.0** (May 2021): Initial release.
