function fish_config
    if test "$argv[1]" = "theme" -a "$argv[2]" = "choose" -a "$argv[4]" = "--no-override"
        return 0
    end
    builtin functions -e fish_config
    fish_config $argv
end
