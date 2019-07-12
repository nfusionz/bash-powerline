#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

## Uncomment to enable powerline-fonts
#POWERLINE_FONTS=1

## Uncomment to disable separator overlap
#POWERLINE_OVERLAP=0

__powerline() {    
    # Colorscheme
    # readonly SYMBOL_GIT_BRANCH='⑂'
    readonly SYMBOL_GIT_PUSH='↑'
    readonly SYMBOL_GIT_PULL='↓'

    if [[ $POWERLINE_FONTS -eq 1 ]]; then
	readonly PS_DIVIDER=''
    else
	readonly PS_DIVIDER=''
    fi

    readonly DEFAULT_BG_COLOR=49
    readonly DEFAULT_FG='39'

    readonly BASE_BG_COLOR=46
    readonly BASE_BG_EXTRA=""
    readonly BASE_FG='1;37'
    readonly BASE_STR="\u"

    readonly CWD_BG_COLOR=45
    readonly CWD_BG_EXTRA=""
    readonly CWD_FG='1;37'

    readonly GIT_BG_COLOR=100
    readonly GIT_BG_EXTRA=''
    readonly GIT_FG='1;37'
    readonly GIT_FG_MODIFIED='1;3;31'
    readonly SYMBOL_GIT_MODIFIED=''

    readonly PS_ZERO_BG_COLOR=42
    readonly PS_ERR_BG_COLOR=41
    readonly PS_ZERO_BG_EXTRA=''
    readonly PS_ERR_BG_EXTRA=''
    readonly PS_ZERO_FG='1;37'
    readonly PS_ERR_FG='1;37'

    if [[ -z "$PS_SYMBOL" ]]; then
      case "$(uname)" in
          Darwin)   PS_SYMBOL='';;
          Linux)    PS_SYMBOL='λ';;
          *)        PS_SYMBOL='%';;
      esac
    fi

    __git_info() { 
        [[ $POWERLINE_GIT = 0 ]] && return # disabled
        hash git 2>/dev/null || return # git not found
        local git_eng="env LANG=C git"   # force git output in English to make our work easier

        # get current branch name
        local ref=$($git_eng symbolic-ref --short HEAD 2>/dev/null)

        if [[ -n "$ref" ]]; then
            # prepend branch symbol
            ref=$SYMBOL_GIT_BRANCH$ref
        else
            # get tag name or short unique hash
            ref=$($git_eng describe --tags --always 2>/dev/null)
        fi

        [[ -n "$ref" ]] || return  # not a git repo

        local marks

        # scan first two lines of output from `git status`
        while IFS= read -r line; do
            if [[ $line =~ ^## ]]; then # header line
                [[ $line =~ ahead\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PUSH${BASH_REMATCH[1]}"
                [[ $line =~ behind\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PULL${BASH_REMATCH[1]}"
            else # branch is modified if output contains more lines after the header line
		printf "$ref$SYMBOL_GIT_MODIFIED$marks"
		return 1
            fi
        done < <($git_eng status --porcelain --branch 2>/dev/null)  # note the space between the two <

        # print the git branch segment without a trailing newline
        printf "$ref$marks"
    }

    # Adds to PS1
    # Takes the text, block_bg, block_fg, disable spacing, redirect boolean (for security reasons)
    __block() {
	if [[ -n $1 ]]; then	    
	    if [[ -n "$__LAST_BG" ]]; then
		if [[ $POWERLINE_OVERLAP = 0 ]]; then
		    PS1+="$PS_DIVIDER"
		else
		    local __divider_fg=$((__LAST_BG - 10))
		    PS1+="\[\033[$__divider_fg;$2m\]$PS_DIVIDER"
		fi
	    fi

	    PS1+="\[\033[$2;$3m\]"
	    [[ $4 -eq 1 ]] || PS1+=" "
	    shopt -q promptvars
	    if [[ $? && $5 -eq 1 ]]; then
		__redirect+="$1"
		PS1+="\${__redirect[$__redirect_counter]}"
		__redirect_counter+=1
	    else
		PS1+="$1"
	    fi
	    [[ $4 -eq 1 ]] || PS1+=" "
	    PS1+="\[\033[m\]"
	    __LAST_BG=$2
	fi
    }

    __short_path() {
	local short=""
	local path="$(dirs)"
	while [[ $path =~ ^((\/?)([^\n\/])[^\n\/]*\/) ]]; do
	    short+="${BASH_REMATCH[2]}${BASH_REMATCH[3]}/"
	    path=${path#*"${BASH_REMATCH[1]}"}
	done
	short+="$path"
	echo "$short"
    }

    ps1() {
	
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly. 
        if [ $? -eq 0 ]; then
            local ps_style=("$PS_ZERO_BG_COLOR" "$PS_ZERO_FG")
        else
            local ps_style=("$PS_ERR_BG_COLOR" "$PS_ERR_FG")
        fi

	unset __LAST_BG

        local cwd=$(__short_path) #"\w"
        
	__redirect=()
	__redirect_counter=0

	git="$(__git_info)"
	if [[ $? -eq 1 ]]; then
	    local git_style="$GIT_FG_MODIFIED"
	else
	    local git_style="$GIT_FG"
	fi
	
	# Generate PS1
	PS1=""
	__block "$BASE_STR" "$BASE_BG_COLOR" "$BASE_FG"
	__block "$cwd" "$CWD_BG_COLOR" "$CWD_FG"
	__block "$git" "$GIT_BG_COLOR" "$git_style" 0 1
	__block "$PS_SYMBOL" "${ps_style[0]}" "${ps_style[1]}" 0
	__block " " "$DEFAULT_BG_COLOR" "$DEFAULT_FG" 1
    }

    PROMPT_COMMAND="ps1${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

__powerline
unset __powerline
