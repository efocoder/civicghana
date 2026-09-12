const KEY = "civicroute.saved.v1"

function read() {
  try {
    const raw = window.localStorage.getItem(KEY)
    const parsed = raw ? JSON.parse(raw) : []
    return Array.isArray(parsed) ? parsed : []
  } catch (_) {
    return []
  }
}

function write(items) {
  try {
    window.localStorage.setItem(KEY, JSON.stringify(items))
    return true
  } catch (_) {
    return false
  }
}

export const SavedItemsStore = {
  list() { return read() },
  save(item) {
    const items = read()
    const now = new Date().toISOString()
    const index = items.findIndex((saved) => saved.type === item.type && saved.public_id === item.public_id)
    const next = { ...item, saved_at: index >= 0 ? items[index].saved_at : now, last_visited_at: now }
    if (index >= 0) items[index] = next
    else items.push(next)
    return write(items)
  },
  remove(type, publicId) { return write(read().filter((item) => !(item.type === type && item.public_id === publicId))) },
  exists(type, publicId) { return read().some((item) => item.type === type && item.public_id === publicId) },
  clear() { return write([]) },
  count() { return read().length },
  touch(type, publicId) {
    const items = read()
    const item = items.find((saved) => saved.type === type && saved.public_id === publicId)
    if (!item) return false
    item.last_visited_at = new Date().toISOString()
    return write(items)
  }
}
