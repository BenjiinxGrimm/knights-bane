# Knights Bane

Top-down roguelike with a voxel aesthetic and Elden Ring-inspired combat. You play as an assassin — fast, precise, built around reading telegraphs and punishing windows rather than tanking hits.

This is a work-in-progress vertical slice. The goal is to get combat feeling good before building anything else.

## Current state

Combat prototype — one room, two enemy types, no progression. Placeholder capsule art.

What's working:
- Movement, sprint, dodge roll with i-frames and stamina cost
- Light and heavy attack with separate timing and stamina economy
- Melee enemy: chases, telegraphs attack with a color shift, has a counter-attack window
- Ranged enemy: maintains distance, telegraphs shots, fires projectiles
- Hit feedback: screenshake, hit pause, particles, sound

## Controls

| Action | Keyboard | Controller |
|--------|----------|------------|
| Move | WASD | Left stick |
| Sprint | Left Shift | Right bumper |
| Light attack | Left click | A / Cross |
| Heavy attack | Right click | B / Circle |
| Dodge | Space | X / Square |
| Aim | Mouse | (mouse only for now) |

## Running the project

Requires **Godot 4.6**. Open `project.godot` in the Godot editor and press Run, or export a build from the editor.

## Built with

- Godot 4 (Jolt physics, Forward Plus renderer)
- Sound effects: Kenney Impact Sounds + RPG Audio (CC0)
