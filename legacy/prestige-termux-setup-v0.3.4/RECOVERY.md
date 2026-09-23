# Odzyskiwanie konfiguracji

Pliki .bashrc, .gitconfig i .ssh/config są zapisywane do osobnego pliku
tymczasowego, synchronizowane i atomowo zastępują poprzedni plik.
Nieudany zapis nie pozostawia uciętej konfiguracji. Kopia i manifest powstają
przed pierwszą zmianą. Rollback używa atomowego zapisu także przy odtwarzaniu.

Po niepowodzeniu konfiguracji wielu plików wybierz dziennik z home/backup.
Rollback przywraca zmienione pliki i pomija te, które już mają oryginalną treść.
Późniejsze ręczne zmiany blokują odtwarzanie. Pakiety pozostają zainstalowane.

Testy lokalne obejmują błąd atomowej zamiany i przerwaną konfigurację kilku
plików. Instalacja pakietów i zachowanie Androida wymagają fizycznego Termuxa.
