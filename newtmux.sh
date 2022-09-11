#!/usr/bin/env bash
# newtmux.sh — Tmux Session & Logging Optimizer — Version 2.0 — Created by Daniel Velez
# Starts Tmux with specified number [-w] of horizontally-split windows (default 1, maximum 5)
# Automatically enables logging for each pane via the "tmux-logging" plugin, then selects the first pane
# Filters ANSI color codes from log output text streams via ansi2text/sed for easy copy/paste into reports
# Lowers the message duration for all "tmux-logging" plugin messages by 90% (5000 ms --> 500 ms)
# Creates an optimized Tmux config file (keybinds, history limit, etc.) after backing up the existing one
# Integrates with engagement-init with [-e] or if the current folder is located in a project directory tree
# Otherwise, a "tmux-logging-output" folder is created in your home directory to store all logs and screen captures
# Detects whether or not the "tmux-logging" plugin is installed, prompts to install it automatically if not
# Identifies if a compatible version of Tmux is installed, prompts to update Tmux automatically if not

SCRIPT_NAME=`basename $0` && SCRIPT_NAME=${SCRIPT_NAME%.*}
unset LOGOUTPUTDIR && STATUS=true && KEEP_CONF=false

main() {
	check_version
	detect_tmux_logging
	install_ansi2txt
	optimize_config
	lower_duration
	start_tmux
}

einit() {
	file=~/.zshrc && [[ -f ~/.zshrc ]] || file=~/.bashrc && [[ -f ~/.bashrc ]]
	if alias=`grep -o -h 'alias einit.*' $file` || alias=`grep -o -h 'alias engagementinit.*' $file` || alias=`grep -o -h 'alias engagement-init.*' $file`
	then
		einit=`cut -d '=' -f 2 <<< $alias` && einit=`tr -d \'\" <<< $einit` && einit=${einit/#\~/$HOME}
		read -p $'\033[36mEngagement SKU\033[0m (IPT/EPT/CPT/ADSR/RTA/etc.): ' esku
		read -p $'\033[31mOpportunity Number: \033[0m' onum
		read -p $'\033[32mClient Name: \033[0m' cname && cname=`tr ' ' '-' <<< $cname`
		read -p $'\033[35mYour Initials: \033[0m' yini
		printf '—%.0s' {1..50} && echo
		$einit -e $esku -o $onum -c $cname -i $yini &>/dev/null
		if [[ $? -eq 0 ]]
		then
			pause && echo -e "\033[33mengagementinit\033[32m completed successfully.\033[0m Continuing..."
			project="`pwd`/$cname-$onum-$esku"
			if [[ -d "$project-02" ]]; then pdir="$project-02"; else pdir="$project-01"; fi
			LOGOUTPUTDIR="$pdir/Evidence/$cname-notes-$yini/Logging-Output"
			mkdir "$LOGOUTPUTDIR" &>/dev/null
			return 0
		else
			echo -e "\033[33mengagementinit\033[31m failed to complete\033[0m Continuing..."
			return 1
		fi
	else
		echo -e "\033[33mengagementinit\033[31m could not be located\033[0m as an alias."
		echo -e "(\033[36meinit\033[0m, \033[36mengagementinit\033[0m, \033[36mengagement-init\033[0m). Continuing..."
		return 1
	fi
}

check_version () {
	if [[ `tmux -V | tr -dC '[:digit:]'` -lt 30 ]]
	then
		echo -e "\nThe \033[33mversion of Tmux\033[0m that you are using \033[31mis outdated\033[0m."
		echo -e "This can \033[0mcause \033[35msome features\033[0m of $SCRIPT_NAME to \033[31mnot work properly\033[0m."
		echo -e "Would you like \033[33m$SCRIPT_NAME\033[0m to \033[32minstall the latest version\033[0m?"
		echo -e "All existing \033[33mTmux\033[0m sessions \033[31mwill be killed\033[0m before the update is initiated."
		if [[ `uname` != "Darwin" ]]
		then
			echo -e "\nCommands:"
			echo -e "\033[36msudo apt remove \033[35mtmux \033[33m-y"
			echo -e "\033[36msudo apt install \033[35mlibevent-dev ncurses-dev build-essential bison pkg-config automake \033[33m-y"
			echo -e "\033[36mgit clone \033[35mhttps://github.com/tmux/tmux.git /tmp/latest_tmux\033[0m && \033[33mcd /tmp/latest_tmux \033[0m"
			echo -e "\033[33msh autogen.sh \033[0m&&\033[33m ./configure \033[0m&& \033[36mmake\033[0m && \033[36msudo make install\033[0m"
			echo && read -n 1 -p "[y | n] " choice && echo
			if [[ $choice =~ y|Y ]]
			then
				pause && echo "Updating Tmux. Please wait..." && tmux kill-server &>/dev/null
				sudo apt remove tmux -y &>/dev/null
				sudo apt install libevent-dev ncurses-dev build-essential bison pkg-config automake -y &>/dev/null
				git clone https://github.com/tmux/tmux.git /tmp/latest_tmux &>/dev/null && cd /tmp/latest_tmux
				sh autogen.sh &>/dev/null && ./configure &>/dev/null && make &>/dev/null && sudo make install &>/dev/null
				if [[ $? -eq 0 ]]
				then
					rm -rf /tmp/latest_tmux && pause && clear
					echo -e "\033[33mTmux\033[0m was \033[32msuccessfully updated.\033[0m Exiting..."
					echo -e "Please re-run \033[33m$SCRIPT_NAME\033[0m with the same arguments.\n"
					exit 0
				else
					echo -e "Error — \033[33mTmux\033[31m failed to install.\033[0m Exiting..."
					exit 1
				fi
			elif [[ $choice =~ n|N ]]
			then
				pause && echo -e "Continuing \033[31mwithout updating \033[33mTmux\033[0m..."
				return 0
			else
				echo -e "Error — \033[31mInvalid input.\033[0m Exiting..."
				exit 1
			fi
		else
			echo -e "\nCommands:"
			echo -e "\033[36mbrew update\033[33m"
			echo -e "\033[36mbrew upgrade\033[0m"
			echo && read -n 1 -p "[y | n] " choice && echo
			if [[ $choice =~ y|Y ]]
			then
				pause && echo "Updating Tmux. Please wait..." && tmux kill-server &>/dev/null
				brew update &>/dev/null
				brew upgrade &>/dev/null
				if [[ $? -eq 0 ]]
				then
					pause && clear
					echo -e "\033[33mTmux\033[0m was \033[32msuccessfully updated.\033[0m Exiting..."
					echo -e "Please re-run \033[33m$SCRIPT_NAME\033[0m with the same arguments.\n"
					exit 0
				else
					echo -e "Error — \033[33mTmux\033[31m failed to install.\033[0m Exiting..."
					exit 1
				fi
			elif [[ $choice =~ n|N ]]
			then
				pause && echo -e "Continuing \033[31mwithout updating \033[33mTmux\033[0m..."
				return 0
			else
				echo -e "Error — \033[31mInvalid input.\033[0m Exiting..."
				exit 1
			fi
		fi
	fi
}

detect_tmux_logging() {
	if [ "$TERM_PROGRAM" == "tmux" ]
	then
	  echo -e "Error — \033[32m$SCRIPT_NAME \033[31mcannot be executed \033[0minside of a \033[35mTmux\033[0m session."
	  echo -e "Please \033[31mdetach from \033[0mor\033[31m kill\033[0m your current \033[35mTmux\033[0m session and re-run \033[32m$SCRIPT_NAME\033[0m..."
	  exit 1
	fi
	if ! [[ -d ~/.tmux/plugins/tmux-logging ]]
	then
		echo -e "\033[33mtmux-logging\033[0m was \033[31mnot detected\033[0m, but is \033[31mrequired\033[0m."
		echo -e "Would you like \033[35m$SCRIPT_NAME\033[0m to \033[32minstall it automatically\033[0m?"
		read -n 1 -p "[y | n] " choice && echo
		if [[ $choice =~ y|Y ]]
		then
			echo "set -g @plugin 'tmux-plugins/tpm'\nset -g @plugin 'tmux-plugins/tmux-sensible'\nset -g @plugin 'tmux-plugins/tmux-logging'\nrun '~/.tmux/plugins/tpm/tpm'" > /tmp/install-tmux-plugins
			tmux new -s install_plugins \; source-file /tmp/install-tmux-plugins \; run ~/.tmux/plugins/tpm/scripts/install_plugins.sh \; run -d 5 source-file ~/.tmux.conf \; run -d 1 -C kill-session &>/dev/null
			if [[ $? -eq 0 ]]
			then
				pause && echo -e "\n\033[33mtmux-logging\033[0m was installed. Continuing..."
				return 0
			else
				echo -e "Error — \033[33mtmux-logging\033[31m failed to install\033[0m. Exiting..."
				exit 1
			fi
		elif [[ $choice =~ n|N ]]
		then
			echo -e "Error — \033[33mtmux-logging\033[31m must be installed\033[0m. Exiting..."
			return 0
		else
			echo -e "Error — \033[31mInvalid input.\033[0m Exiting..."
			exit 1
		fi
	fi
}

install_ansi2txt() {
	if [[ `uname` == "Darwin" ]]
	then
		if [[ `command -v ansifilter` ]]
		then
			echo -e "\033[33mansifilter\033[0m \033[31mis installed.\033[0m Would you like to remove it?"
			echo -e "This enables \033[33m$SCRIPT_NAME\033[0m to be more accurate when removing \033[32mANSI color coding\033[0m from log files."
			echo -n -e "\nCommand:\033[34m brew remove ansifilter \033[0m\c"
			read -n 1 -p "[y | n] " choice && echo
			if [[ $choice =~ y|Y ]]
			then
				brew remove ansifilter &>/dev/null
				if [[ $? -eq 0 ]]
				then
					pause && echo -e "\n\033[33mansifilter\033[0m was removed. Continuing..."
					return 0
				else
					echo -e "Error — \033[33mansifilter\033[31m failed to uninstall.\033[0m Exiting..."
					exit 1
				fi
			elif [[ $choice =~ n|N ]]
			then
				pause && echo -e "Continuing without removing \033[33mansifilter\033[0m..."
				return 0
			else
				echo -e "Error — \033[31mInvalid input.\033[0m Exiting..."
				exit 1
			fi
		else
			pause && echo -e "\033[33msed ANSI filtering \033[32mis enabled. \033[0mContinuing..."
			return 0
		fi
	elif ! [[ `command -v ansi2txt` ]]
	then
		echo -e "\033[33mansi2txt\033[0m is\033[31m not installed.\033[0m Would you like to install it?"
		echo -e "This enables \033[33m$SCRIPT_NAME\033[0m to remove \033[32mANSI color coding\033[0m from log files."
		echo -n -e "\nCommand:\033[36m sudo apt install \033[35mcolorized-logs \033[33m-y\033[0m \c"
		read -n 1 -p "[y | n] " choice && echo
		if [[ $choice =~ y|Y ]]
		then
			sudo apt install colorized-logs -y &>/dev/null
			if [[ $? -eq 0 ]]
			then
				sed -i'' -e "s/ansifilter/ansi2txt/" "$HOME/.tmux/plugins/tmux-logging/scripts/start_logging.sh"
				pause && echo -e "\n\033[33mansi2txt\033[0m was \033[32minstalled and configured\033[0m. Continuing..."
				return 0
			else
				echo -e "Error — \033[33mansi2txt\033[31m failed to install.\033[0m Exiting..."
				exit 1
			fi
		elif [[ $choice =~ n|N ]]
		then
			pause && echo -e "Continuing \033[31mwithout installing \033[33mansi2txt\033[0m..."
			return 0
		else
			echo -e "Error — \033[31mInvalid input.\033[0m Exiting..."
			exit 1
		fi
	else
		pause && echo -e "\033[33mansi2txt \033[32mis present. \033[0mContinuing..."
		sed -i'' -e "s/ansifilter/ansi2txt/" "$HOME/.tmux/plugins/tmux-logging/scripts/start_logging.sh"
		return 0
	fi
}

optimize_config() {
	if [[ $KEEP_CONF == false ]]
	then
		if [[ -f "$HOME/.tmux.conf" && ! `openssl md5 "$HOME/.tmux.conf" | cut -d " " -f 2` == "8e588c74e5e9148ade5649eb8c951129" ]]
		then
			date=`date "+%F-%R"`
			success_msg="Backed up previous config file to \033[36m$HOME/.tmux.conf.bak-$date\033[0m"
			mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak-$date" && pause && echo -e $success_msg
		fi
		echo -e 'set -g default-shell /bin/zsh\n\n# List of plugins\nset -g @plugin "tmux-plugins/tmux-logging"\nset -g @plugin "tmux-plugins/tpm"\nset -g @plugin "tmux-plugins/tmux-sensible"\n\n# Set command history limit\nset -g history-limit 250000\n\n# Disable session renaming\nset -g allow-rename off\n\n# Change display-time session option\nset -g display-time 750\n\n# Customize Tmux logging output directory\nset -g @logging-path $HOME/tmux-logging-output\nset -g @screen-capture-path $HOME/tmux-logging-output\n\nset-window-option -g mode-keys vi\nbind "c" new-window \; run $HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh\nbind "\"" split-window \; run $HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh\nbind "%" split-window -h \; run $HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh\n\n# Initialize plugins\nrun $HOME/.tmux/plugins/tpm/tpm\nrun $HOME/.tmux/plugins/tmux-logging/logging.tmux' > "$HOME/.tmux.conf"
		if [[ $LOGOUTPUTDIR ]]
		then
			sed -i'' -e "s/\$HOME\/tmux-logging-output/${LOGOUTPUTDIR//\//\\/}/" "$HOME/.tmux.conf"
		elif [[ `ls | head -n 1` =~ Administrative|.*-notes-.* ]]
		then
			newlogdir=`find . -type d -name "*-notes-*" -exec mkdir {}/Logging-Output \; -exec echo "{}/Logging-Output" \;`
			LOGOUTPUTDIR=`realpath $newlogdir`
			sed -i'' -e "s/\$HOME\/tmux-logging-output/${LOGOUTPUTDIR//\//\\/}/" "$HOME/.tmux.conf"
		fi
		if [[ $? -eq 0 ]]
		then
			pause && echo -e "Initialized\033[0m new \033[36m$HOME/.tmux.conf\033[0m with optimal settings..."
			return 0
		else
			echo -e "\033[31mCould not initialize\033[36m $HOME/.tmux.conf.\033[0m Continuing..."
			return 1
		fi
	else
		pause && echo -e "Using the existing\033[36m ~/.tmux.conf\033[0m file..."
		return 0
	fi
}

lower_duration() {
	duration_comment="# display_duration defaults to 5 seconds, if not passed as an argument"
	display_duration="local display_duration=\"5000\""
	shared="$HOME/.tmux/plugins/tmux-logging/scripts/shared.sh"
	sed -i'' -e "s/$duration_comment\$/`sed -E 's/5 \w+/750 ms (newtmux.sh)/' <<< $duration_comment`/" $shared &>/dev/null
	sed -i'' -e "s/$display_duration\$/`sed 's/5000/750/' <<< $display_duration`/" $shared &>/dev/null
	if [[ $? -eq 0 ]]
	then
		pause && echo -e "Message durations \033[32mwere lowered\033[0m for the \033[33m\"tmux-logging\"\033[0m plugin..."
		return 0
	else
		echo -e "\033[31mMessage durations could not be lowered\033[0m for the \033[36m\"tmux-logging\"\033[0m plugin..."
		return 1
	fi
}

start_tmux() {
	[[ $NUM_WINDOWS ]] || NUM_WINDOWS=1
	[[ $LOGOUTPUTDIR ]] && cd $LOGOUTPUTDIR/..
	log="run $HOME/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh" && pause
	window_0="select-window -t 0" && pane_0="select-pane -t 0" && winstring=`[[ $NUM_WINDOWS -ge 2 ]] && echo "windows" || echo "window"`
	echo -e "Starting \033[33mTmux\033[0m with \033[36m$NUM_WINDOWS\033[0m horizontally-split $winstring..." && $STATUS && sleep 1
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
		echo -e "Error - \033[31mCould not start tmux.\033[0m Exiting..."
		exit 1
	fi
}

help() {
	echo -e "[\033[36mTmux Session & Logging Optimizer \033[0m— \033[32mVersion 2.0\033[0m]\n"
	echo -e "\033[36mUsage: \033[32m$SCRIPT_NAME \033[33m-n {tmux-session-name} \033[0m[-w {num_windows} | -k | -s | -e | -h]"
	echo -e "\033[36m\nMandatory argument:\033[0m"
	echo -e " \033[33m-n\033[0m | Tmux Session Name"
	echo -e "\033[36m\nOptional arguments:\033[0m"
	echo -e " \033[35m-w\033[0m | Number of horizontally-split windows to open (default 1, maximum 5)"
	echo -e " \033[35m-k\033[0m | Use the existing .tmux.conf file instead of an optimized one"
	echo -e " \033[35m-s\033[0m | Swift and Slient mode (disables status messages)"
	echo -e " \033[35m-e\033[0m | Run engagementinit.sh before newtmux begins (Alias required)"
	echo -e " \033[35m-h\033[0m | Display this help menu"
	echo -e "\n\033[36mExample execution (with an alias set):"
	echo -e " \033[32m$SCRIPT_NAME \033[33m-n\033[0m flast \033[35m-w\033[0m 2 \033[35m-e\033[0m"
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
				echo -e "Error — \033[31mInvalid argument\033[0m for option \033[35m-w"
				echo -e "\033[36mMin:\033[0m 1, \033[36mMax:\033[0m 5, \033[36mDefault (no flag):\033[0m 1"
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
			echo -e "Error — \033[31mUnknown option provided.\033[0m Exiting..."
			exit 1;;
		:) # Missing argument
			echo -e "Error — \033[31mMissing option argument\033[0m for\033[35m -$OPTARG\033[0m Exiting..."
			exit 1;;
	esac
done

if [[ $SESSION_NAME =~ ^-.$ || -z $SESSION_NAME ]]
then
	echo -e "Error — \033[31mYou must provide a session name \033[0mfor \033[32m$SCRIPT_NAME\033[0m to create.\n"
	help
	exit 1
fi

main
