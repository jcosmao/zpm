#!/usr/bin/env zsh

# ----------
# ZPM Plugin
# ----------

function _ZPM-load-plugin() {
  local Plugin_path
  local Plugin_basename
  
  Plugin_path=$(_ZPM-get-plugin-path "$1")
  Plugin_basename=$(_ZPM-get-plugin-basename "$1")
  
  local _ZPM_local_source=true
  local _ZPM_local_async=false
  local _ZPM_local_inline=false
  local _ZPM_local_path=true
  local _ZPM_local_fpath=true
  
  if [[ "$1"  == *",apply:"* ]]; then
    local _ZPM_tag_str=${1##*,apply:}
    _ZPM_tag_str=${_ZPM_tag_str%%\,*}
    
    if [[ "$_ZPM_tag_str" != *'source'* ]]; then
      _ZPM_local_source=false
    fi
    
    if [[ "$_ZPM_tag_str" != *'path'* ]]; then
      _ZPM_local_path=false
    fi
    
    if [[ "$_ZPM_tag_str" != *'fpath'* ]]; then
      _ZPM_local_fpath=false
    fi
  fi
  
  if [[ "$1"  == *",async"* ]]; then
    _ZPM_local_async=true
  fi
  
  if [[ "$1"  == *",inline"* ]]; then
    _ZPM_local_inline=true
  fi
  
  if [[ "$_ZPM_local_fpath"  == "true" ]]; then
    if [[ "$1"  == *",fpath:"* ]]; then
      local zpm_fpath=${${1##*,fpath:}%%,*}
      local _ZPM_path="${Plugin_path}/${zpm_fpath}"
      _ZPM-log zpm:init:fpath "Add to FPATH ${Plugin_basename:A}/${zpm_fpath}"
      fpath=( $fpath "${_ZPM_path:A}") 
    elif [[ -n "${Plugin_path:A}/_"*(#qN)  ]]; then
      local _ZPM_path="${Plugin_path}"
      _ZPM-log zpm:init:fpath "Add to FPATH ${Plugin_basename:A}"
      fpath=( $fpath "${_ZPM_path:A}")  
    fi
  fi
  
  if [[ "$_ZPM_local_path"  == "true" ]]; then
    if [[ "$1"  == *",path:"* ]]; then
      local zpm_path=${${1##*,path:}%%,*}
      local _ZPM_path="${Plugin_path}/${zpm_path}"
      _ZPM-log zpm:init:path "Add to PATH ${Plugin_basename}/${zpm_path}"
      export path=("${_ZPM_path:A}" $path) 
    elif [[ -d ${Plugin_path:A}/bin ]]; then
      local _ZPM_path="${Plugin_path}/bin"
      _ZPM-log zpm:init:path "Add to PATH ${Plugin_basename}/bin"
      export path=("${_ZPM_path:A}" $path) 
    fi
  fi
  
  if [[ "$_ZPM_local_source"  == "true" ]]; then
    if [[ "$1"  == *",source:"* ]]; then
      _ZPM_plugin_file_path=$(
        _ZPM-get-plugin-file-path "${Plugin_path}" "${Plugin_basename}" "${${1##*,source:}%%,*}"
      )
    else
      _ZPM_plugin_file_path=$(
        _ZPM-get-plugin-file-path "${Plugin_path}" "${Plugin_basename}"
      )
    fi
    
    if [[ ! -z "$_ZPM_plugin_file_path" ]]; then
      if [[ "$_ZPM_local_inline" == "true" ]]; then
        if [[ "$_ZPM_local_async" == "true" ]]; then
          _ZPM-log zpm:init:source "Source ${Plugin_basename}"
          _ZPM_inline_async_source "${_ZPM_plugin_file_path}"
        else
          _ZPM-log zpm:init:source "Source ${Plugin_basename}"
          _ZPM_inline_source "${_ZPM_plugin_file_path}"
        fi
      else
        if [[ "$_ZPM_local_async" == "true" ]]; then
          _ZPM-log zpm:init:source "Source ${Plugin_basename}"
          _ZPM_async_source "${_ZPM_plugin_file_path}"
        else
          _ZPM-log zpm:init:source "Source ${Plugin_basename}"
          _ZPM_source "${_ZPM_plugin_file_path}"
        fi
      fi
    fi
  fi
  
}

function _ZPM-initialize-plugin() {
  # Check if plugin isn't loaded
  declare -a _Plugins_Install
  
  for plugin ("$@"); do
    local Plugin_path=$(_ZPM-get-plugin-path "$plugin")
    
    if [[ ! -e $Plugin_path ]]; then
      _Plugins_Install+=("$plugin")
    fi
  done
  
  if [[ -n "$_Plugins_Install[@]" ]]; then;
    printf '%s\0' "${_Plugins_Install[@]}" | \
    xargs -0 -P0 -n1 "${_ZPM_DIR}/bin/_ZPM-plugin-helper" install
  fi
  
  for plugin ($_Plugins_Install); do
    if [[ "$plugin" == *",hook:"* ]]; then
      ${_ZPM_DIR}/bin/_ZPM-post-install-helper "$plugin"
    fi
  done
  
  for plugin ($@); do
    if [[ " ${_ZPM_Plugins[*]} " != *"$plugin"* ]]; then
      _ZPM-log zpm:init "Initialize $plugin"
      _ZPM_Plugins+=("$plugin")
      _ZPM-load-plugin "$plugin"
    else
      _ZPM-log zpm:init:skip "Skip initialization $1"
    fi
  done
}
