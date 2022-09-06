#!/bin/bash
# Starts Tmux with two horizontally-split windows, then swaps to the first pane
# Automatically enables logging for each pane via the "tmux-logging" plugin
# Lowers the display message duration when toggling logging by 90% (5000 ms --> 500 ms)
# Creates a .tmux.conf file with optimal settings (keybinds, history limit, etc.)
# Creates a "tmux-logging-output" folder in your home directory to store log files


if [ $# -ne 1 ]
then
	echo "Usage: `basename $0` {tmux-session-name}"
	exit 1
fi

echo -e 'set-option -g default-shell /bin/zsh\n\n# List of plugins\nset-option -g @plugin "tmux-plugins/tmux-logging"\nset-option -g @plugin "tmux-plugins/tpm"\nset-option -g @plugin "tmux-plugins/tmux-sensible"\n\n# Set command history limit\nset-option -g history-limit 250000\n# Disable session renaming\nset-option -g allow-rename off\n\n# Change display-time session option\nset-option -g display-time 500\n\n# Customize Tmux logging output directory\nset-option -g @logging-path "~/tmux-logging-output"\n\nset-window-option -g mode-keys vi\nbind-key "c" new-window \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"\nbind-key "\"" split-window \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"\nbind-key "%" split-window -h \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"\n\n# Initialize plugins\nrun-shell "~/.tmux/plugins/tpm/tpm"\nrun-shell "~/.tmux/plugins/tmux-logging/logging.tmux"' > "$HOME/.tmux.conf"

tog_log="$HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"

start='display_message \"Started logging to ${logging_full_filename}\"'
stop='display_message \"Ended logging to $logging_full_filename\"'
sed -i "s/$start\$/$start, 500/" $tog_log
sed -i "s/$stop\$/$stop, 500/" $tog_log

log="run-shell $tog_log"
tmux new -s $1 \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; last-window \; swap-pane -U

exit 0
