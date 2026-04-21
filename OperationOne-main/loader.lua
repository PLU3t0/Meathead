local flag_name = "DebugRunParallelLuaOnMainThread"
local main_url = "https://github.com/PLU3t0/Meathead/raw/refs/heads/main/OperationOne-main/main.lua"
local rejoin_msg = "REJOIN THE GAME FUCK FURRY."
local max_attempts = 3
local retry_delay = 1

local players = game:GetService("Players")
local local_player = players.LocalPlayer

local function get_executor()
    local fn = identifyexecutor
    if type(fn) == "function" then
        local ok, name = pcall(fn)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end

    fn = getexecutorname
    if type(fn) == "function" then
        local ok, name = pcall(fn)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end

    return "Unknown"
end

local function notify_not_supported(exec_name)
    local function load_ui_from_source(src, label)
        local compile = loadstring or load
        if type(compile) ~= "function" then
            return nil
        end

        local ok_chunk, chunk = pcall(compile, src, "@loader_ui:" .. tostring(label))
        if not ok_chunk or type(chunk) ~= "function" then
            return nil
        end

        local ok_run, lib = pcall(chunk)
        if not ok_run or type(lib) ~= "table" then
            return nil
        end

        if type(lib.notify) ~= "function" then
            return nil
        end

        return lib
    end

    local lib = nil

    if type(readfile) == "function" then
        local ok_read, src = pcall(readfile, "ui_lib.lua")
        if ok_read and type(src) == "string" and src ~= "" then
            lib = load_ui_from_source(src, "local:ui_lib.lua")
        end
    end

    if not lib then
        local ok_http, src = pcall(function()
            return game:HttpGet("https://github.com/PLU3t0/Meathead/raw/refs/heads/main/OperationOne-main/ui_lib.lua")
        end)
        if ok_http and type(src) == "string" and src ~= "" then
            lib = load_ui_from_source(src, "url:ui_lib.lua")
        end
    end

    if lib then
        pcall(function()
            lib:notify("Loader", tostring(exec_name) .. " is not supported", nil, false)
        end)
    end
end

local UNSUPPORTED_EXECUTORS = {
    ["xeno"] = true,
    ["solara"] = true,
    ["wave"] = true,
    ["velocity"] = true,
}

local executor = get_executor()
local executor_lc = string.lower(executor)

if UNSUPPORTED_EXECUTORS[executor_lc] then
    notify_not_supported(executor)
    return
end

local function is_flag_on(v)
    if type(v) == "boolean" then
        return v
    end

    if type(v) == "string" then
        return string.lower(v) == "true"
    end

    return false
end

local function read_flag(flag)
    if type(getfflag) ~= "function" then
        return nil
    end

    local ok, value = pcall(getfflag, flag)
    if ok then
        return value
    end

    return nil
end

local function set_flag_true(flag)
    if type(setfflag) ~= "function" then
        return false
    end

    local ok = pcall(setfflag, flag, "true")
    return ok == true
end

local function kick_rejoin()
    if local_player and type(local_player.Kick) == "function" then
        local_player:Kick(rejoin_msg)
    end
end

local function fetch_source(link)
    local ok, src = pcall(function()
        return game:HttpGet(link)
    end)

    if not ok or type(src) ~= "string" or src == "" then
        return nil, "failed to fetch source from " .. tostring(link)
    end

    return src, nil
end

local function compile_src(src)
    local compile = loadstring
    if type(compile) ~= "function" then
        return nil, "loadstring unavailable"
    end

    local ok, chunk = pcall(compile, src, "@operationone_main")
    if not ok or type(chunk) ~= "function" then
        return nil, "failed to compile main source"
    end

    return chunk, nil
end

local function run_main_with_retry(link)
    local last_err = nil

    for attempt = 1, max_attempts do
        local src, fetch_err = fetch_source(link)
        if src then
            local chunk, compile_err = compile_src(src)
            if chunk then
                local ok_run, run_err = pcall(chunk)
                if ok_run then
                    return true
                end
                last_err = "runtime error: " .. tostring(run_err)
            else
                last_err = compile_err
            end
        else
            last_err = fetch_err
        end

        if attempt < max_attempts then
            task.wait(retry_delay)
        end
    end

    error("loader failed after " .. tostring(max_attempts) .. " attempts: " .. tostring(last_err))
end

local function get_actor()
    if type(getactors) ~= "function" then
        return nil
    end

    local ok, list = pcall(getactors)
    if not ok or type(list) ~= "table" then
        return nil
    end

    for _, a in ipairs(list) do
        if typeof(a) == "Instance" and a:IsA("Actor") then
            return a
        end
    end

    for _, a in pairs(list) do
        if typeof(a) == "Instance" and a:IsA("Actor") then
            return a
        end
    end

    return nil
end

local function build_actor_code(link)
    return string.format([[
local max_attempts = %d
local retry_delay = %s
local last_err = nil

for attempt = 1, max_attempts do
    local ok_src, src = pcall(function()
        return game:HttpGet(%q)
    end)

    if ok_src and type(src) == "string" and src ~= "" then
        local compile = loadstring
        if type(compile) ~= "function" then
            last_err = "loadstring unavailable"
        else
            local ok_chunk, chunk = pcall(compile, src, "@operationone_main")
            if ok_chunk and type(chunk) == "function" then
                local ok_run, run_err = pcall(chunk)
                if ok_run then
                    return
                end
                last_err = "runtime error: " .. tostring(run_err)
            else
                last_err = "failed to compile main source"
            end
        end
    else
        last_err = "failed to fetch source from " .. tostring(%q)
    end

    if attempt < max_attempts then
        task.wait(retry_delay)
    end
end

error("loader actor failed after " .. tostring(max_attempts) .. " attempts: " .. tostring(last_err))
]], max_attempts, tostring(retry_delay), link, link)
end

local function run_main_on_actor(actor, link)
    if typeof(actor) ~= "Instance" or not actor:IsA("Actor") then
        return false
    end
    if type(run_on_actor) ~= "function" then
        return false
    end

    local actor_code = build_actor_code(link)
    task.spawn(function()
        pcall(run_on_actor, actor, actor_code)
    end)

    return true
end

local actor = get_actor()
if actor and run_main_on_actor(actor, main_url) then
    return
end

if not is_flag_on(read_flag(flag_name)) then
    set_flag_true(flag_name)
    kick_rejoin()
    return
end

run_main_with_retry(main_url)
