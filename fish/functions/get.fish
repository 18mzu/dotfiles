function get --wraps='sudo pacman -S' --description 'alias get=sudo pacman -S'
  sudo pacman -S $argv
        
end
