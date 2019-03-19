#!/bin/bash
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="~/.sdkman"
[[ -s "~/.sdkman/bin/sdkman-init.sh" ]] && source "~/.sdkman/bin/sdkman-init.sh"

###-tns-completion-start-###
if [ -f ~/.tnsrc ]; then 
    source ~/.tnsrc 
fi
###-tns-completion-end-###
