# How add a blog post/note

Create `content/{name}.typ`:

```typ
#import "/lib.typ": template, folders

#let meta = (
    id: "{name}",
    folder: folders.blog,
    title: "name",
    // subtitle: "",
    lang: "en",
    // required if has translation
    translations: "ru", // or ("ru",)
    draft: false,
    created: datetime(day: 1, month: 1, year: 2021)
    toc: true,
)

#show: template.with(..meta)

/* write */
```

Optionally, create translation in `content/{name}.ru.typ`:

```typ
#import "/lib.typ": template, folders

#let meta = (
    id: "{name}",
    folder: folders.blog,
    title: "name",
    // subtitle: "",
    lang: "ru",
    translations: "en", // or ("en",)
    draft: false,
    created: datetime(day: 1, month: 1, year: 2021)
    toc: true,
)

#show: template.with(..meta)

/* write */
```

Add an entry to `posts` in `content/index.typ`
