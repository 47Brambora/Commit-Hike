-- Commit Hike for Neovim: your commits walk a hiking trail.
--
-- A thin wrapper around the `commit-hike` program (the same core the IDE
-- plugins use): the status line text comes from `commit-hike prompt`, the
-- commands call the core's JSON commands. Nothing here blocks the editor.
local M = {}

local uv = vim.uv or vim.loop

M.config = {
  bin = "commit-hike", -- the core; install: curl -fsSL https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/scripts/install.sh | sh
  icon = "🥾", -- before the distance in the status line; "" for none
  lang = nil, -- nil: the language set in Commit Hike, else the editor's
  interval = 60, -- seconds between background refreshes; 0 turns them off
  watch_head = true, -- refresh right after a commit (watches .git/logs/HEAD)
}

local state = {
  text = "", -- what statusline() returns
  root = nil, -- git work tree of the current folder
  watcher = nil,
  watched = nil,
  timer = nil,
  running = false,
  again = false, -- a refresh was asked for while one was running
}

-- ---------------------------------------------------------------- texts
-- Labels of :CommitHike status. Route texts come translated from the core.
-- i18n.lua is generated from i18n/<lang>.json (task i18n).
local I18N = require("commit-hike.i18n")
local TEXTS, LANG_NAMES = {}, {}
for code, l in pairs(I18N.languages) do
  TEXTS[code] = l.texts
  LANG_NAMES[code] = l.meta.name
end

--- The editor's language as a two-letter code ("uk" from "uk_UA.UTF-8").
local function editor_lang()
  if M.config.lang then
    return M.config.lang
  end
  for _, v in ipairs({ vim.env.LC_ALL, vim.env.LC_MESSAGES, vim.env.LANG, vim.v.lang }) do
    local code = v and v:match("^(%a%a%a?)[_%-%.@]?") or nil
    if code and code ~= "C" then
      return code:lower()
    end
  end
  return "en"
end

local function texts(locale)
  local base = (locale or editor_lang()):match("^(%a+)") or "en"
  return TEXTS[base] or TEXTS.en, base
end

--- Distances as the panel writes them: 640 m · 16,0 км · 2863 km.
function M.distance(m, locale)
  local base = (locale or "en"):match("^(%a+)") or "en"
  local meta = (I18N.languages[base] or I18N.languages.en).meta
  local unit_m, unit_km = meta.m, meta.km
  m = math.max(0, m or 0)
  if m < 1000 then
    return string.format("%d %s", math.floor(m + 0.5), unit_m)
  end
  local km = m / 1000
  if km >= 100 then
    return string.format("%d %s", math.floor(km + 0.5), unit_km)
  end
  local s = string.format("%.1f", km):gsub("%.", meta.decimal)
  return s .. " " .. unit_km
end

-- ---------------------------------------------------------------- the core
--- Runs the core. cb(ok, data_or_message) gets the decoded envelope's data.
local function core(args, cb)
  local cmd = { M.config.bin }
  vim.list_extend(cmd, args)
  local ok, err = pcall(vim.system, cmd, { text = true }, function(res)
    vim.schedule(function()
      local parsed, decoded = pcall(vim.json.decode, res.stdout or "")
      if not parsed or type(decoded) ~= "table" then
        cb(false, (res.stderr ~= "" and res.stderr) or ("exit " .. tostring(res.code)))
      elseif decoded.ok then
        cb(true, decoded.data)
      else
        cb(false, decoded.error and (decoded.error.code .. ": " .. decoded.error.message) or "error", decoded.error)
      end
    end)
  end)
  if not ok then -- the binary isn't installed
    vim.schedule(function()
      cb(false, texts().missing .. " (" .. tostring(err) .. ")", { code = "missing" })
    end)
  end
end
M._core = core

local function repo_root(dir)
  local found = vim.fs.find(".git", { path = dir, upward = true })[1]
  return found and vim.fs.dirname(found) or nil
end

-- ---------------------------------------------------------------- status line
local function redraw()
  pcall(vim.cmd.redrawstatus)
end

--- Asks the core for the line; counts new commits first when HEAD moved.
--- opts.wait = true runs synchronously (for tests and :CommitHike scan).
function M.refresh(opts)
  opts = opts or {}
  if state.running and not opts.wait then
    state.again = true
    return
  end
  local dir = vim.fn.getcwd()
  state.root = repo_root(dir)
  M._watch(state.root)
  local cmd = { M.config.bin, "prompt", "--scan", "--repo", dir, "--icon", M.config.icon }
  if M.config.lang then
    vim.list_extend(cmd, { "--lang", M.config.lang })
  end
  state.running = true
  local function done(res)
    state.running = false
    local line = (res.code == 0 and res.stdout or ""):gsub("%s+$", "")
    if line ~= state.text then
      state.text = line
      vim.schedule(redraw)
    end
    if state.again then
      state.again = false
      vim.schedule(M.refresh)
    end
  end
  local ok, job = pcall(vim.system, cmd, { text = true }, (not opts.wait) and done or nil)
  if not ok then
    state.running = false
    state.text = ""
    return
  end
  if opts.wait then
    done(job:wait())
  end
end

--- The text for a status line, e.g. "🥾 16,0 км · Озеро Несамовите". Never blocks.
function M.statusline()
  return state.text
end

-- Watch .git/logs/HEAD: every commit, checkout or rebase appends to it, from
-- any tool. One watcher for the current work tree.
function M._watch(root)
  if not M.config.watch_head or root == state.watched then
    return
  end
  if state.watcher then
    state.watcher:stop()
    state.watcher = nil
  end
  state.watched = nil -- set only once a watcher runs: a new repository has no logs/ until its first commit
  local gitdir = root and (root .. "/.git") or nil
  if gitdir and vim.fn.isdirectory(gitdir) == 0 then
    -- a worktree or submodule: .git is a file "gitdir: <path>"
    local f = io.open(gitdir, "r")
    local line = f and f:read("*l") or ""
    if f then
      f:close()
    end
    gitdir = line:match("^gitdir:%s*(.+)$")
  end
  local logs = gitdir and (gitdir .. "/logs") or nil
  if not logs or vim.fn.isdirectory(logs) == 0 then
    return
  end
  local w = uv.new_fs_event()
  if not w then
    return
  end
  local pending = false
  w:start(logs, {}, function(_, fname)
    if fname ~= "HEAD" or pending then
      return
    end
    pending = true -- git writes several times per commit: one refresh
    vim.defer_fn(function()
      pending = false
      M.refresh()
    end, 700)
  end)
  state.watcher = w
  state.watched = root
end

-- ---------------------------------------------------------------- commands
local function float(lines)
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded", title = " 🥾 Commit Hike ", title_pos = "center",
    width = width + 2, height = #lines,
    row = math.floor((vim.o.lines - #lines) / 2) - 1, col = math.floor((vim.o.columns - width) / 2),
  })
  for _, key in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
  return buf, win
end

--- The lines of :CommitHike status for a status answer of the core.
function M.status_lines(st)
  local T = texts(st.locale)
  local j = st.project or st.global
  if not j then
    return { T.noJourney }
  end
  local d = function(m)
    return M.distance(m, st.locale)
  end
  local lines = { " " .. j.route.name, "" }
  local pct = string.format("%.1f%%", j.percent or 0)
  if st.locale and st.locale:match("^%a+") ~= "en" then
    pct = pct:gsub("%.", ",")
  end
  table.insert(lines, string.format(" %s: %s / %s (%s)", T.walked, d(j.distance_m), d(j.route.length_m), pct))
  if j.finished then
    table.insert(lines, " " .. T.finished .. " ✓")
  else
    if j.last_waypoint then
      table.insert(lines, string.format(" %s: %s", T.place, j.last_waypoint.name))
    end
    if j.next_waypoint then
      table.insert(lines, string.format(" %s: %s · %s", T.next, j.next_waypoint.name, d(j.to_next_m or 0)))
    end
  end
  if j.elevation_m then
    local unit = (st.locale or ""):match("^uk") and "м" or "m"
    table.insert(lines, string.format(" %s: %d %s", T.altitude, math.floor(j.elevation_m + 0.5), unit))
  end
  table.insert(lines, string.format(" %s: %s · %s: " .. T.days, T.today, d(st.today_m or 0), T.streak, j.streak_days or 0))
  return lines
end

local function report(msg, err)
  local T = texts()
  if err and err.code == "not_initialized" then
    msg = T.notSetUp
  end
  vim.notify(msg, vim.log.levels.WARN, { title = "Commit Hike" })
end

local function lang_args()
  return M.config.lang and { "--lang", M.config.lang } or { "--lang", editor_lang() }
end

local commands = {}

function commands.status()
  local args = { "status", "--repo", vim.fn.getcwd() }
  vim.list_extend(args, lang_args())
  core(args, function(ok, data, err)
    if not ok then
      return report(data, err)
    end
    float(M.status_lines(data))
  end)
end

function commands.scan()
  local root = repo_root(vim.fn.getcwd())
  if not root then
    return report(texts().noJourney)
  end
  local args = { "scan", "--repo", root }
  vim.list_extend(args, lang_args())
  core(args, function(ok, data, err)
    if not ok then
      return report(data, err)
    end
    vim.notify(string.format(texts(data.locale).scanned, data.new_commits or 0), vim.log.levels.INFO, { title = "Commit Hike" })
    M.refresh()
  end)
end

function commands.init()
  local email = vim.trim(vim.fn.system({ "git", "config", "--global", "user.email" }))
  vim.ui.input({ prompt = "E-mail: ", default = email }, function(input)
    if not input or input == "" then
      return
    end
    core({ "init", "--email", input }, function(ok, data, err)
      if not ok then
        return report(data, err)
      end
      vim.notify(string.format(texts().initDone, input), vim.log.levels.INFO, { title = "Commit Hike" })
      M.refresh()
    end)
  end)
end

-- Starts walking a route: asks whether to count the commits already made.
local function walk(route_id)
  local T = texts()
  vim.ui.select({ true, false }, {
    prompt = T.history,
    format_item = function(v)
      return v and T.yes or T.no
    end,
  }, function(history)
    if history == nil then
      return
    end
    core({ "journey", "--scope", "global", "--route", route_id, "--from-history=" .. tostring(history) }, function(ok, data, err)
      if not ok then
        return report(data, err)
      end
      M.refresh()
      commands.status()
    end)
  end)
end

function commands.route(id)
  if id and id ~= "" then
    return walk(id)
  end
  local args = { "routes" }
  vim.list_extend(args, lang_args())
  core(args, function(ok, routes, err)
    if not ok then
      return report(routes, err)
    end
    vim.ui.select(routes, {
      prompt = texts().pickRoute,
      format_item = function(r)
        return string.format("%s · %s", r.name, M.distance(r.length_m, editor_lang()))
      end,
    }, function(r)
      if r then
        walk(r.id)
      end
    end)
  end)
end

function commands.difficulty(level)
  local function set(l)
    core({ "difficulty", "--set", l }, function(ok, data, err)
      if not ok then
        return report(data, err)
      end
      M.refresh()
    end)
  end
  if level and level ~= "" then
    return set(level)
  end
  local _, base = texts()
  vim.ui.select({ "easy", "medium", "hard" }, {
    prompt = texts().pickDifficulty,
    format_item = function(l)
      return (TEXTS[base] or TEXTS.en)["level_" .. l]
    end,
  }, function(l)
    if l then
      set(l)
    end
  end)
end

-- Whether commits made before 1.2 count by their size too (the core's `scoring`).
function commands.scoring(history)
  local function set(h)
    local args = { "scoring", "--history", h }
    local root = repo_root(vim.fn.getcwd())
    if root then -- re-read from git, so this repository's older commits count their exact lines
      vim.list_extend(args, { "--repo", root })
    end
    core(args, function(ok, data, err)
      if not ok then
        return report(data, err)
      end
      local T = texts()
      vim.notify(string.format(T.scoringDone, M.distance(data.previous_m, editor_lang()), M.distance(data.total_m, editor_lang())),
        vim.log.levels.INFO, { title = "Commit Hike" })
      M.refresh()
    end)
  end
  if history and history ~= "" then
    return set(history)
  end
  core({ "scoring" }, function(ok, data, err)
    if not ok then
      return report(data, err)
    end
    local T = texts()
    if not data.upgraded_at or data.upgraded_at == 0 then
      return vim.notify(T.scoringAlways, vim.log.levels.INFO, { title = "Commit Hike" })
    end
    vim.ui.select({ "on", "off" }, {
      prompt = T.pickScoring,
      format_item = function(h)
        local current = (h == "on") == data.history and " ✓" or ""
        return (h == "on" and T.scoringOn or T.scoringOff) .. current
      end,
    }, function(h)
      if h and (h == "on") ~= data.history then
        set(h)
      end
    end)
  end)
end

function commands.lang(code)
  local function set(c)
    core({ "locale", "--set", c }, function(ok, data, err)
      if not ok then
        return report(data, err)
      end
      M.refresh()
    end)
  end
  if code and code ~= "" then
    return set(code)
  end
  vim.ui.select(vim.list_extend({ "auto" }, I18N.order), {
    prompt = texts().pickLang,
    format_item = function(c)
      return c == "auto" and texts().auto or LANG_NAMES[c]
    end,
  }, function(c)
    if c then
      set(c)
    end
  end)
end

-- ---------------------------------------------------------------- routes from the site
-- The core talks to the routes website (commit-hike.dev) only for these
-- two commands: public data, nothing about the user is sent.

local function site_failed(data, err)
  if err and err.code == "site_unreachable" then
    return report(texts().siteOffline)
  end
  report(data, err)
end

-- Installs (or updates) a route from the site, then offers to walk it.
function commands.install(id, replace_local)
  if not id or id == "" then
    return commands.find()
  end
  local args = { "site", "install", "--id", id }
  if replace_local then
    table.insert(args, "--replace-local")
  end
  vim.list_extend(args, lang_args())
  core(args, function(ok, data, err)
    local T = texts()
    if not ok then
      -- the user's own route with this id: ask before replacing it
      if err and err.code == "route_exists" and not replace_local and not (err.message or ""):match("built%-in") then
        return vim.ui.select({ true, false }, {
          prompt = string.format(T.siteReplace, id),
          format_item = function(v)
            return v and T.yes:gsub(",.*", "") or T.later
          end,
        }, function(yes)
          if yes then
            commands.install(id, true)
          end
        end)
      end
      return site_failed(data, err)
    end
    vim.notify(string.format(T.siteInstalled, data.route.name, data.version), vim.log.levels.INFO, { title = "Commit Hike" })
    vim.ui.select({ true, false }, {
      prompt = T.walkNow,
      format_item = function(v)
        return v and data.route.name or T.later
      end,
    }, function(go)
      if go then
        walk(id)
      end
    end)
  end)
end

-- Searches the site's catalogue; picking a route installs (or updates) it.
function commands.find(text)
  local args = { "site", "routes" }
  if text and text ~= "" then
    vim.list_extend(args, { "--q", text })
  end
  vim.list_extend(args, lang_args())
  core(args, function(ok, page, err)
    if not ok then
      return site_failed(page, err)
    end
    local T = texts()
    if #page.routes == 0 then
      return vim.notify(T.siteNone, vim.log.levels.INFO, { title = "Commit Hike" })
    end
    local marks = { site = T.markInstalled, builtin = T.markBuiltin, ["local"] = T.markLocal }
    vim.ui.select(page.routes, {
      prompt = T.siteFind,
      format_item = function(r)
        local mark = r.update and ("↑ " .. T.markUpdate) or (r.installed and ("✓ " .. marks[r.installed]) or nil)
        local parts = { r.title, M.distance(r.length_m, editor_lang()), string.format(T.by, r.author) }
        if mark then
          table.insert(parts, "[" .. mark .. "]")
        end
        return table.concat(parts, " · ")
      end,
    }, function(r)
      if not r then
        return
      end
      if r.installed == "builtin" or (r.installed == "site" and not r.update) then
        return walk(r.id)
      end
      commands.install(r.id) -- your own route with the same id: install asks first
    end)
  end)
end

M.commands = commands

local VALUES = {
  difficulty = { "easy", "medium", "hard" },
  scoring = { "on", "off" },
  lang = vim.list_extend({ "auto" }, I18N.order),
}

function M.complete(arglead, cmdline)
  local words = vim.split(cmdline, "%s+", { trimempty = true })
  local typing_first = #words == 1 or (#words == 2 and not cmdline:match("%s$"))
  local pool = typing_first and vim.tbl_keys(commands) or (VALUES[words[2]] or {})
  table.sort(pool)
  return vim.tbl_filter(function(v)
    return v:sub(1, #arglead) == arglead
  end, pool)
end

function M.run(args)
  local name = args[1] or "status"
  local value = #args > 1 and table.concat(args, " ", 2) or nil
  local fn = commands[name]
  if not fn then
    return vim.notify("Commit Hike: unknown command " .. name, vim.log.levels.ERROR)
  end
  fn(value)
end

-- ---------------------------------------------------------------- setup
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  -- Also here, not only in plugin/: plugin managers that add plugins/neovim to
  -- the runtimepath after start-up (lazy.nvim's config) never source plugin/.
  if vim.fn.exists(":CommitHike") ~= 2 then
    vim.api.nvim_create_user_command("CommitHike", function(o)
      M.run(o.fargs)
    end, { nargs = "*", desc = "Commit Hike: your commits walk a hiking trail", complete = M.complete })
  end
  local group = vim.api.nvim_create_augroup("CommitHike", { clear = true })
  vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "FocusGained" }, {
    group = group,
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if state.watcher then
        state.watcher:stop()
      end
      if state.timer then
        state.timer:stop()
      end
    end,
  })
  if state.timer then
    state.timer:stop()
    state.timer = nil
  end
  if (M.config.interval or 0) > 0 then
    state.timer = uv.new_timer()
    state.timer:start(M.config.interval * 1000, M.config.interval * 1000, vim.schedule_wrap(M.refresh))
  end
  if vim.v.vim_did_enter == 1 then
    M.refresh()
  end
end

return M
