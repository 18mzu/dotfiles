if status is-interactive

end
function fish_greeting
    set_color FFB0B5
    echo "  meowzu ฅ^•ﻌ•^ฅ"
    set_color normal
end

starship init fish | source

function compile
    clang++ -g $argv[1] -o $argv[2]
end

function run
    if test (count $argv) -eq 0
        ./main
    else
        ./$argv[1]
    end
end

zoxide init fish | source
