#!/bin/bash

#verificam daca exista argument cand apelez script-ul
#Daca nu afisez cu echo eroare, Dc da il salvez intr-o variabila

if [ "$#" -ne 1 ]; then
	echo "Eroare! Trebuie specificata calea catre fisierul de configurare."
	echo "Sintaxa corecta: $0 /.../vsftpd.conf"
	exit 1
fi

FILE="$1"

#Verificam daca exista fisierul pe care l-am mentionat ca argument

if [ ! -f "$FILE" ]; then
	echo "Eroare! Fisierul '$FILE' nu exista"
	exit 1
fi

#Verificam permisiunile si proprietarul fisierului
