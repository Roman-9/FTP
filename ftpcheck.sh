#!/bin/bash

# Culori sau formatare text

RED="\033[38;5;9m"
NC="\033[0m"
GREEN="\033[38;5;10m"
BOLD="\033[1m"
YELLOW="\033[38;5;11m"
PURPLE="\033[38;5;135m"
PASTEL="\033[38;5;183m"

echo -e "\n${BOLD}${PASTEL}<---------------------------------------------------------->"
echo -e "<---------- Raport de Securitate FTPConfigCheck ----------->"
echo -e "<---------------------------------------------------------->${NC}\n"

# Verificam daca exista argument cand apelez script-ul
# Daca nu afisez cu echo eroare, Dc da il salvez intr-o variabila

if [ "$#" -ne 1 ]; then
	echo -e "${BOLD}${RED}Eroare!${NC} Trebuie specificata calea catre fisierul de configurare."
	echo "Sintaxa corecta: $0 /.../vsftpd.conf"
	exit 1
fi

FILE="$1"

# Verificam daca exista fisierul pe care l-am mentionat ca argument

if [ ! -f "$FILE" ]; then
	echo -e "${BOLD}${RED}Eroare!${NC} Fisierul '$FILE' nu exista"
	exit 1
fi

# Verificam permisiunile si proprietarul fisierului

echo -e "\n${PASTEL}<---------------------------------------------------------->"
echo -e "<------- Verificare permisiuni si proprietar fisier ------->"
echo -e "<---------------------------------------------------------->${NC}\n"

PERMS=$(stat -c "%a" "$FILE")
OWNER=$(stat -c "%U" "$FILE")
echo -e "Proprietarul fisierului ${PURPLE}$FILE${NC} este ${PURPLE}$OWNER.${NC}"
OTHERS=$(( $PERMS % 10 ))

if [ "$OTHERS" -ne 2 ] && [ "$OTHERS" -ne 3 ] && [ "$OTHERS" -ne 6 ] && [ "$OTHERS" -ne 7 ]; then
	echo -e "${GREEN}Fisierul are permisiuni sigure ${NC}($PERMS in baza 8)."
else
	echo -e "${BOLD}${RED}Eroare!${NC} ${RED}Permisiuni nesigure! ($PERMS in baza 8) Fisierul poate fi modificat de alte persoane in afara de $OWNER${NC}."
fi

# Verificare duplicate sau directive suprascrise

echo -e "\n${PASTEL}<---------------------------------------------------------->"
echo -e "<----- Verificare directive duplicate sau suprascrise ----->"
echo -e "<---------------------------------------------------------->${NC}\n"

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
			echo -e "${BOLD}${YELLOW}Atentie!${NC} Duplicat pe linia $NR_LINII pentru permisiunea $KEY!\nValoarea initiala - ${PURPLE}${DICTIONAR[$KEY]}${NC} - Va fi inlocuita cu ${PURPLE}$VAL${NC}."
			((DUPLICATE++))
		fi
	DICTIONAR["$KEY"]="$VAL"
	fi
done < "$FILE"

if [ "$DUPLICATE" -eq 0 ]; then
	echo -e "${GREEN}Nu au fost gasite duplicate.${NC}"
elif [ "$DUPLICATE" -eq 1 ]; then
	echo -e "In fisierul $FILE exista ${YELLOW}o singura duplicata${NC}."
else
	echo -e "In fisierul $FILE exista ${YELLOW}$DUPLICATE duplicate${NC}."
fi

# Verificare setari critice de securitate

echo -e "\n${PASTEL}<---------------------------------------------------------->"
echo -e "<--------- Verificare setari critice de scuritate --------->"
echo -e "<---------------------------------------------------------->${NC}\n"
verificare(){
	local KEY=$1
	local VAL_RECOMANDAT=$2
	local VAL="${DICTIONAR[$KEY]}"

	if [ -z "$VAL" ]; then
		echo -e "${BOLD}${YELLOW}Atentie!${NC} Valoarea setarii $KEY NU a fost configurata! Valoare recomandata: ${PURPLE}$VAL_RECOMANDAT${NC}."
		return
	fi

	if [ "$VAL" == "$VAL_RECOMANDAT" ]; then
		echo -e "${GREEN}Valoarea setarii $KEY a fost configurata sigur.${NC}"
	else
		echo -e "${BOLD}${YELLOW}Atentie!${NC} Valoarea setarii $KEY NU a fost configurata sigur. Valoarea recomandata: ${PURPLE}$VAL_RECOMANDAT${NC}."
	fi
}

verificare "anonymous_enable" "NO"
verificare "local_enable" "YES"
verificare "write_enable" "YES"
verificare "chroot_local_user" "YES"

# Finalizare :)

echo -e "\n${BOLD}${PASTEL}<---------------------------------------------------------->"
echo -e "<---------- Verificare FTPConfigCheck finalizata ---------->"
echo -e "<---------------------------------------------------------->${NC}\n"
