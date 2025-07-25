#import "/lib.typ": template, folders

#let meta = (
    id: "local-nixpkgs-build",
    folder: folders.notes,
    title: [How to build a package in a local clone of #link("https://github.com/NixOS/nixpkgs")[nixpkgs]],
)

#show: template.with(..meta)

For example, if you need to update hashes manually, or test package in the shell

First, clone nixpkgs:

```sh
git clone https://github.com/NixOS/nixpkgs
```

Then, run from `nixpkgs` folder:

```sh
nix repl
# or, if some env variables is needed (e.g. NIXPKGS_ALLOW_INSECURE):
nix repl --impure
```

And then in the repl:

- Load nixpkgs: ```nix :l .```
- Reload nixpkgs after editing packages: ```nix :r```
- Build a package: ```nix :b pkgs.your-package```
- Build a package and open shell with it: ```nix :u pkgs.your-package```
