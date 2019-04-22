#!/bin/bash

if [ $# -eq 0 ] ; then
	aplay notification.wav &
	zenity --info --text "Notificator is active!" --title="Notificator"
else
	aplay notification.wav &
	zenity --info --text "$*" --title="Notificator"
fi
