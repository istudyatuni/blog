const LIGHT = "light"
const DARK = "dark"
const STORAGE_KEY = "blog-theme"

const TAG_SELECTED_CLASS = "tag-selected"
const DATA_TAG_FILTER = "data-tag-filter"

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

/** @param {HTMLSpanElement} e */
function set_tag_filter(e) {
    let filtered_tag = document.body.getAttribute(DATA_TAG_FILTER)
    let filter_active = filtered_tag != null
    let tag = e.getAttribute("data-tag")

    if (filter_active && tag == filtered_tag) {
        document.body.removeAttribute(DATA_TAG_FILTER)
    } else {
        document.body.setAttribute(DATA_TAG_FILTER, tag)
    }
}
