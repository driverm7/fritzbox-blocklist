# FRITZ!Box Blocklist

Domain-Blacklist für die FRITZ!Box-Kindersicherung (Filterliste „Gesperrte Internetseiten“).

**Fertige Liste:** [`dist/fritzbox-blocklist.txt`](dist/fritzbox-blocklist.txt)
(Raw: `https://raw.githubusercontent.com/<user>/fritzbox-blocklist/main/dist/fritzbox-blocklist.txt`)

## Einschränkungen der FRITZ!Box
- Max. **500 Einträge** pro Filterliste – der Build bricht bei Überschreitung ab.
- Kein Import per URL – die Liste wird manuell eingefügt.
- Wirkt nur für Geräte, deren **Zugangsprofil** die Filterliste aktiviert hat.
- Bei aktiver Filterliste ist der direkte Aufruf von IP-Adressen gesperrt (Freigabe unter „Erlaubte IP-Adressen“).
- Blockiert zuverlässig nur über IPv4.

## In die FRITZ!Box übernehmen
1. `Internet` → `Filter` → Registerkarte `Listen`
2. Bei **Gesperrte Internetseiten (Blacklist)** auf `bearbeiten`
3. Inhalt von `dist/fritzbox-blocklist.txt` einfügen → `Übernehmen`
4. `Internet` → `Filter` → `Zugangsprofile` → Profil bearbeiten → *Filter für Internetseiten* aktivieren, *Internetseiten sperren (Blacklist)* wählen
5. FRITZ!Box neu starten, damit der Filter auch für bereits verbundene Geräte greift

## Struktur
```
sources/        Quelllisten (*.txt, eine Domain pro Zeile, # = Kommentar)
  allowlist.txt Ausnahmen – werden aus allen Quellen entfernt
scripts/        build.ps1 – normalisiert, validiert, dedupliziert
dist/           generierte Ausgabe (nicht manuell bearbeiten)
```
Akzeptierte Eingabeformate: `domain.tld`, `https://domain.tld/pfad`, `0.0.0.0 domain.tld`, `||domain.tld^`.
Subdomains werden entfernt, wenn die Parent-Domain bereits gelistet ist (spart Plätze).

## Lokal bauen (Windows)
```powershell
pwsh .\scripts\build.ps1          # kürzt bei >500 mit Warnung
pwsh .\scripts\build.ps1 -Strict  # bricht bei >500 ab
```
Bei Push auf `main` baut GitHub Actions automatisch und committet `dist/`.
