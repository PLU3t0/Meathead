  pcall(function() setthreadidentity(8) end)
    local cloneref    = cloneref or function(o) return o end
    local clonefunc   = clonefunction or function(f) return f end
    local newcclosure = newcclosure or function(f) return f end
    local table_find  = clonefunc(table.find)
    local task_defer  = clonefunc(task.defer)
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local Data    = require(ReplicatedStorage.Modules.Data)
    local Net     = require(ReplicatedStorage.Modules.Net)
    local Loadout = require(ReplicatedStorage.Modules.Loadout)

    local AUTO_NAME  = "ASTOWASGOD"
    local isRenaming = false
    local original_get = clonefunc(Net.get)

    hookfunction(Net.get, newcclosure(function(...)
        local args = {...}

        if args[1] == "change_class_name" and not isRenaming then
            local classIndex = args[2]
            local result = original_get(...)
            task_defer(newcclosure(function()
                isRenaming = true
                local accepted = original_get("change_class_name", classIndex, AUTO_NAME)
                if accepted then
                    Data.classes[classIndex].name = accepted
                end
                isRenaming = false
            end))
            return result
        end

        if args[1] == "create_class" then
            local before = #Data.classes
            local result = original_get(...)
            task.wait(0.2)
            local newIndex = before + 1
            if Data.classes[newIndex] then
                isRenaming = true
                local accepted = original_get("change_class_name", newIndex, AUTO_NAME)
                if accepted then
                    Data.classes[newIndex].name = accepted
                end
                isRenaming = false
            end
            return result
        end

        return original_get(...)
    end))

    task.spawn(newcclosure(function()
        local currentClass = Loadout.chosen_class:get()
        if not currentClass then
            repeat task.wait(0.5) until Loadout.chosen_class:get()
            currentClass = Loadout.chosen_class:get()
        end
        local classIndex = table_find(Data.classes, currentClass)
        if not classIndex or Data.classes[classIndex].name == AUTO_NAME then return end
        isRenaming = true
        local accepted = original_get("change_class_name", classIndex, AUTO_NAME)
        if accepted then
            Data.classes[classIndex].name = accepted
        end
        isRenaming = false
    end))