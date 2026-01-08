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

PERMS=$(stat -c "%a" "$FILE")
OWNER=$(stat -c "%U" "$FILE")
echo "Proprietarul fisierului $FILE este $OWNER."
OTHERS=$(( $PERMS % 10 ))

if [ "$OTHERS" -ne 2 ] && [ "$OTHERS" -ne 3 ] && [ "$OTHERS" -ne 6 ] && [ "$OTHERS" -ne 7 ]; then
	echo "Fisierul are permisiuni sigure ($PERMS in baza 8)."
else
	echo "Eroare! Permisiuni nesigure! ($PERMS in baza 8) Fisierul poate fi modificat de alte persoane in afara de $OWNER."
fi

#Verificare duplicate sau directive suprascrise

declare -A DICTIONAR

NR_LINII=0
DUPLICATE=0
while IFS= read -r LINIE || [ -n "$LINIE" ]; do
	((NR_LINII++))
	LINIE=$(echo "$LINIE" | xargs)
	if [[ "$LINIE" == \#* || -z "$LINIE" ]]; then
		continue
	fi
	if [[ "$LINIE" == *"="* ]]; then
		KEY=$(echo "$LINIE" | cut -d'=' -f1 | xargs)
		VAL=$(echo "$LINIE" | cut -d'=' -f2 | xargs)
		if [[ -v DICTIONAR["$KEY"] ]]; then
			echo -e "Atentie! Duplicat pe linia $NR_LINII pentru permisiunea $KEY!\nValoarea initiala - ${DICTIONAR[$KEY]} - Va fi inlocuita cu $VAL."
			((DUPLICATE++))
		fi
	DICTIONAR["$KEY"]="$VAL"
	fi
done < "$FILE"

if [ "$DUPLICATE" -eq 0 ]; then
	echo "Nu au fost gasite duplicate." 
elif [ "$DUPLICATE" -eq 1 ]; then
	echo "In fisierul $FILE exista o singura duplicata."
else
	echo "In fisierul $FILE exista $DUPLICATE duplicate."
fi


#Verificare setari critice de securitate

verificare(){
	local KEY=$1
	local VAL_RECOMANDAT=$2
	local VAL="${DICTIONAR[$KEY]}"

	if [ -z "$VAL" ]; then
		echo "Atentie! Permisiunea $KEY nu a fost configurata! Valoare recomandata: $VAL_RECOMANDAT"
		return
	fi

	if [ "$VAL" == "$VAL_RECOMANDAT" ]; then
		echo "Valoarea setarii $KEY a fost configurata sigur."
	else
		echo "Atentie! Valoarea setarii $KEY NU a fost configurata sigur. Valoarea recomandata: $VAL_RECOMANDAT"
	fi
}

verificare "anonymous_enable" "NO"
verificare "local_enable" "YES"
verificare "write_enable" "YES"
verificare "chroot_local_user" "YES"
