#import "/lib/lib.typ": template, folders

#let meta = (
    folder: folders.notes,
    title: [Use your shell instead of Bash in ```sh nix develop```],
    tags: "nix",
)

#show: template.with(..meta)

```sh
nix develop --command bash -c "SHELL=$SHELL $SHELL"
```

This executes your shell, stored in ```sh $SHELL```, and also sets correct ```sh SHELL=$SHELL```, so it won't be equal to `bash`
