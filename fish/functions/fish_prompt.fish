# Greeting
set -g fish_greeting ""

function fish_greeting
    set_color brmagenta
    echo "meowzu ฅ^•ﻌ•^ฅ"
    set_color normal
end

# Prompt
function fish_prompt
    set_color cyan
    echo -n "~"

    echo ""

    set_color green
    echo -n "> "

    set_color normal
end
