local M = {}

local function edges(c)
    local gap = c.gap
    return {
        gap = gap, spacing = gap * 2,
        left = gap, top = gap,
        right = 1 - gap / 1.5, bottom = 1 - gap * 1.5,
    }
end

local function slotFraction(c, name)
    local e, split, side, top = edges(c), c.split, c.sideHeight, c.topShare
    local rects = {
        main      = { e.left, e.top, split - e.spacing, e.bottom - e.top },
        side      = { split, e.top, e.right - split, side - e.gap },
        corner    = { split, side + e.spacing, e.right - split, 1 - side - e.spacing },
        video     = { split, side + e.spacing, e.right - split, 1 - side - e.spacing * 2 },
        full      = { e.left, e.top, e.right - e.left, e.bottom - e.top },
        halfLeft  = { e.left, e.top, 0.5 - e.spacing, e.bottom - e.top },
        halfRight = { 0.5, e.top, e.right - 0.5, e.bottom - e.top },
        top60     = { e.left, e.top, e.right - e.left, top - e.spacing },
        bottom40  = { e.left, top, e.right - e.left, e.bottom - top },
        column    = { split, e.top, e.right - split, e.bottom - e.top },
    }
    local r = assert(rects[name], "PowerWindows: unknown rect " .. tostring(name))
    return { x = r[1], y = r[2], w = r[3], h = r[4] }
end

function M.rect(c, name, sf)
    local f = slotFraction(c, name)
    return { x = sf.x + sf.w * f.x, y = sf.y + sf.h * f.y, w = sf.w * f.w, h = sf.h * f.h }
end

function M.anchor(box, w, h, anchor)
    if anchor == "center" then
        return { x = box.x + (box.w - w) / 2, y = box.y + (box.h - h) / 2, w = w, h = h }
    elseif anchor == "top" then
        return { x = box.x + (box.w - w) / 2, y = box.y, w = w, h = h }
    end
    return { x = box.x, y = box.y, w = w, h = h }
end

function M.fit(box, aspect, anchor)
    local w, h = box.w, box.w * aspect
    if h > box.h then
        h = box.h
        w = h / aspect
    end
    return M.anchor(box, w, h, anchor)
end

-- Sized off the screen, not a slot: the column is too narrow for a readable phone.
function M.deviceSize(c, sf, aspect)
    local w = sf.w * c.device.width
    local h = w * aspect
    if h > sf.h * c.device.maxHeight then
        h = sf.h * c.device.maxHeight
        w = h / aspect
    end
    return w, h
end

function M.stackCells(c, sf, n)
    local column = M.rect(c, "column", sf)
    local between = sf.h * c.gap * 2
    local h = (column.h - between * (n - 1)) / n
    local cells = {}
    for i = 1, n do
        cells[i] = { x = column.x, y = column.y + (i - 1) * (h + between), w = column.w, h = h }
    end
    return cells
end

function M.smallDialog(c, sf, current)
    local e = edges(c)
    local w = math.min(current.w, sf.w * (e.right - c.split) * c.dialog.width)
    local h = math.min(current.h, sf.h * c.sideHeight * c.dialog.height)
    return { x = sf.x + sf.w - w - c.gap * sf.w, y = sf.y + e.top * sf.h, w = w, h = h }
end

function M.near(a, b, tol)
    return math.abs(a.x - b.x) <= tol and math.abs(a.y - b.y) <= tol
        and math.abs(a.w - b.w) <= tol and math.abs(a.h - b.h) <= tol
end

return M
