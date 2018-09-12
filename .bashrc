#!/bin/bash
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/gassertm/.sdkman"
[[ -s "/Users/gassertm/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/gassertm/.sdkman/bin/sdkman-init.sh"

###-tns-completion-start-###
if [ -f /Users/gassertm/.tnsrc ]; then 
    source /Users/gassertm/.tnsrc 
fi
###-tns-completion-end-###
