# task_planner_for_linux
Task planner written for Linux systems (made with "Zenity").

Main script is "taskPlanner.sh", add this program to your startup programs list with "-starter" option:
  Ex.: PATH_TO_THIS_SCRIPT/taskPlanner.sh -starter

Files description:
  "notifications" - stores your notifications tasks
  "tasks" - stores your program tasks
  "fileTasks" - stores your tasks with file option

Usage options:
  -starter:
    First run after system boot (removes expired tasks stored in "tasks", "fileTasks" 
    and "notifications" files and adds active tasks to "to do queue").  
  -v:
    Show the application's version.
  -h:
    Show help options.
