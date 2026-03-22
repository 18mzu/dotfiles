function uninstall --wraps='sudo pacman -Rsnc' --description 'alias uninstall=sudo pacman -Rsnc'
  sudo pacman -Rsnc $argv
        
end
