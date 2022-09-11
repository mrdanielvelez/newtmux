# newtmux — Tmux Session & Logging Optimizer
### Optimizes Tmux for session creation, project trees, and logging via config modifications and various features.
* Starts Tmux with specified number [-w] of horizontally-split windows (default 1, maximum 5)
* Automatically enables logging for each pane via the "tmux-logging" plugin, then selects the first pane
* Filters ANSI color codes from log output text streams via ansi2text/sed for easy copy/paste into reports
* Lowers the message duration for all "tmux-logging" plugin messages by 90% (5000 ms --> 500 ms)
* Creates an optimized Tmux config file (keybinds, history limit, etc.) after backing up the existing one
* Integrates with engagement-init with [-e] or if the current folder is located in a project directory tree
* Otherwise, a "tmux-logging-output" folder is created in your home directory to store all logs and screen captures
* Detects whether or not the "tmux-logging" plugin is installed, prompts to install it automatically if not
* Identifies if a compatible version of Tmux is installed, prompts to update Tmux automatically if not

![newtmux Demo 1](https://user-images.githubusercontent.com/85040841/189546780-5dc20636-7354-45d5-a158-eca049c76fc9.gif)

    $ newtmux -h               
    [Tmux Session & Logging Optimizer — Version 2.0]

    Usage: newtmux -n {tmux-session-name} [-w {num_windows} | -k | -s | -e | -h]

    Mandatory argument:
     -n | Tmux Session Name

    Optional arguments:
     -w | Number of horizontally-split windows to open (default 1, maximum 5)
     -k | Use the existing .tmux.conf file instead of an optimized one
     -s | Swift and Slient mode (disables status messages)
     -e | Run engagementinit.sh before newtmux begins (Alias required)
     -h | Display this help menu

    Example execution (with an alias set):
     newtmux -n flast -w 2 -e
