# Smart Potion Macro

Automatically updates a macro to use the best available Light's Potential potion.

## Features

- Selects the best available potion:
  - Fleeting Light's Potential (High Quality)
  - Fleeting Light's Potential
  - Light's Potential (High Quality)
  - Light's Potential
- Updates automatically when:
  - Logging in
  - Bags change
  - Leaving combat
- Settings panel included
- Optional debug output
- Configurable behavior when no potion is available

## Commands

/smartpotion           - Open settings  
/smartpotion update    - Force macro update  
/smartpotion debug     - Toggle debug output  

## Notes

- Macro updates only occur outside of combat
- Designed for Midnight expansion potions
- Disclosure: This started as a personal project and the vast majority of the code was written with the aid of ChatGPT. I hope to get more comfortable with lua coding in the future, but this was the easiest way for me to get started.
