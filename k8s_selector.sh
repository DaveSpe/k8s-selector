#!/bin/bash
black=$'\e[1;30m'
red=$'\e[1;31m'
green=$'\e[1;32m'
yellow=$'\e[1;33m'
blue=$'\e[1;34m'
purple=$'\e[1;35m'
cyan=$'\e[1;36m'
gray=$'\e[1;37m'
blink=$'\e[5m'
escape=$'\e[0m'

function connect_cluster {
    cluster_list=()
    aws_env=("dev" "qa" "prod")

    # Generate cluster list 
    for each in $(ls ~/.kube/configs/); do cluster_list[${#cluster_list[@]}]=$each; done

    # Prompt for cluster selection
    for each in ${!cluster_list[@]}; do echo $blue $((each + 1))":" ${cluster_list[$each]/.yml/" "} $escape; done
    read -p "$red Please select the number option for one of the above clusters (ex. ': 1'): $escape" cluster_select
    cluster_select=$((cluster_select - 1))

    # Promopt for AWS environment
    echo "$purple stg env is part of prod! $escape"
    for each in ${!aws_env[@]}; do echo $green $((each + 1))":" ${aws_env[$each]} $escape; done
    read -p  "$yellow Which AWS environment would you like to connect to: $escape" assume_env
    assume_env=$((assume_env -1))
    source okta-assumerole ${aws_env[$assume_env]}

    # Run k9s with teh configuration
    KUBECONFIG=~/.kube/configs/${cluster_list[$cluster_select]} k9s
}


function get_k9s {
    k9s_latest=$(curl https://github.com/derailed/k9s/releases | awk /Linux_amd64/ | awk -F'"' 'NR==1 {print $2}')
    online_ver=$(echo $k9s_latest | awk -F'/' '{print $6}')
    current_ver=$(k9s version | awk 'NR==8 {print $2}')
    if [[ $online_ver != $current_ver && $1 == "" ]]; then
        echo "New version is ${online_ver} you have ${current_ver}"
        file_name=$(echo $k9s_latest | awk -F'/' '{print $7}')
        wget https://github.com${k9s_latest} -O /tmp/${file_name}
        tar -xf /tmp/${file_name} -C ~/.local/bin/
        chmod +x ~/.local/bin/k9s
        rm -f /tmp/${file_name}
        echo "Installed!"
    elif [[ $1 != "" ]]; then
	      echo "Installing K9s version $1"
        if [[ $(echo $1 | awk -F'.' '{print $2}') < 27 ]]; then
	          file_name="k9s_Linux_x86_64.tar.gz"
	      else
            file_name="k9s_Linux_amd64.tar.gz"
	      fi
        wget https://github.com/derailed/k9s/releases/download/${1}/${file_name}
        tar -xf /tmp/${file_name} -C ~/.local/bin/
        chmod +x ~/.local/bin/k9s
        rm -f /tmp/${file_name}
        echo "Installed!"
    else
	      echo "Nothing to do your version matches the online version! $1"
    fi
}

function cfg_update {
    # aws eks update-kubeconfig: https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
    configs=()
    aws_env=("dev" "qa" "prod")

    # Generate config list
    for each in $(ls ~/.kube/configs/); do configs[${#configs[@]}]=$each; done

    # Prompt for config file selection
    for each in ${!configs[@]}; do echo $blue $((each + 1))":" ${configs[$each]/.yml/" "} $escape; done
    read -p "$red Please select the number option for one of the above configs (ex. ': 1'): $escape" config_select
    config_select=$((config_select - 1))

    # Promopt for AWS environment
    echo "$purple stg env is part of prod! $escape"
    for each in ${!aws_env[@]}; do echo $green $((each + 1))":" ${aws_env[$each]} $escape; done
    read -p  "$yellow Which AWS environment would you like to connect to: $escape" assume_env
    assume_env=$((assume_env -1))
    source okta-assumerole ${aws_env[$assume_env]}

    # Update Kubeconfig for the selected cluster
    aws eks update-kubeconfig --region us-east-1 --name "${configs[$config_select]/.yml/}" --kubeconfig ~/.kube/configs/${configs[$config_select]}
    # echo "${configs[$config_select]/.yml/}"
}

function help {
cat <<EOF
k8s_selector.sh

Move this file to either '~/.local/bin' or '~/bin/' directory.
Additionally it is helpful to add an alias to your '~/.bashrc' file: "alias k8s='k8s_selector.sh'"

help       	    -- displays this help file
cfg_update 	    -- prompts to update the kube config files, located '~/.kube/configs/'
install [version]   -- when used without a version ex. 'k8s_selector.sh install' will grab the latest version of k9s,
                       otherwise you may specify the vertsion using the following format v0.xx.xx;
                       ex. 'k8s_selector.sh install v0.25.18'
EOF
}

if [[ $1 == "install" ]]; then
    get_k9s $2
elif [[ $1 == "cfg_update" ]]; then
    cfg_update
elif [[ $1 == "help" ]]; then
    help
else
    connect_cluster
fi
