#!/bin/bash

function deleteNonActiveTasks() {
	#file tasks
	TASKS_TO_DELETE=()
	LINE_NUMBER=1
	while read LINE ; do
		PROGRAM=$LINE
		read LINE
		FILE=$LINE
		read LINE
		DATE=$LINE
		read LINE
		HOURS=$LINE
		read LINE
		MINUTES=$LINE
		TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
		CURRENT_TIME=$(date +%s)
		DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
		if [ $DELAY_TIME -lt 0 ] ; then
			TASKS_TO_DELETE+=($LINE_NUMBER)
		fi
		LINE_NUMBER=$(($LINE_NUMBER+5))
	done < fileTasks

	maxIndex=$((${#TASKS_TO_DELETE[@]}-1))
	currentIndex=$((${#TASKS_TO_DELETE[@]}-1))
	while [ $currentIndex -ge 0 ] ; do
		lineNum=${TASKS_TO_DELETE[$currentIndex]}
		sed -i.bak -e "${lineNum}d;$((${lineNum}+1))d;$((${lineNum}+2))d;$((${lineNum}+3))d;$((${lineNum}+4))d" fileTasks
		currentIndex=$(($currentIndex-1))
	done


	#simple tasks
	TASKS_TO_DELETE=()
	LINE_NUMBER=1
	while read LINE ; do
		PROGRAM=$LINE
		read LINE
		DATE=$LINE
		read LINE
		HOURS=$LINE
		read LINE
		MINUTES=$LINE
		TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
		CURRENT_TIME=$(date +%s)
		DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
		if [ $DELAY_TIME -lt 0 ] ; then
			TASKS_TO_DELETE+=($LINE_NUMBER)
		fi
		LINE_NUMBER=$(($LINE_NUMBER+4))
	done < tasks

	maxIndex=$((${#TASKS_TO_DELETE[@]}-1))
	currentIndex=$((${#TASKS_TO_DELETE[@]}-1))
	while [ $currentIndex -ge 0 ] ; do
		lineNum=${TASKS_TO_DELETE[$currentIndex]}
		sed -i.bak -e "${lineNum}d;$((${lineNum}+1))d;$((${lineNum}+2))d;$((${lineNum}+3))d" tasks
		currentIndex=$(($currentIndex-1))
	done


	#notifications
	TASKS_TO_DELETE=()
	LINE_NUMBER=1
	while read LINE ; do
		MESSAGE=$LINE
		read LINE
		DATE=$LINE
		read LINE
		HOURS=$LINE
		read LINE
		MINUTES=$LINE
		TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
		CURRENT_TIME=$(date +%s)
		DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
		if [ $DELAY_TIME -lt 0 ] ; then
			TASKS_TO_DELETE+=($LINE_NUMBER)
		fi
		LINE_NUMBER=$(($LINE_NUMBER+4))
	done < notifications

	maxIndex=$((${#TASKS_TO_DELETE[@]}-1))
	currentIndex=$((${#TASKS_TO_DELETE[@]}-1))
	while [ $currentIndex -ge 0 ] ; do
		lineNum=${TASKS_TO_DELETE[$currentIndex]}
		sed -i.bak -e "${lineNum}d;$((${lineNum}+1))d;$((${lineNum}+2))d;$((${lineNum}+3))d" notifications
		currentIndex=$(($currentIndex-1))
	done
	rm *.bak
}

function starter() {
	deleteNonActiveTasks
	
	#file tasks
	while read LINE ; do
		PROGRAM=$LINE
		read LINE
		FILE=$LINE
		read LINE
		DATE=$LINE
		read LINE
		HOURS=$LINE
		read LINE
		MINUTES=$LINE
		TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
		CURRENT_TIME=$(date +%s)
		DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
		if [ $DELAY_TIME -gt 0 ] ; then
			sleep $DELAY_TIME && $PROGRAM $FILE &
		fi
	done < fileTasks


	#simple tasks
	while read LINE ; do
		PROGRAM=$LINE
		read LINE
		DATE=$LINE
		read LINE
		HOURS=$LINE
		read LINE
		MINUTES=$LINE
		TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
		CURRENT_TIME=$(date +%s)
		DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
		if [ $DELAY_TIME -gt 0 ] ; then
			sleep $DELAY_TIME && $PROGRAM &
		fi
	done < tasks


	#notifications
	while read LINE ; do
		MESSAGE=$LINE
		read LINE
		DATE=$LINE
		read LINE
		HOURS=$LINE
		read LINE
		MINUTES=$LINE
		TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
		CURRENT_TIME=$(date +%s)
		DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
		if [ $DELAY_TIME -gt 0 ] ; then
			sleep $DELAY_TIME && ./notificator.sh $MESSAGE &
		fi
	done < notifications
}


if [ "$1" == "-starter" ] ; then
	echo "Task planner is active"
	starter
elif [ "$1" == "-v" ] ; then
	echo "Task planner - Version 1.0"
	exit
elif [ "$1" == "-h" ] ; then
	printf "Usage:\n  /...path to the script.../taskPlanner.sh [OPTION...]\n\nHelp options:\n  "
	printf "%-20s %8s\n\n" "-h" "Show help options"
	printf "Application Options:\n  "
	printf "%-20s %8s\n  " "-v" "Show the application's version"
	printf "%-20s %8s\n\n" "-starter" "First run after system boot (removes expired tasks and adds active tasks to \"to do queue\")"
	exit
fi


MENU=("Add new task" "List of sceduled tasks" "Add notification")
OPEN_MENU=("Run program" "Open file")

while true; do
	OPTION=$(zenity --list --height 300 --title="Task planner" --text="Welcome!"\
	 --cancel-label "Cancel" --ok-label "OK" --column="Choose option" "${MENU[@]}")

	if [[ $? -ne 0 ]]; then
		echo "Exit"
		exit
	fi
	
	case "$OPTION" in
		"${MENU[0]}" )
			DATE=$(zenity --calendar --date-format=%s --text "Choose date" --title "Task date:")
			if [ $? -eq 1 ] ; then
				continue
			fi
			TIME=$(zenity --forms --title="Choose time" --text="Task time" --add-entry="Hours" --add-entry="Minutes")
			WINDOW_STATUS=$?
			if [ $WINDOW_STATUS -eq 1 ] ; then
				continue
			fi
			HOURS=$(sed 's/|[0-9]*//' <<< "$TIME")
			MINUTES=$(sed 's/[0-9]*|//' <<< $TIME)

			while ! [[ $HOURS =~ ^[0-9]+$ ]] || ! [[ $MINUTES =~ ^[0-9]+$ ]] || [ $HOURS -lt 0 ] || [ $HOURS -gt 23 ] || [ $MINUTES -lt 0 ] || [ $MINUTES -gt 59 ] ; do
				TIME=$(zenity --forms --title="Error! Try again!" --text="Task time" --add-entry="Hours" --add-entry="Minutes")
				WINDOW_STATUS=$?
				if [ $WINDOW_STATUS -eq 1 ] ; then
					break
				fi
				HOURS=$(sed 's/|[0-9]*//' <<< "$TIME")
				MINUTES=$(sed 's/[0-9]*|//' <<< $TIME)
			done
			if [ $WINDOW_STATUS -eq 1 ] ; then
				continue
			fi

			PROGRAM_FILE=$(zenity --file-selection --title "Pick a program or script to execute")
			if [ $? -eq 1 ] ; then
				continue
			fi
			zenity --question --text "Do you need to open some file by this program?"
			if [ $? -eq 0 ] ; then
				FILE_TO_OPEN=$(zenity --file-selection --title "Pick a file to open")
				if [ $? -eq 1 ] ; then
					continue
				fi
				printf "$PROGRAM_FILE\n$FILE_TO_OPEN\n$DATE\n$HOURS\n$MINUTES\n" >> fileTasks

				TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
				CURRENT_TIME=$(date +%s)
				DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
				if [ $DELAY_TIME -gt 0 ] ; then
					sleep $DELAY_TIME && $PROGRAM_FILE $FILE_TO_OPEN &
					aplay success.wav &
				else
					aplay error.wav &
					zenity --info --text "Expired task!"
				fi
			else
				printf "$PROGRAM_FILE\n$DATE\n$HOURS\n$MINUTES\n" >> tasks

				TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
				CURRENT_TIME=$(date +%s)
				DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
				if [ $DELAY_TIME -gt 0 ] ; then
					sleep $DELAY_TIME && $PROGRAM_FILE &
					aplay success.wav &
				else
					aplay error.wav &
					zenity --info --text "Expired task!"
				fi
			fi
		;;
		"${MENU[1]}" )
			deleteNonActiveTasks
			TASKS=""
			FILE_TASKS=""
			NOTIFICATIONS=""
			NEWLINE=$'\n'
			
			while read LINE ; do
				FILE_TASKS="${FILE_TASKS}Program: $LINE$NEWLINE"
				read LINE
				FILE_TASKS="${FILE_TASKS}File to open: $LINE$NEWLINE"
				read LINE
				LINE=$(date -d @$LINE | sed "s/, [0-9][0-9]:[0-9A-Z :]*//")
				FILE_TASKS="${FILE_TASKS}Date: ${LINE} at "
				read LINE
				FILE_TASKS="${FILE_TASKS}${LINE} h "
				read LINE
				FILE_TASKS="${FILE_TASKS}${LINE} m$NEWLINE$NEWLINE"
			done < fileTasks
			
			while read LINE ; do
				TASKS="${TASKS}Program: $LINE$NEWLINE"
				read LINE
				LINE=$(date -d @$LINE | sed "s/, [0-9][0-9]:[0-9A-Z :]*//")
				TASKS="${TASKS}Date: ${LINE} at "
				read LINE
				TASKS="${TASKS}${LINE} h "
				read LINE
				TASKS="${TASKS}${LINE} m$NEWLINE$NEWLINE"
			done < tasks
			
			while read LINE ; do
				NOTIFICATIONS="${NOTIFICATIONS}Message: $LINE$NEWLINE"
				read LINE
				LINE=$(date -d @$LINE | sed "s/, [0-9][0-9]:[0-9A-Z :]*//")
				NOTIFICATIONS="${NOTIFICATIONS}Date: ${LINE} at "
				read LINE
				NOTIFICATIONS="${NOTIFICATIONS}${LINE} h "
				read LINE
				NOTIFICATIONS="${NOTIFICATIONS}${LINE} m$NEWLINE$NEWLINE"
			done < notifications
			
			zenity --text-info --title "To do list" --width 500 --height 600 --filename=<(echo "=== TASKS WITH OPENING FILES ===$NEWLINE$NEWLINE${FILE_TASKS}=== SIMPLE TASKS ===$NEWLINE$NEWLINE${TASKS}=== NOTIFICATIONS ===$NEWLINE$NEWLINE$NOTIFICATIONS")
		;;
		"${MENU[2]}" )
			DATE=$(zenity --calendar --text "Choose date" --date-format=%s --title "Task date:")
			if [ $? -eq 1 ] ; then
				continue
			fi
			TIME=$(zenity --forms --title="Choose time" --text="Task time" --add-entry="Hours" --add-entry="Minutes")
			WINDOW_STATUS=$?
			if [ $WINDOW_STATUS -eq 1 ] ; then
				continue
			fi
			HOURS=$(sed 's/|[0-9]*//' <<< "$TIME")
			MINUTES=$(sed 's/[0-9]*|//' <<< $TIME)

			while ! [[ $HOURS =~ ^[0-9]+$ ]] || ! [[ $MINUTES =~ ^[0-9]+$ ]] || [ $HOURS -lt 0 ] || [ $HOURS -gt 23 ] || [ $MINUTES -lt 0 ] || [ $MINUTES -gt 59 ] ; do
				TIME=$(zenity --forms --title="Error! Try again!" --text="Task time" --add-entry="Hours" --add-entry="Minutes")
				WINDOW_STATUS=$?
				if [ $WINDOW_STATUS -eq 1 ] ; then
					break
				fi
				HOURS=$(sed 's/|[0-9]*//' <<< "$TIME")
				MINUTES=$(sed 's/[0-9]*|//' <<< $TIME)
			done
			if [ $WINDOW_STATUS -eq 1 ] ; then
				continue
			fi

			NOTIFICATION_TEXT=$(zenity --forms --title="Notification text" --text="Notification text" --add-entry="Text")
			if [ $? -eq 1 ] ; then
				continue
			fi

			printf "$NOTIFICATION_TEXT\n$DATE\n$HOURS\n$MINUTES\n" >> notifications
			
			TIME_TO_RUN=$(($DATE+($HOURS*3600)+($MINUTES*60)))
			CURRENT_TIME=$(date +%s)
			DELAY_TIME=$(($TIME_TO_RUN-$CURRENT_TIME))
			if [ $DELAY_TIME -gt 0 ] ; then
				sleep $DELAY_TIME && ./notificator.sh $NOTIFICATION_TEXT &
				aplay success.wav &
			else
				aplay error.wav &
				zenity --info --text "Expired notification!"
			fi
		;;
	esac
done
