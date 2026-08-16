#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FIELDS=SSID,SECURITY,BARS
POSITION=0
YOFF=0
XOFF=0
FONT="DejaVu Sans Mono 12"

if [ -r "$DIR/config" ]; then
	source "$DIR/config"
elif [ -r "$HOME/.config/rofi/wifi" ]; then
	source "$HOME/.config/rofi/wifi"
else
	#echo "WARNING: config file not found! Using default values."
  echo ""
fi

# First open uses cached results so the menu is instant; picking "Rescan"
# re-execs with RESCAN=yes for a real refresh (~3-5s block).
if [ "$RESCAN" = "yes" ]; then
	LIST=$(nmcli --fields "$FIELDS" device wifi list --rescan yes | sed '/^--/d')
else
	LIST=$(nmcli --fields "$FIELDS" device wifi list --rescan no | sed '/^--/d')
fi
RESCAN_ENTRY="Rescan"
# For some reason rofi always approximates character width 2 short... hmmm
RWIDTH=$(($(echo "$LIST" | head -n 1 | awk '{print length($0); }')+2))
# Dynamically change the height of the rofi menu
LINENUM=$(echo "$LIST" | wc -l)
# Gives a list of known connection NAMES (first column only) so we can match exactly later
KNOWNCON=$(nmcli -t -f NAME connection show)
# Really janky way of telling if there is currently a connection
CONSTATE=$(nmcli -fields WIFI g)

CURRSSID=$(LANGUAGE=C nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}')

if [[ ! -z $CURRSSID ]]; then
	HIGHLINE=$(echo  "$(echo "$LIST" | awk -F "[  ]{2,}" '{print $1}' | grep -Fxn -m 1 "$CURRSSID" | awk -F ":" '{print $1}') + 1" | bc )
fi

# HOPEFULLY you won't need this as often as I do
# If there are more than 8 SSIDs, the menu will still only have 8 lines
if [ "$LINENUM" -gt 8 ] && [[ "$CONSTATE" =~ "enabled" ]]; then
	LINENUM=8
elif [[ "$CONSTATE" =~ "disabled" ]]; then
	LINENUM=1
fi


if [[ "$CONSTATE" =~ "enabled" ]]; then
	TOGGLE="toggle off"
elif [[ "$CONSTATE" =~ "disabled" ]]; then
	TOGGLE="toggle on"
fi



HIGHLINE=${HIGHLINE:-0}
# Bump line count by 1 so the Rescan entry doesn't push the list off screen.
CHENTRY=$(echo -e "$RESCAN_ENTRY\n$TOGGLE\nmanual\n$LIST" | uniq -u | rofi -dmenu -p "Wi-Fi SSID: " -lines "$((LINENUM + 1))" -a "$HIGHLINE" -location "$POSITION" -yoffset "$YOFF" -xoffset "$XOFF" -font "$FONT" -width -"$RWIDTH")

# Exit if user cancelled
[[ -z "$CHENTRY" ]] && exit 0

# Rescan re-execs this script with RESCAN=yes so the new list is instant on the next open.
if [ "$CHENTRY" = "$RESCAN_ENTRY" ]; then
	RESCAN=yes exec "$0" "$@"
fi

CHSSID=$(echo "$CHENTRY" | sed  's/\s\{2,\}/\|/g' | awk -F "|" '{print $1}')

# If the user inputs "manual" as their SSID in the start window, it will bring them to this screen
if [ "$CHENTRY" = "manual" ] ; then
	# Manual entry of the SSID and password (if appplicable)
	MSSID=$(echo "enter the SSID of the network (SSID,password)" | rofi -dmenu -p "Manual Entry: " -font "$FONT" -lines 1)
	# Separating the password from the entered string
	MPASS=$(echo "$MSSID" | awk -F "," '{print $2}')

	#echo "$MSSID"
	#echo "$MPASS"

	# If the user entered a manual password, then use the password nmcli command
	if [ "$MPASS" = "" ]; then
		nmcli dev wifi con "$MSSID"
	else
		nmcli dev wifi con "$MSSID" password "$MPASS"
	fi

elif [ "$CHENTRY" = "toggle on" ]; then
	nmcli radio wifi on

elif [ "$CHENTRY" = "toggle off" ]; then
	nmcli radio wifi off

else

	# If the connection is already in use, then this will still be able to get the SSID
	if [ "$CHSSID" = "*" ]; then
		CHSSID=$(echo "$CHENTRY" | sed  's/\s\{2,\}/\|/g' | awk -F "|" '{print $3}')
	fi

	# Exact-match against known connection names so saved networks use `con up` (no re-auth).
	if echo "$KNOWNCON" | grep -Fxq "$CHSSID"; then
		nmcli con up "$CHSSID"
	else
		if [[ "$CHENTRY" =~ WPA|WEP|SAE|802\.1X ]]; then
			WIFIPASS=$(echo "if connection is stored, hit enter" | rofi -dmenu -p "password: " -lines 1 -font "$FONT" )
		fi
		if [ -z "$WIFIPASS" ]; then
			nmcli dev wifi con "$CHSSID"
		else
			nmcli dev wifi con "$CHSSID" password "$WIFIPASS"
		fi
	fi

fi
