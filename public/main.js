const LIGHT = "light"
const DARK = "dark"
const STORAGE_KEY = "notes-theme"

function restore_theme() {
    let theme = localStorage.getItem(STORAGE_KEY)
    if (theme === LIGHT) {
        document.body.classList.add(LIGHT)
        document.body.classList.remove(DARK)
    }
}

function switch_theme() {
    let is_dark = document.body.classList.contains(DARK)
    let is_light = document.body.classList.contains(LIGHT)
    if (is_dark && is_light) {
        throw Error("wrong state: body has both light and dark classes")
    }
    // body initially doesn't have any classes
    if (is_dark || (!is_dark && !is_light)) {
        document.body.classList.add(LIGHT)
        document.body.classList.remove(DARK)
        localStorage.setItem(STORAGE_KEY, LIGHT)
    } else {
        document.body.classList.remove(LIGHT)
        document.body.classList.add(DARK)
        localStorage.setItem(STORAGE_KEY, DARK)
    }
}

function set_heading(id) {
    window.location.hash = id
}
