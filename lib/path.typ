#import "constants.typ": base, folder-paths

// Join paths with /
#let join-paths(parts) = {
    let res = parts.filter(p => p != "")
    if res.len() == 0 {
        return ""
    }
    res.join("/").replace(regex("//+"), "/")
}

// Absolute path
#let real-path(path) = {
    ("/" + join-paths((base, path))).replace(regex("//+"), "/")
}

// Absolute folder path
#let real-folder-path(folder) = {
    real-path(folder-paths.at(folder))
}
