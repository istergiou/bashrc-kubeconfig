# kubeconfig

A bash script that provides a unified CLI for managing multiple `KUBECONFIG` files and contexts. Source it in your `.bashrc` or `.bash_profile` to get the `kubeconfig` command with tab completion.

## Installation

Option A. With bashrc-installer

```bash
# First install bashrc-installer with curl
curl -fsSL https://raw.githubusercontent.com/istergiou/bashrc-installer/main/install.sh | bash
# or wget
wget -qO- https://raw.githubusercontent.com/istergiou/bashrc-installer/main/install.sh | bash

# create ~/.bashrc.d and wire it into ~/.bashrc
bashrc-installer prepare          

# install kubeconfig
bashrc-installer install github.com/istergiou/bashrc-kubeconfig
```

Option B. Without bashrc-installer

```bash
source /path/to/kubeconfig.sh
```

## Usage

```bash
kubeconfig <command>
```

### Commands

| Command | Description |
|---|---|
| `kubeconfig set <name>` | Set `KUBECONFIG` to `~/.kube/config-<name>` |
| `kubeconfig set none` / `kubeconfig set default` | Unset `KUBECONFIG`, reverting to the default `~/.kube/config` |
| `kubeconfig print` | Print the current value of `KUBECONFIG` |
| `kubeconfig get contexts` | List all contexts in the current kubeconfig file |
| `kubeconfig export context <name>` | Export a named context from the current kubeconfig into its own file at `~/.kube/config-<name>` |
| `kubeconfig remove context <name>` | Delete a context from the current kubeconfig file |

## Convention

Config files are expected to follow the naming convention `~/.kube/config-<name>`. For example, `kubeconfig set prod` points `KUBECONFIG` at `~/.kube/config-prod`.

## Tab Completion

The script registers bash tab completion for all subcommands:

- `kubeconfig set <TAB>` completes from existing `~/.kube/config-*` files plus `none` and `default`
- `kubeconfig get <TAB>` completes to `contexts`
- `kubeconfig export context <TAB>` and `kubeconfig remove context <TAB>` complete from contexts in the active kubeconfig

## Notes

- `export context` refuses to overwrite an existing file.
- `remove context` warns if you delete the currently active context, since that leaves `kubectl` without a usable context until you run `kubectl config use-context <name>`.
- The script also exports a `KUBECTL_KUBECONFIG` variable tracking the last name passed to `kubeconfig set`, which can be used in shell prompts.
