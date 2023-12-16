hi clear
if version > 580
    if exists("syntax_on")
        syntax reset
    endif
endif

if has("gui_running")
    set background=dark
endif

exec("hi Normal guifg=#ececec guibg=#23212e gui=NONE cterm=NONE")
exec("hi Identifier guifg=#46f2f2 gui=NONE cterm=NONE")
exec("hi link @field Identifier")
exec("hi link odinVariable Identifier")
