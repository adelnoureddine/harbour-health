# Health for SailfishOS

Health is a private health tracker for SailfishOS. All health data is stored locally on the device, and the application has no network permissions.

Health is not medical advice and must not be used for diagnosis or treatment decisions.

# Features

- Multiple profiles, each with its own data and its own dashboard
- Track weight, height, BMI, water, calories, heart rate, blood pressure and glucose
- History graphs for every metric, with editable reference ranges shaded behind them
- Health conditions, treatments and medication intake logs
- Vaccination records, meditation sessions and menstrual cycle tracking
- Configurable cover page showing two metrics at a glance
- Backup and restore to a JSON file, plus CSV export of all measurements

# Authors

This project was initially built during software engineering course in 2022 at the Université de Pau et des Pays de l'Adour (France), by students and under the supervision of Prof. Adel Noureddine.
It has been then updated with contribution from the open source community.

# Contributors

- Adel Noureddine (project lead and maintainer) © 2022
- Dylan Mignot-Bousseau (student) © 2022
- Lucille Rey (student) © 2022
- Mathieu Vazquez (student) © 2022
- Angel Gezat (student) © 2022
- Bienvenu Akoun (student) © 2022
- Thomas Abadie (student) © 2022
- Ashraf Ajouka (student) © 2022
- Jose Buepoyo Sopale (student) © 2022
- Charlotte Ortali (student) © 2022
- Maarten Vanraes © 2026
- Ilies Hamadene (student) © 2026

# Building

Build with the Sailfish OS SDK:

```
mb2 -t SailfishOS-latest-armv7hl build
```

Before a release, refresh the translation catalogue from the SDK shell:

```
lupdate harbour-health.pro
```

# License

The project is licensed under the GNU GPL 3 license only (GPL-3.0-only).
