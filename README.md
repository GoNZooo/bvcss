# bvcss

A compiler from a Vim syntax group language to vim colorscheme files.

## Example

```ruby
clear = true
background = dark

Normal: "ececec", "23212e"
Identifier: "46f2f2"

# Tree sitter
@field: Identifier
@type.builtin: Identifier
```

When we run `bvcss example.bvcss` we get the following output:

```vim
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
exec("hi link @type.builtin Identifier")
```

This makes it so that we easily can change group values and the values that
should derive from them without too much ceremony.
