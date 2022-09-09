#!/usr/bin/env bash
# newtmux.sh by Daniel Velez
# Starts Tmux with specified number [-w] of horizontally-split windows (default 1, maximum 5)
# Automatically enables logging for each pane via the "tmux-logging" plugin, then selects the first pane
# Filters ANSI color codes from log output text streams via ansi2text for easy copy/paste into reports
# Lowers the message duration for all "tmux-logging" plugin messages by 90% (5000 ms --> 500 ms)
# Optionally creates an optimized .tmux.conf file (keybinds, history limit, etc.) after backing up the existing one
# Integrates with engagement-init with [-e] or if the current folder is located in a project directory tree
# Otherwise, a "tmux-logging-output" folder is created in your home directory to store all logs and screen captures

SCRIPT_NAME=`basename $0` && SCRIPT_NAME=${SCRIPT_NAME%.*}
STATUS=true && KEEP_CONF=false

main() {
	install_ansi2txt
	optimize_config
	lower_duration
	start_tmux
}

einit() {
	if alias=`grep -o -h 'alias einit.*' ~/.zshrc ~/.bashrc` || alias=`grep -o -h 'alias engagementinit.*' ~/.zshrc ~/.bashrc` || alias=`grep -o -h 'alias engagement-init.*' ~/.zshrc ~/.bashrc`
	then
		einit=`cut -d '=' -f 2 <<< $alias` && einit=`tr -d \'\" <<< $einit` && einit=${einit/#\~/$HOME}
		read -p $'\e[36mEngagement SKU\e[0m (IPT/EPT/CPT/ADSR/RTA/etc.): ' esku
		read -p $'\e[31mOpportunity Number: \e[0m' onum
		read -p $'\e[32mClient Name: \e[0m' cname && cname=`tr ' ' '-' <<< $cname`
		read -p $'\e[35mYour Initials: \e[0m' yini
		printf '—%.0s' {1..50} && echo
		$einit -e "$esku" -o "$onum" -c $cname -i "$yini" &>/dev/null
		if [[ $? -eq 0 ]]
		then
			pause && echo -e "\e[33mengagementinit\e[32m completed successfully.\e[0m Continuing..."
			project="`pwd`/$cname-$onum-$esku"
			if [[ -d "$project-02" ]]; then pdir="$project-02"; else pdir="$project-01"; fi
			logoutputdir="$pdir/Evidence/$cname-notes-$yini/Logging-Output"
			mkdir "$logoutputdir" &>/dev/null
			return 0
		else
			echo -e "\e[33mengagementinit\e[31m failed to complete\e[0m Continuing..."
			return 1
		fi
	else
		echo -e "\e[33mengagementinit\e[31m could not be located\e[0m as an alias."
		echo -e "(\e[36meinit\e[0m, \e[36mengagementinit\e[0m, \e[36mengagement-init\e[0m). Continuing..."
		return 1
	fi
}

install_ansi2txt() {
	if ! [[ `command -v ansi2txt` ]]
	then
		echo -e "\e[33mansi2txt\e[0m is\e[31m not installed.\e[0m Would you like to install it?"
		echo -e "This enables \e[33m$SCRIPT_NAME\e[0m to remove \e[32mANSI color coding\e[0m from log files."
		echo -n -e "\nCommand:\e[34m sudo apt install colorized-logs \e[0m\c"
		read -n 1 -p "[y | n] " choice && echo
		if [[ $choice =~ y|Y ]]
		then
			sudo apt install colorized-logs &>/dev/null
			if [[ $? -eq 0 ]]
			then
				sed -i "s/ansifilter/ansi2txt/" "$HOME/.tmux/plugins/tmux-logging/scripts/start_logging.sh"
				pause && echo -e "\n\e[33mansi2txt\e[0m was successfully installed and configured. Continuing..."
				return 0
			else
				echo -e "Error — \e[33mansi2txt\e[31m failed to install.\e[0m Exiting..."
				exit 1
			fi
		elif [[ $choice =~ n|N ]]
		then
			pause && echo -e "Continuing without installing \e[33mansi2txt\e[0m..."
			return 0
		else
			echo -e "Error — \e[31mInvalid input.\e[0m Exiting..."
			exit 1
		fi
	else
		pause && echo -e "\e[33mansi2txt \e[32mis present. \e[0mContinuing..."
		sed -i "s/ansifilter/ansi2txt/" "$HOME/.tmux/plugins/tmux-logging/scripts/start_logging.sh"
	fi
}

optimize_config() {
	if [[ $KEEP_CONF = false ]]
	then
		if [[ -f "$HOME/.tmux.conf" ]]
		then
			date=`date "+%Y-%m-%d"`
			success_msg="Backed up previous config file to \e[36m$HOME/.tmux.conf.bak-$date\e[0m"
			mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak-$date" && pause && echo -e $success_msg
		fi
		echo -e 'set-option -g default-shell /bin/zsh\n\n# List of plugins\nset-option -g @plugin "tmux-plugins/tmux-logging"\nset-option -g @plugin "tmux-plugins/tpm"\nset-option -g @plugin "tmux-plugins/tmux-sensible"\n\n# Set command history limit\nset-option -g history-limit 250000\n\n# Disable session renaming\nset-option -g allow-rename off\n\n# Change display-time session option\nset-option -g display-time 750\n\n# Customize Tmux logging output directory\nset-option -g @logging-path "~/tmux-logging-output"\nset-option -g @screen-capture-path "~/tmux-logging-output"\n\nset-window-option -g mode-keys vi\nbind-key "c" new-window \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"\nbind-key "\"" split-window \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"\nbind-key "%" split-window -h \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"\n\n# Initialize plugins\nrun-shell "~/.tmux/plugins/tpm/tpm"\nrun-shell "~/.tmux/plugins/tmux-logging/logging.tmux"' > "$HOME/.tmux.conf"
		if [[ $logoutputdir ]]
		then
			sed -i "s/\~\/tmux-logging-output/${logoutputdir//\//\\/}/" "$HOME/.tmux.conf"
		elif [[ `ls | head -n 1` =~ Administrative|.*-notes-.* ]]
		then
			newlogdir=`find . -type d -name "*-notes-*" -exec mkdir {}/Logging-Output \; -exec echo "{}/Logging-Output" \;`
			logoutputdir=`realpath $newlogdir`
			sed -i "s/\~\/tmux-logging-output/${logoutputdir//\//\\/}/" "$HOME/.tmux.conf"
		fi
		if [[ $? -eq 0 ]]
		then
			pause && echo -e "Initialized\e[0m new \e[36m$HOME/.tmux.conf\e[0m with optimal settings..."
			return 0
		else
			echo -e "\e[31mCould not initialize\e[36m $HOME/.tmux.conf.\e[0m Continuing..."
			return 1
		fi
	else
		pause && echo -e "Using the existing\e[36m ~/.tmux.conf\e[0m file. Continuing..."
		return 0
	fi
}

lower_duration() {
	duration_comment="# display_duration defaults to 5 seconds, if not passed as an argument"
	display_duration="local display_duration=\"5000\""
	shared="$HOME/.tmux/plugins/tmux-logging/scripts/shared.sh"
	sed -i "s/$duration_comment\$/`sed -E 's/5 \w+/750 ms (newtmux.sh)/' <<< $duration_comment`/" $shared &>/dev/null
	sed -i "s/$display_duration\$/`sed 's/5000/750/' <<< $display_duration`/" $shared &>/dev/null
	if [[ $? -eq 0 ]]
	then
		pause && echo -e "Message durations \e[32mwere lowered\e[0m for the \e[33m\"tmux-logging\"\e[0m plugin..."
		return 0
	else
		echo -e "\e[31mMessage durations could not be lowered\e[0m for the \e[36m\"tmux-logging\"\e[0m plugin..."
		return 1
	fi
}

start_tmux() {
	[[ $NUM_WINDOWS ]] || NUM_WINDOWS=1
	[[ $logoutputdir ]] && cd $logoutputdir/..
	log="run-shell $HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"
	window_0="select-window -t 0" && pane_0="select-pane -t 0"
	winstring=`[[ $NUM_WINDOWS -ge 2 ]] && echo "windows" || echo "window"` && pause
	echo -e "Starting \e[33mTmux\e[0m with \e[36m$NUM_WINDOWS\e[0m horizontally-split $winstring..." && $STATUS && sleep 2
	case $NUM_WINDOWS in
		1)
			tmux new -s $SESSION_NAME \; $log \; split-window \; $log \; $pane_0;;
		2)
			tmux new -s $SESSION_NAME \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; $window_0 \; $pane_0;;
		3)
			tmux new -s $SESSION_NAME \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; $window_0 \; $pane_0;;
		4)
			tmux new -s $SESSION_NAME \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; $window_0 \; $pane_0;;
		5)
			tmux new -s $SESSION_NAME \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; new-window \; $log \; split-window \; $log \; $window_0 \; $pane_0;;
	esac
	if [[ $? -eq 0 ]]
	then
		exit 0
	else
		echo -e "Error - \[31mCould not start tmux.\e[0m Exiting..."
		exit 1
	fi
}

help() {
	echo -e "\e[36mUsage: \e[32m$SCRIPT_NAME \e[33m-n {tmux-session-name} \e[0m[-w {num_windows} | -e | -k | -s | -h]"
	echo -e "\e[36m\nMandatory argument:\e[0m"
	echo -e " \e[33m-n\e[0m | Tmux Session Name"
	echo -e "\e[36m\nOptional arguments:\e[0m"
	echo -e " \e[35m-w\e[0m | Specify number of horizontally-split windows to open (default 1, maximum 5)"
	echo -e " \e[35m-k\e[0m | Use the existing .tmux.conf file instead of an optimized one"
	echo -e " \e[35m-s\e[0m | Swift and Slient mode (disables status messages)"
	echo -e " \e[35m-e\e[0m | Run engagementinit.sh before newtmux begins (Alias required)"
	echo -e " \e[35m-h\e[0m | Display this help menu"
	echo -e "\n\e[36mExample execution (with an alias in ~/.zshrc or ~/.bashrc):"
	echo -e " \e[32m$SCRIPT_NAME \e[33m-n\e[0m flast \e[35m-w\e[0m 2 \e[35m-e\e[0m"
	return 0
}

pause() {
	$STATUS && sleep 0.5
	return $?
}

while getopts :n:w:eksh option
do
	case $option in
		n) # Tmux Session Name
			SESSION_NAME=${OPTARG};;
		w) # Number of horizontally-split windows to open (default 1, maximum 5)
			if ! [[ $OPTARG -ge 1 && $OPTARG -le 5 ]]
			then
				echo -e "Error — \e[31mInvalid argument\e[0m for option \e[35m-w"
				echo -e "\e[36mMin:\e[0m 1, \e[36mMax:\e[0m 5, \e[36mDefault (no flag):\e[0m 1"
				exit 1
			fi
			NUM_WINDOWS=$OPTARG;;
		k) # Use the existing .tmux.conf instead of an optimized one
			KEEP_CONF=true;;
		s) # Swift and Slient mode (disables status messages)
			STATUS=false;;
		e) # Run engagement-init before newtmux starts its own actions
			einit;;
		h) # Display help menu
			help
			exit 0;;
		\?)# Invalid option
			echo -e "Error — \e[31mUnknown option provided.\e[0m Exiting..."
			exit 1;;
		:) # Missing argument
			echo -e "Error — \e[31mMissing option argument\e[0m for\e[35m -$OPTARG\e[0m Exiting..."
			exit 1;;
	esac
done

if [[ $SESSION_NAME =~ ^-.$ || -z $SESSION_NAME ]]
then
	echo -e "Error — \e[31mYou must provide a session name \e[0mfor \e[32m$SCRIPT_NAME\e[0m to create.\n"
	help
	exit 1
fi

main