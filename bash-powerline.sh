#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

__powerline() {
    # Colorscheme
    readonly RESET='\[\033[m\]'
    readonly COLOR_CWD='\[\033[0;34m\]' # blue
    readonly COLOR_GIT='\[\033[0;36m\]' # cyan
    readonly COLOR_SUCCESS='\[\033[0;32m\]' # green
    readonly COLOR_FAILURE='\[\033[0;31m\]' # red

    readonly SYMBOL_GIT_BRANCH='⑂'
    readonly SYMBOL_GIT_MODIFIED='*'
    readonly SYMBOL_GIT_PUSH='↑'
    readonly SYMBOL_GIT_PULL='↓'

    readonly BASE_STYLE="37;44"
    readonly BASE_STR="\u"
    readonly CWD_STYLE="37;45"
    readonly GIT_STYLE="30;46"
    readonly PS_STYLE_ZERO="37;42"
    readonly PS_STYLE_ERR="37;41"

    if [[ -z "$PS_SYMBOL" ]]; then
      case "$(uname)" in
          Darwin)   PS_SYMBOL='';;
          Linux)    PS_SYMBOL='λ';;
          *)        PS_SYMBOL='%';;
      esac
    fi

    # Takes the text and style
    __block() {
	if [[ -n $1 ]]; then
	    printf "\[\033[%sm\] %s %s" "$2" "$1" "$RESET"
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
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly. 
        if [ $? -eq 0 ]; then
            local symbol="$(__block $PS_SYMBOL $PS_STYLE_ZERO)"
        else
            local symbol="$(__block $PS_SYMBOL $PS_STYLE_ERR)"
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

	PS1="$(__block $BASE_STR $BASE_STYLE)"
	PS1+="$(__block $cwd $CWD_STYLE)"
	PS1+="$(__block $git $GIT_STYLE)$symbol "
    }

    PROMPT_COMMAND="ps1${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

__powerline
unset __powerline
