#!/usr/bin/env bash
set -euo pipefail

# --- Funktioner ---


show_main(){
    cat <<EOF
Hej $USER
EOF


    cat <<'EOF'
====Systemmeny====
1) Testa att den fungerar
2) Systeminfo
3) Visa alla användare
4) Lägg till användare
5) Ta bort användare
6) Kolla tjänster (ssh, docker, nginx)
7) Återställ användarlösenord
q) Avsluta
==================
EOF
}

do_test(){
  echo "[OK] Menyn fungerar! (funktion do_test kördes)"
}

pause(){
    echo
    read -rp "Tryck Enter för att fortsätta..."
}

show_system_info(){
    echo "===Kernel==="
    uname -a
    echo


    echo "===OS==="
    if command -v lsb_release >/dev/null 2>&1; then
	lsb_release -a || true
    else
	if [ -r /etc/os-release ]; then
	. /etc/os-release
	echo "Neme: ${NAME:-unkonwn}"
	echo "Version: ${VERSION:-unkonwn}"
	echo "Pretty: ${PRETTY_NAME:-unkonwn}"
    else
	echo "Kunde inte läsa OS-info"
    fi
	echo "(Tips: installera med: sudo apt-get install -y lsb-release)"
    fi

    echo

    echo "Date:  $(date)"
    echo
    echo "Uptime: "
	uptime
    echo
    echo "===Disk df -h ==="
    df -h
    pause
}

list_users(){
    echo "===Användare==="
    grep 'bash$' /etc/passwd | cut -d: -f1
    pause
}

add_user(){
    read -rp "Username: " newuser
    # är newuser tomt?
    if [ -z "$newuser" ]; then
	echo [X] "Inget användarnamn angivet!"
	pause
	return
    fi

    if getent passwd "$newuser" >/dev/null; then
	echo "Användaren '$newuser' finns redan!"
	pause
	return
    fi

    sudo adduser "$newuser"

    pause

}


remove_user(){
    read -rp "Userneme att ta bort: " deluser

    if [ -z "${deluser:-}" ]; then
	echo "[X] Ingen användarenamen angivit!"
	pause
	return
    fi

    if ! id "$deluser" &>/dev/null; then
	echo "[X] Avnändaren '$deluser' finns inte!"
	pause
	return
    fi

    read -rp "Är du säker att du vill ta bort '$deluser'? (j/n):  " confirm
    if [[ ! "$confirm" =~ ^[JjYy]$ ]]; then
	echo "[!] Avbröt."
	pause
	return
    fi

    sudo deluser --remove-home "$deluser"
    echo "[OK] Avnändaren '$deluser' har tagits bort."
    pause

}


check_services() {
  echo "=== Tjänststatus ==="

  # Lista på tjänster du vill kolla
  for svc in ssh docker nginx; do
    if systemctl is-active --quiet "$svc"; then
      echo "[OK]   $svc är aktiv"
    else
      echo "[X]    $svc är INTE aktiv"
    fi
  done

  pause
}


reset_password() {
    read -rp "Ange användarnamn att återställa lösenord för: " target

    if [ -z "${target:-}" ]; then
        echo "[X] Inget användarnamn angivet!"
        pause
        return
    fi

    # Finns användaren?
    if ! id "$target" &>/dev/null; then
        echo "[X] Användaren '$target' finns inte!"
        pause
        return
    fi

    echo "[i] Återställer lösenordet för '$target'..."
    echo "[i] Du kommer få ange ett nytt lösenord nu."
    sudo passwd "$target"

    if [ $? -eq 0 ]; then
        echo "[OK] Lösenordet för '$target' har uppdaterats."
    else
        echo "[X] Misslyckades att ändra lösenord."
    fi
    pause
}



while true; do
    clear
    show_main
    read -rp "Välj: " choice
    case "${choice:-}" in
    1)
	do_test
	pause
	;;
    2)
    	show_system_info
    	;;
    3)
	list_users
	;;
    4)
	add_user
	;;
    5)
	remove_user
	;;
    6)
	check_services
	;;
    7)
	reset_password
	;;
    q|Q)
	echo "Hejdå!"
	exit
    esac
done
