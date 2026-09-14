# Użycie

`python app.py --menu` — wybór kategorii.
`python app.py SYSTEM` / `python app.py GIT --root ~/projects/repo`
`python app.py BACKUP --root ~/projects/demo --archive ~/backup/demo.tar.gz --apply`

Backendy: uname, ip, ls, git, ssh, tar; Android wymaga Termux:API i termux-api.
DIAGNOSTICS wymaga termux-info. Panel nie instaluje zależności automatycznie.
SYSTEM/NETWORK/FILES/GIT/SSH/ANDROID/DIAGNOSTICS tylko odczyt. SSH pokazuje obsługiwane
typy kluczy, nie łączy się z hostem i nie uruchamia serwera. Nie zbiera kluczy prywatnych.
BACKUP: tar do nowego archiwum poza źródłem, dopiero po --apply. Wyklucza znane nazwy
sekretów; nie wykryje sekretów wpisanych w zwykły dokument. Wybierz źródło świadomie.
Nie ma automatycznego wypakowywania ani zdalnych operacji Git/SSH.

## Rozszerzenia 0.2.0

Bez kategorii program pokazuje także listę operacji. Użyj `--operation`:
SYSTEM: summary/uptime/storage; NETWORK: addresses/routes/ping (`--target IP`);
FILES: list/hash (`--file`); GIT: status/branches/last-commit; SSH: algorithms;
ANDROID: battery/wifi; DIAGNOSTICS: info/dependencies; BACKUP: create/verify.
`BACKUP --operation verify --archive kopia.tar.gz` sprawdza manifest SHA256 obok archiwum.
Termux:API wymaga osobnej aplikacji i pakietu. Nie odczytuje SMS, kontaktów ani haseł Wi-Fi.
Filtry backupu nie wykrywają sekretów ukrytych w dowolnej treści; wybierz źródło świadomie.
