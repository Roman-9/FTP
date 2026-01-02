#!/bin/bash

#verificam daca exista argument cand apelez script-ul
#Daca nu afisez cu echo eroare, Dc da il salvez intr-o variabila

#verificam daca ne da eroare la merge

#Verificam daca exista fisierul pe care l-am mentionat ca argument

#Verificam permisiunile si proprietarul fisierului

PERMS=$(stat -c "%a" "$FILE")
OWNER=$(stat -c "%U" "$FILE")
echo "Proprietarul fisierului $FILE este $OWNER."
OTHERS=$(( $PERMS % 10 ))
if [ "$OTHERS" -ne 2 ] && [ "$OTHERS" -ne 3 ] && [ "$OTHERS" -ne 6 ] && [ "$OTHERS" -ne 7 ]; then
	echo "Fisierul are permisiuni sigure ($PERMS in baza 8)."
else
	echo "Eroare! Permisiuni nesigure! ($PERMS in baza 8) Fisierul poate fi modificat de alte persoane in afara de $OWNER."
fi
