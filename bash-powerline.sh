#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

## Uncomment to disable spacing
#POWERLINE_SPACING=0

## Uncomment to disable separator overlap
#POWERLINE_OVERLAP=0

__powerline() {    
    # Colorscheme
    readonly RESET='\[\033[m\]'

    readonly SYMBOL_GIT_BRANCH='⑂'
    readonly SYMBOL_GIT_MODIFIED='*'
    readonly SYMBOL_GIT_PUSH='↑'
    readonly SYMBOL_GIT_PULL='↓'

    readonly BASE_BG_COLOR=44
    readonly BASE_BG_EXTRA=""
    readonly BASE_FG="1;37"
    readonly BASE_STR="\u"

    readonly CWD_BG_COLOR=45
    readonly CWD_BG_EXTRA=""
    readonly CWD_FG="1;37"

    readonly GIT_BG_COLOR=46
    readonly GIT_BG_EXTRA=""
    readonly GIT_FG="1;30"

    readonly PS_ZERO_BG_COLOR=42
    readonly PS_ERR_BG_COLOR=41
    readonly PS_ZERO_BG_EXTRA=""
    readonly PS_ERR_BG_EXTRA=""
    readonly PS_ZERO_FG="1;37"
    readonly PS_ERR_FG="1;37"

    readonly PS_DIVIDER=""
    
    readonly BASE_STYLE="1;37;44"
    readonly CWD_STYLE="1;37;45"
    readonly GIT_STYLE="30;46"
    readonly PS_STYLE_ZERO="1;37;42"
    readonly PS_STYLE_ERR="1;37;41"

    if [[ -z "$PS_SYMBOL" ]]; then
      case "$(uname)" in
          Darwin)   PS_SYMBOL='';;
          Linux)    PS_SYMBOL='λ';;
          *)        PS_SYMBOL='%';;
      esac
    fi

    # Takes the text, block_bg, block_fg, expandable boolean
    __block() {
	if [[ -n $1 ]]; then
	    if [[ -n "$__LAST_BG" ]]; then
		if [[ $POWERLINE_OVERLAP = 0 ]]; then
		    printf "%s" "$PS_DIVIDER"
		else
		    local __divider_fg=$((__LAST_BG - 10))
		    printf "\[\033[%s;%sm\]%s" "$__divider_fg" "$2" "$PS_DIVIDER"
		fi
	    fi
	    
	    printf "\[\033[%s;%sm\] %s \[\033[m\]" "$2" "$3" "$1"
	    return $2
	fi
    }

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
                marks="$SYMBOL_GIT_MODIFIED$marks"
                break
            fi
        done < <($git_eng status --porcelain --branch 2>/dev/null)  # note the space between the two <

        # print the git branch segment without a trailing newline
        printf "$ref$marks"
    }

    ps1() {

	unset __LAST_BG
	
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly. 
        if [ $? -eq 0 ]; then
            local style=("$PS_ZERO_BG_COLOR" "$PS_ZERO_FG")
        else
            local style=("$PS_ERR_BG_COLOR" "$PS_ERR_FG")
        fi

        local cwd="\w"
        # Bash by default expands the content of PS1 unless promptvars is disabled.
        # We must use another layer of reference to prevent expanding any user
        # provided strings, which would cause security issues.
        # POC: https://github.com/njhartwell/pw3nage
        # Related fix in git-bash: https://github.com/git/git/blob/9d77b0405ce6b471cb5ce3a904368fc25e55643d/contrib/completion/git-prompt.sh#L324
        if shopt -q promptvars; then
            __powerline_git_info="$(__git_info)"
            local git="\${__powerline_git_info}"
        else
            # promptvars is disabled. Avoid creating unnecessary env var.
            local git="$(__git_info)"
        fi
	
	PS1="$(__block $BASE_STR $BASE_BG_COLOR $BASE_FG)"
	__LAST_BG=$?
	PS1+="$(__block $cwd $CWD_BG_COLOR $CWD_FG)"
	__LAST_BG=$?
	PS1+="$(__block $git $GIT_BG_COLOR $GIT_FG)"
	__LAST_BG=$?
	PS1+="$(__block $PS_SYMBOL ${style[0]} ${style[1]}) "
    }

    PROMPT_COMMAND="ps1${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

__powerline
unset __powerline
