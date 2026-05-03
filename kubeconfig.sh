#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# kubeconfig — unified CLI for managing KUBECONFIG files and contexts
#
# Usage:
#   kubeconfig set <name>              Set KUBECONFIG to ~/.kube/config-<name>
#   kubeconfig print                   Print current KUBECONFIG
#   kubeconfig get contexts            List contexts in current KUBECONFIG
#   kubeconfig export context <name>   Export context to ~/.kube/config-<name>
#   kubeconfig remove context <name>   Remove context from current KUBECONFIG
# ---------------------------------------------------------------------------

# -- helpers ----------------------------------------------------------------

_kubeconfig_configs() {
  find "$HOME/.kube/" -maxdepth 1 -name 'config-*' -exec basename {} \; \
    | sed 's/config-//g'
}

_kubeconfig_contexts() {
  kubectl config get-contexts --no-headers -o name 2>/dev/null
}

_kubeconfig_usage() {
  cat <<'EOF'
Usage: kubeconfig <command>
  set <name>              Set KUBECONFIG to ~/.kube/config-<name>
  print                   Print current KUBECONFIG
  get contexts            List contexts in current KUBECONFIG
  export context <name>   Export context to ~/.kube/config-<name>
  remove context <name>   Remove context from current KUBECONFIG
EOF
}

# -- subcommands ------------------------------------------------------------

_kubeconfig_set() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: kubeconfig set <name>"; return 1
  fi
  export KUBECTL_KUBECONFIG="$name"
  if [[ "$name" == "none" || "$name" == "default" ]]; then
    unset KUBECONFIG; return 0
  fi
  if [[ ! -f "$HOME/.kube/config-${name}" ]]; then
    echo "Error: kubeconfig not found: ~/.kube/config-${name}"; return 1
  fi
  export KUBECONFIG="$HOME/.kube/config-${name}"
  echo "setting kubeconfig to ${name}"
}

_kubeconfig_print() {
  echo "KUBECONFIG=${KUBECONFIG}"
}

_kubeconfig_get_contexts() {
  _kubeconfig_contexts
}

_kubeconfig_export_context() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: kubeconfig export context <name>"; return 1
  fi
  local dest="$HOME/.kube/config-${name}"
  if [[ -f "$dest" ]]; then
    echo "Error: file already exists: $dest"; return 1
  fi
  kubectl config view --minify --raw --context="$name" > "$dest"
  echo "Exported context ${name} to ${dest}"
}

_kubeconfig_remove_context() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: kubeconfig remove context <name>"; return 1
  fi
  if [[ -z "$KUBECONFIG" ]]; then
    echo "Error: KUBECONFIG is not set"; return 1
  fi
  local current
  current=$(kubectl config current-context 2>/dev/null)
  kubectl config delete-context "$name"
  if [[ "$name" == "$current" ]]; then
    echo "Warning: you removed the current-context. Set a new one with:"
    echo "  kubectl config use-context <context-name>"
  fi
}

# -- dispatch ---------------------------------------------------------------

function kubeconfig() {
  local cmd="$1"; shift
  case "$cmd" in
    set)            _kubeconfig_set "$@" ;;
    print)          _kubeconfig_print ;;
    get)
      [[ "$1" == "contexts" ]] && { _kubeconfig_get_contexts; return; }
      echo "Usage: kubeconfig get contexts"; return 1 ;;
    export)
      [[ "$1" == "context" ]] && { shift; _kubeconfig_export_context "$@"; return; }
      echo "Usage: kubeconfig export context <name>"; return 1 ;;
    remove)
      [[ "$1" == "context" ]] && { shift; _kubeconfig_remove_context "$@"; return; }
      echo "Usage: kubeconfig remove context <name>"; return 1 ;;
    *)              _kubeconfig_usage; return 1 ;;
  esac
}
export -f kubeconfig

# -- tab completion ---------------------------------------------------------

_kubeconfig_completions() {
  local cur prev words cword
  _get_comp_words_by_ref -n : cur prev words cword

  case $cword in
    1) COMPREPLY=($(compgen -W "set print get export remove" -- "$cur")) ;;
    2)
      case "${words[1]}" in
        set)    COMPREPLY=($(compgen -W "none default $(_kubeconfig_configs)" -- "$cur")) ;;
        get)    COMPREPLY=($(compgen -W "contexts" -- "$cur")) ;;
        export) COMPREPLY=($(compgen -W "context" -- "$cur")) ;;
        remove) COMPREPLY=($(compgen -W "context" -- "$cur")) ;;
      esac ;;
    3)
      if [[ "${words[2]}" == "context" ]]; then
        COMPREPLY=($(compgen -W "$(_kubeconfig_contexts)" -- "$cur"))
      fi ;;
  esac
}

complete -F _kubeconfig_completions kubeconfig
