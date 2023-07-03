# EncumbranceTracker

https://github.com/JustinFreitas/EncumbranceTracker

EncumbranceTracker v1.2.1, by Justin Freitas

ReadMe and Usage Notes

This 5e based extension will monitor the PC's encumbrance on every Combat Tracker activation of an actor (clicking that row to move the turn to a PC or simply the Next Actor button) or via a chat command (either /et or /encumbrance).  If a PC is encumbered according to the 5e rules (standard or variant/optional), an effect will be placed on the CT actor designating the encumbrance level (mostly applicable to variant encumbrance) and some rules around that encumbrance level will be displayed (if configured in the options).

GM EncumbranceTracker Chat Commands:

/et or /encumbrance - This will run the encumbrance analysis on all of the PCs in the Combat Tracker, even if combat is not active.

Features:
- Each turn of combat (or whichever CT actor is clicked on in the left turn ordering by the DM), the entire list of CT actors is processed for PC encumbrance.  If a PC gets classified at a particular level of encumbrance, an effect will be added to the CT actor to designate it as such.  Some of these effects will have automation syntax attached to them, when possible.  The level of summary verbosity can be controlled by some settings in the FG Options.  These include options like the display of rule help from the SRD for variant encumbrance details.


Changelist:
- v1.0 - Initial version.
- v1.1 - Better turn order firing in combat.  Formatting improvements.  Bug fixes.  Strength less than zero filtered out.
- v1.2 - Added an option to disable the use of effects, if desired.  Defaults to enabled/on.
- v1.2.1 - Updated icon using Sir Motte's template for their dark theme.