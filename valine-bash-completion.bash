# This file is part of valine, providing intelligent valine tab-completion for BASH
# Save it to: /etc/bash_completion.d/
#
# Revision date: 2016/02/03 matching up with valine v0.6.2
# 
# Copyright 2014, 2016 Ryan Sawhill Aroha <rsaw@redhat.com>
# 
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#    General Public License <gnu.org/licenses/gpl.html> for more details.
#
#-------------------------------------------------------------------------------

# NOTE: For a non-root user to use valine and valine tab-completion they must be
#       a member of the 'libvirt' system group.

if groups | grep -qs '\<libvirt\>' && [[ -z $LIBVIRT_DEFAULT_URI ]]; then
    # If member of libvirt group and no LIBVIRT_DEFAULT_URI already set:
    export LIBVIRT_DEFAULT_URI=qemu:///system
fi

__v_VIRSH() {
    virsh "${@}" 2>/dev/null
}

__v_get_domains() {
    __v_VIRSH list --all --name
}

__v_list_snapshots() {
    local cfgFile=/etc/valine/${1}
    if [[ -e ${cfgFile} ]]; then
        [[ -r ${cfgFile} ]] || return
        local desiredColumn=$(awk '/^# Columns:/ {print $3}' ${cfgFile} | awk -F❚ '{i = 1; while ($i != "LV") { i++ }; print i}')
        [[ ${desiredColumn} =~ [0-9]+ ]] || return
        awk -F❚ -v desiredColumn=${desiredColumn}  '(NF == 0 || $1 ~ /^\s*($|#)/) {next}; {print $desiredColumn}' ${cfgFile}
    else
        __v_VIRSH snapshot-list ${1} --name
    fi
}

_valine()  {
  
    # Variables
    local curr prev prevX2 virtDomains
    
    # Wipe out COMPREPLY array
    COMPREPLY=()
  
    # Set cur & prev appropriately
    curr=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    prevX2=${COMP_WORDS[COMP_CWORD-2]}
    
    # Check previous arg to see if we need to do anything special
    case "${prev}" in
        valine)
            COMPREPLY=( $(compgen -W "-a --all $(__v_get_domains)" -- "${curr}") )
            ;;
        --help|-h|--size|start|s|shutdown|h|destroy|d|console|c|NUKE|K)
            ;;
        --off)
            if [[ ${prevX2} =~ ^n(ew-snap)?$ || ${COMP_WORDS[COMP_CWORD-3]} =~ ^n(ew-snap)?$ ]]; then
                COMPREPLY=( $(compgen -W "--size" -- "${curr}") )
            fi
            ;;
        new-snap|n)
            COMPREPLY=( $(compgen -W "--off --size" -- "${curr}") )
            ;;
        revert-snap|r)
            case "${prevX2}" in
                --all|-a)
                    COMPREPLY=( $(compgen -W "--off" -- "${curr}") )  ;;
                *)
                    if __v_get_domains | grep -qs -- "^${prevX2}$"; then
                        COMPREPLY=( $(compgen -W "--off $(__v_list_snapshots ${prevX2})" -- "${curr}" ) )
                    fi
            esac
            ;;
        Delete-snap|D)
            case "${prevX2}" in
                --all|-a)
                    : ;;
                *)
                    if __v_get_domains | grep -qs -- "^${prevX2}$"; then
                        COMPREPLY=( $(compgen -W "$(__v_list_snapshots ${prevX2})" -- "${curr}" ) )
                    fi
            esac
            ;;
        --all|-a)
            COMPREPLY=( $(compgen -W "new-snap revert-snap start shutdown destroy" -- "${curr}") )
            ;;
        *)
            if [[ ${prevX2} == --size || ${prevX2} =~ ^r(evert-snap)?$ ]]; then
                COMPREPLY=( $(compgen -W "--off" -- "${curr}") )
            elif [[ ${prevX2} =~ ^n(ew-snap)?$ ]]; then
                COMPREPLY=( $(compgen -W "--off --size" -- "${curr}") )
            elif __v_get_domains | grep -qs -- "^${prev}$"; then
                COMPREPLY=( $(compgen -W "new-snap revert-snap Delete-snap start shutdown destroy console NUKE" -- "${curr}") )
            fi
    esac
    return 0

}

# Add the names of any valine aliases (or alternate file-names) to the end of the following line
complete -F _valine v valine
