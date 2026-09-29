# Button Elevation & Affordance Rule

## Core Requirement
All buttons across the application must have visible elevation or shadows so users can easily and intuitively recognize that an element on screen is an interactive button.

## Guidelines
1. **Visible Elevation & Shadow**:
   - Every button (`FilledButton`, `ElevatedButton`, `OutlinedButton`, custom button containers) must provide a noticeable resting elevation (e.g. `elevation: 2` or `elevation: 3`) with a soft shadow (`shadowColor`).
   - Avoid completely flat buttons without depth, as flat elements lack clear interactive affordance in POS / management interfaces.
2. **Theme Configuration**:
   - Global `ThemeData` must define `filledButtonTheme`, `elevatedButtonTheme`, and `outlinedButtonTheme` with default elevation and shadow styling so all standard buttons inherit depth automatically.
3. **Floating & Primary Action Buttons**:
   - Primary actions and modal action buttons should use higher prominence with `elevation: 2` or `elevation: 3` and matching shadow tint.
