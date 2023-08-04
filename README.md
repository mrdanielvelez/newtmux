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

![newtmux Demo](https://user-images.githubusercontent.com/85040841/189549863-cb93a285-10eb-4424-bffc-88d0822a16b5.gif)

    $ newtmux -h               
    [Tmux Session & Logging Optimizer — Version 2.0]

    Usage: newtmux -n {tmux-session-name} [-w {num_windows} | -k | -s | -e | -h]

    Mandatory argument:
     -n | Tmux Session Name

    Optional arguments:
     -w | Number of horizontally-split windows to open (default 1, maximum 5)
     -k | Use the existing .tmux.conf file instead of an optimized one
     -s | Swift and Slient mode (disables status messages)
     -e | Run engagementinit and create a symlink (Alias required)
     -h | Display this help menu

    Example execution (with an alias set):
     newtmux -n flast -w 2 -e

# Obtaining Missing Evidence from Tmux Logs
If you're missing evidence while reporting, the best way to look for the output of a command you forgot to take notes of is by running the following command within the ~/tmux-logging-output directory:
```
cat * | less -r
```
Then type slash (`/`) and a keyword of the command you'd like to see the output of (e.g. ntlmrelayx) — `/ntlmrelayx` — press `Enter` — then press `n` or `N` (lower/upper) to go forward and back, respectively.

This will search through your Tmux command history for the entire penetration test. The `-r` flag is necessary to clear up any raw control characters and get a clean output within less.

The reason we are piping all of the files into less from cat as opposed to running `less -r *` is to avoid separate pages for each log file. This enables us to easily search through everything that was logged.

If you need results from a specific day you can easily distill the evidence by modifying the command to only cat certain files based on their names. And if you always execute a certain tool within a specific Tmux pane, the filenames can help out with discovery since they include pane numbers and session names.

Once you find what you're looking for, select the content and press `CTRL+SHIFT+C` to copy it to your clipboard from less. Alternatively, right-click to open the feature menu and select Copy Selection.
