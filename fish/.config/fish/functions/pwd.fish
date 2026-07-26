function pwd
    set -l real_pwd (command pwd)
    set -l display_pwd (string replace $HOME '~' $real_pwd)
    set_color 8BE9FD --bold
    echo $display_pwd
    set_color normal
end
