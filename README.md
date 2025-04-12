## Introduction

**Senne** is a lightweight and efficient
[PowerShell](https://wikipedia.org/wiki/PowerShell) script designed to
automatically switch your [Windows 10](https://wikipedia.org/wiki/Windows_10)
or [Windows 11](https://wikipedia.org/wiki/Windows_11) system theme
(light/dark) based on the current time of day and real-world sunrise/sunset
data. By leveraging the
[Nominatim OpenStreetMap API](https://nominatim.openstreetmap.org/) and the
[Sunrise-Sunset API](https://sunrise-sunset.org/api), the script determines the
appropriate theme by checking your specified location's sunrise and sunset
times.

### Key Features

- **Automatic Theme Switching** - Changes the system theme to light during
  daylight hours and dark at night or before sunrise.
- **Geolocation-Based Scheduling** - Uses your provided location name to fetch
  precise sunrise and sunset times.
- **System-Wide Application Theme Sync** - Ensures all compatible apps follow
  the system theme.
- **Lightweight & Efficient** – No architecture-specific requirements (works
  on x86, x86-64, ARM).
- **Task Scheduler Integration** – Runs seamlessly in the background via
  Windows Task Scheduler.

### How It Works

1. **Geolocation Lookup** – The script queries
   [Nominatim OpenStreetMap API](https://nominatim.openstreetmap.org/) to
   convert your location name into geographic coordinates.

2. **Sunrise/Sunset API Call** – Using the obtained coordinates, it fetches
   accurate sunrise and sunset times from
   [Sunrise-Sunset API](https://sunrise-sunset.org/api).

3. **Theme Adjustment** - Compares the current system time with the
   sunrise/sunset data and applies:
     - **Dark theme** if before sunrise or after sunset.
     - **Light theme** if between sunrise and sunset.

4. **System-Wide Consistency** – All theme-aware applications (e.g., Microsoft
   Edge, File Explorer) update accordingly.

## Installation

Since **senne** requires **Task Scheduler configuration** and
**administrator privileges**, it is best suited for users comfortable with
PowerShell and Windows automation.

### Requirements

- **System**: [Windows 10](https://pl.wikipedia.org/wiki/Windows_10) or
[Windows 11](https://pl.wikipedia.org/wiki/Windows_11)
- **Internet**: Good enough to be able to send 1-2 requests and download 10-30 KB 
of data.

## Special thanks

This script would **never** have worked without the generosity of
**open-source**and **free-to-use APIs** that provide essential data without any
restrictions, API keys, or hidden costs. A huge thank you to:

- **[Nominatim OpenStreetMap API](https://nominatim.openstreetmap.org/)** – For
  offering free, reliable geocoding services that convert location names into
  precise coordinates.

- **[Sunrise-Sunset API](https://sunrise-sunset.org/api/)** – For delivering
  accurate sunrise and sunset times based on geographic coordinates, enabling
  seamless theme switching.

Your commitment to open data and accessibility makes projects like **senne**
possible. Thank you for supporting developers and enthusiasts worldwide!

_If you find these services useful, consider supporting their initiatives
(if possible) to help keep them freely available for others._

## License

This project is licensed under the **WTFPL (Do What The F*ck You Want To
Public License)**. This means you are free to use, modify, distribute, and even
sell the code - **without any restrictions**. You don’t need to include
attribution, though it’s always appreciated.

For more details (or if you just want a good laugh), check out the full license 
text in the [LICENSE](https://github.com/kvdpxne/senne/blob/master/LICENSE)
file.

**TL;DR:** Do whatever you want. No warranties. Enjoy! 🎉