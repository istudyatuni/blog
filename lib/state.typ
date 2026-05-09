// state with name of current file without .typ/.ru.typ, beeing set with doc-name-wrap in main.typ
#let doc-name = state("__doc_name", none)

#let doc-name-wrap(name, body) = [
    #doc-name.update(_ => name)
    #body
    #doc-name.update(_ => none)
]
