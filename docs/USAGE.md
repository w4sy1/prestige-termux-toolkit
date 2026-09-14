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
