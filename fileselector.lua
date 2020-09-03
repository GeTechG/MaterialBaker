brow = {}

slash = ''
if jit.os == "Windows" then
    slash = '\\'
else
    slash = '/'
end

local path = new("char[512]",love.filesystem.getWorkingDirectory())
local current_item = 0;

function brow.load()
    imgui.Begin("Open file",nil,imgui.lib.ImGuiWindowFlags_AlwaysAutoResize)
    imgui.InputText("path", path, ffi.sizeof(path))
    if imgui.ListBoxHeaderVec2("", imgui.ImVec2(400,250)) then
        local i = 0
        if lfs.attributes(ffi.string(path),"mode") ~= nil then
            for file in lfs.dir(ffi.string(path)) do
                local item = lfs.attributes(ffi.string(path)..slash..file,"mode")
                local icon = ''
                if item == "file" then
                    icon = faicons.ICON_FILE.." "
                elseif item == "directory" then
                    icon = faicons.ICON_FOLDER.." "
                end 
                if imgui.Selectable(icon..file,i == current_item,imgui.lib.ImGuiSelectableFlags_AllowDoubleClick) then
                    if imgui.IsMouseDoubleClicked(0) then
                            current_item = i
                        
                    end
                end
                i = i + 1
            end
        end
        imgui.ListBoxFooter()
    end
    imgui.End()
end

return brow