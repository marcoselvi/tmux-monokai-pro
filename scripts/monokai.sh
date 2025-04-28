#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

main()
{
  # set configuration option variables
  show_kubernetes_context_label=$(get_tmux_option "@monokai-kubernetes-context-label" "")
  eks_hide_arn=$(get_tmux_option "@monokai-kubernetes-eks-hide-arn" false)
  eks_extract_account=$(get_tmux_option "@monokai-kubernetes-eks-extract-account" false)
  hide_kubernetes_user=$(get_tmux_option "@monokai-kubernetes-hide-user" false)
  terraform_label=$(get_tmux_option "@monokai-terraform-label" "")
  show_fahrenheit=$(get_tmux_option "@monokai-show-fahrenheit" false)
  show_location=$(get_tmux_option "@monokai-show-location" false)
  fixed_location=$(get_tmux_option "@monokai-fixed-location")
  show_powerline=$(get_tmux_option "@monokai-show-powerline" false)
  show_flags=$(get_tmux_option "@monokai-show-flags" false)
  show_left_icon=$(get_tmux_option "@monokai-show-left-icon" session)
  show_left_icon_padding=$(get_tmux_option "@monokai-left-icon-padding" 0)
  show_military=$(get_tmux_option "@monokai-military-time" false)
  timezone=$(get_tmux_option "@monokai-set-timezone" "GMT")
  show_timezone=$(get_tmux_option "@monokai-show-timezone" false)
  show_left_sep=$(get_tmux_option "@monokai-show-left-sep" )
  show_left_end=$(get_tmux_option "@monokai-show-left-end" )
  show_right_sep=$(get_tmux_option "@monokai-show-right-sep" )
  show_right_end=$(get_tmux_option "@monokai-show-right-end" )
  show_day_month=$(get_tmux_option "@monokai-day-month" false)
  show_refresh=$(get_tmux_option "@monokai-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@monokai-synchronize-panes-label" "Sync")
  time_format=$(get_tmux_option "@monokai-time-format" "")
  show_ssh_session_port=$(get_tmux_option "@monokai-show-ssh-session-port" false)
  IFS=' ' read -r -a right_plugins <<< $(get_tmux_option "@monokai-right-plugins" "network-ping cpu-usage ram-usage")
  IFS=' ' read -r -a left_plugins <<< $(get_tmux_option "@monokai-left-plugins" "session")
  show_empty_plugins=$(get_tmux_option "@monokai-show-empty-plugins" true)

  # Monokai Pro Color Pallette
  white='#fcfcfa'
  black='#161716'
  dark_gray='#403e41'
  gray='#727072'
  red='#ff6188'
  green='#a9dc76'
  yellow='#ffd866'
  blue='#78dce8'
  magenta='#fc9867'
  cyan='#ab9df2'

  # Handle left icon configuration
  case $show_left_icon in
    smiley)
      left_icon="☺";;
    session)
      left_icon="#S";;
    window)
      left_icon="#W";;
    hostname)
      left_icon="#H";;
    shortname)
      left_icon="#h";;
    *)
      left_icon=$show_left_icon;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Handle powerline option
  if $show_powerline; then
    left_sep="$show_left_sep"
    left_end="$show_left_end"
    right_sep="$show_right_sep"
    right_end="$show_right_end"
  fi

  # start weather script in background
  if [[ "${right_plugins[@]}" =~ "weather" ]]; then
    $current_dir/sleep_weather.sh $show_fahrenheit $show_location $fixed_location &
  fi

  # Set timezone unless hidden by configuration
  if [[ -z "$timezone" ]]; then
    case $show_timezone in
      false)
        timezone="";;
      true)
        timezone="#(date +%Z)";;
    esac
  fi

  case $show_flags in
    false)
      flags=""
      current_flags="";;
    true)
      flags="#{?window_flags,#[fg=${cyan}]#{window_flags},}"
      current_flags="#{?window_flags,#[fg=${cyan}]#{window_flags},}"
  esac

  # sets refresh interval to every $show_refresh seconds
  tmux set-option -g status-interval $show_refresh

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  tmux set-option -g pane-active-border-style "fg=${green}"
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${dark_gray},fg=${white}"

  # Status left
  tmux set-option -g status-left ""

  if $show_powerline; then
    powerfg=${black}
    powerbg=${dark_gray}
  fi

  len=${#left_plugins[@]}
  for (( i=0; i<$len; i++ )); do
    plugin=${left_plugins[i]}

    if [ $plugin = "session" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@monokai-session-colors" "green black")
      tmux set-option -g status-left-length 250
      script="#S"

    elif [ $plugin = "host" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@monokai-host-colors" "yellow black")
      tmux set-option -g status-left-length 250
      script="#h"

    else
      continue
    fi

    fgcolor="#{?client_prefix,$magenta,$powerfg}"
    bgcolor="#{?client_prefix,$magenta,${!colors[0]}}"
    if [ $i -eq 0 ] && $show_powerline; then
      left_symbol="#[fg=$bgcolor,bg=${black},nobold,nounderscore,noitalics]${left_end}"
    elif $show_powerline; then
      left_symbol="#[fg=$fgcolor,bg=$bgcolor,nobold,nounderscore,noitalics]${left_sep}"
    else
      left_symbol=""
    fi
    if $show_empty_plugins; then
      tmux set-option -ga status-left "$left_symbol#[fg=${!colors[1]},bg=$bgcolor,bold] $script "
    else
      tmux set-option -ga status-left "#{?#{==:$script,},,$left_symbol#[fg=${!colors[1]},bg=$bgcolor,bold] $script }"
    fi
    powerfg=${!colors[0]}

  done

  if $show_powerline; then
    fgcolor="#{?client_prefix,$magenta,$powerfg}"
    tmux set-option -ga status-left "#[fg=$fgcolor,bg=${powerbg}]${left_sep}"
    left_sep="$show_left_sep"
  fi

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${right_plugins[@]}"; do

    if case $plugin in custom:*) true;; *) false;; esac; then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-custom-plugin-colors" "blue black")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="black"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@monokai-cwd-colors" "dark_gray white")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "fossil" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@monokai-fossil-colors" "green black")
      tmux set-option -g status-right-length 250
      script="#($current_dir/fossil.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@monokai-git-colors" "green black")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "hg" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@monokai-hg-colors" "green black")
      tmux set-option -g status-right-length 250
      script="#($current_dir/hg.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-battery-colors" "red black")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-gpu-usage-colors" "red black")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-gpu-ram-usage-colors" "blue black")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-gpu-power-draw-colors" "green black")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-cpu-usage-colors" "magenta black")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-ram-usage-colors" "yellow black")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "tmux-ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-tmux-ram-usage-colors" "yellow black")
      script="#($current_dir/tmux_ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-network-colors" "blue black")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-network-bandwidth-colors" "blue black")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-network-ping-colors" "dark_gray white")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-network-vpn-colors" "blue black")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-attached-clients-colors" "blue black")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "mpc" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-mpc-colors" "green black")
      script="#($current_dir/mpc.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-spotify-tui-colors" "green black")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "playerctl" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-playerctl-colors" "green black")
      script="#($current_dir/playerctl.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-kubernetes-context-colors" "blue black")
      script="#($current_dir/kubernetes_context.sh $eks_hide_arn $eks_extract_account $hide_kubernetes_user $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-terraform-colors" "blue black")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-continuum-colors" "blue black")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-weather-colors" "magenta black")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location '$fixed_location')"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-time-colors" "green black")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military ; then # military time and dd/mm
          script="%a %d/%m %R ${timezone}"
        elif $show_military; then # only military time
          script="%a %m/%d %R ${timezone}"
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone}"
        else
          script="%a %m/%d %I:%M %p ${timezone}"
        fi
      fi

    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-synchronize-panes-colors" "blue black")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"

    elif [ $plugin = "ssh-session" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@monokai-ssh-session-colors" "green black")
      script="#($current_dir/ssh_session.sh $show_ssh_session_port)"

    else
      continue
    fi

    if $show_powerline; then
      separator="#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}"
    else
      separator=""
    fi
    if $show_empty_plugins; then
      tmux set-option -ga status-right "$separator#[fg=${!colors[1]},bg=${!colors[0]},bold] $script "
    else
      tmux set-option -ga status-right "#{?#{==:$script,},,$separator#[fg=${!colors[1]},bg=${!colors[0]},bold] $script }"
    fi
    powerbg=${!colors[0]}

  done

  if $show_powerline; then
    tmux set-option -ga status-right "#[fg=${powerbg},bg=${black},nobold,nounderscore,noitalics]${right_end}"
  fi

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[bg=${gray},fg=${dark_gray}]${left_sep} #[fg=${white},bg=${gray}]#I #W${current_flags} #[bg=${dark_gray},fg=${gray}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${gray}] #I #W${current_flags} "
  fi

  tmux set-window-option -g window-status-format "#[bg=${dark_gray},fg=${dark_gray}]${left_sep} #[fg=${white},bg=${dark_gray}]#I #W${flags} #[bg=${dark_gray},fg=${dark_gray}]${left_sep}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
  tmux set-window-option -g window-status-separator ""
}

# run main function
main
