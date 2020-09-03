gui = {}



gui.b_settings = ffi.new("bool[1]",true)
gui.b_saveMaterial = ffi.new("bool[1]",true)

function gui.draw()
  if gui.b_settings[0] then draw_settings() end
  if gui.b_saveMaterial[0] then saveMaterial() end
end


gui.world_settings = {
  dayTime = new("float[1]",0),
  speedDay = new("float[1]",0),
  sky = new("bool[1]",true),
}


gui.current_image_data = nil;
gui.current_image_texture = nil;
gui.settings_size = imgui.ImVec2(0,0)
gui.cut_layer = -1
function draw_settings()
  --imgui.ShowDemoWindow(gui.b_settings)

  imgui.Begin("Settings",nil, imgui.lib.ImGuiWindowFlags_AlwaysAutoResize + imgui.lib.ImGuiWindowFlags_NoCollapse)
  
  if imgui.BeginTabBar("Tabs") then
    if imgui.BeginTabItem("World") then
      imgui.SetNextItemWidth(120)
      imgui.DragScalar("Day time", imgui.lib.ImGuiDataType_Float, gui.world_settings.dayTime,new("float",0.001), new("float[1]",0), new("float[1]",1))
      imgui.SetNextItemWidth(120)
      imgui.DragFloat("Speed of day", gui.world_settings.speedDay,new("float",0.1))
      imgui.Checkbox("Sky", gui.world_settings.sky)
      imgui.EndTabItem()
    end
    if imgui.BeginTabItem("Materials") then

      imgui.Text("Layers")
      imgui.SetNextItemWidth(imgui.GetWindowWidth())
      if imgui.ListBoxHeaderInt("",5,15) then
        imgui.SetNextItemWidth(120)
        imgui.InputInt2("Size textures", dimen_texture)
        for i = 1,#layers do
          imgui.SelectableBool(layers[i].name, current_layer[0]+1 == i)
          if imgui.IsItemClicked(0) then
            current_layer[0] = i-1
          end
        end

        imgui.ListBoxFooter()
      end
      if imgui.Button("Add") then
        layers[#layers+1] = classes.material:new()
      end
      if #layers > 1 then
        imgui.SameLine()
        if imgui.Button("Delete") then
          table.remove(layers, current_layer[0] + 1)
          if current_layer[0] > 0 then
            current_layer[0] = current_layer[0] - 1
          end
          dream:update_texture('albedo')
          dream:update_texture('RMA')
          dream:update_texture('normal')
          dream:update_texture('emission')
        end
        imgui.SameLine()
        if imgui.Button("Cut") then
          gui.cut_layer = current_layer[0]
        end
        if gui.cut_layer ~= -1 then
          imgui.SameLine()
          if imgui.Button("Paste") then
            layers = table.moveCell(layers,gui.cut_layer+1,current_layer[0]+1)
            gui.cut_layer = -1
            dream:update_texture('albedo')
            dream:update_texture('RMA')
            dream:update_texture('normal')
            dream:update_texture('emission')
          end
        end
      end

      if #layers > 0 then
        imgui.Text("Material Settings")
        if layers[current_layer[0]+1]:isInstanceOf(classes.material) then
          if imgui.BeginChild("mat_sett",nil,true) then
            imgui.Text("Maps")
            imgui.Separator()

            imgui.PushIDPtr("albedo")
              if imgui.TreeNodeStr("Albedo") then
                if layers[current_layer[0]+1].albedo[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].albedo[0] = nil
                    render_texs.albedo = nil
                    dream:update_texture('albedo')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].albedo
                  gui.current_image_texture = 'albedo'
                  imgui.OpenPopup("Drop file")
                end
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.PushIDPtr("normal")
              if imgui.TreeNodeStr("Normal") then
                if layers[current_layer[0]+1].normal[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].normal[0] = nil
                    render_texs.normal = nil
                    dream:update_texture('normal')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].normal
                  gui.current_image_texture = 'normal'
                  imgui.OpenPopup("Drop file")
                end
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.PushIDPtr("rough")
              if imgui.TreeNodeStr("Roughness") then
                if layers[current_layer[0]+1].roughness[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].roughness[0] = nil
                    render_texs.RMA = nil
                    dream:update_texture('RMA')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].roughness
                  gui.current_image_texture = 'RMA'
                  imgui.OpenPopup("Drop file")
                end
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.PushIDPtr("met")
              if imgui.TreeNodeStr("Metallic") then
                if layers[current_layer[0]+1].metallic[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].metallic[0] = nil
                    render_texs.RMA = nil
                    dream:update_texture('RMA')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].metallic
                  gui.current_image_texture = 'RMA'
                  imgui.OpenPopup("Drop file")
                end
                --imgui.DragFloat("Intensity", layers[current_layer[0]+1].metallic_value, 0.1, 0.0, 1.0)
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.PushIDPtr("ao")
              if imgui.TreeNodeStr("Ambient occlusion (AO)") then
                if layers[current_layer[0]+1].ao[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].ao[0] = nil
                    render_texs.RMA = nil
                    dream:update_texture('RMA')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].ao
                  gui.current_image_texture = 'RMA'
                  imgui.OpenPopup("Drop file")
                end
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.PushIDPtr("emission")
              if imgui.TreeNodeStr("Emission") then
                if layers[current_layer[0]+1].emission[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].emission[0] = nil
                    render_texs.emission = nil
                    dream:update_texture('emossion')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].emission
                  gui.current_image_texture = 'emission'
                  imgui.OpenPopup("Drop file")
                end
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.Separator()
            imgui.PushIDPtr("mask")
              if imgui.TreeNodeStr("Mask") then
                if layers[current_layer[0]+1].mask[0] then
                  if imgui.Button("clear") then
                    layers[current_layer[0]+1].mask[0] = nil
                    dream:update_texture('mask')
                  end
                else
                  imgui.Spacing()
                end
                imgui.SameLine(imgui.GetWindowWidth()-50)
                if imgui.Button("...") then
                  gui.current_image_data = layers[current_layer[0]+1].mask
                  gui.current_image_texture = 'mask'
                  imgui.OpenPopup("Drop file")
                end
                draw_dropfile()
                imgui.TreePop()
              end
            imgui.PopID()
            imgui.EndChild()
          end
        end
      end

      imgui.EndTabItem()
    end
    imgui.EndTabBar()
    

  end
  
  
  
  ffi.copy(gui.settings_size, imgui.GetWindowSize(),ffi.sizeof(gui.settings_size))
  imgui.End()
end

local formats = {"png","tga"}
local select_format = 1
local export_type = {"all textures","UE style","FPSC style"}
local select_export = 1
local prefix = new("char[128]",{})
function saveMaterial()
  imgui.Begin("Export",nil,imgui.lib.ImGuiWindowFlags_AlwaysAutoResize)
  if imgui.BeginCombo("Type export", export_type[select_export]) then
    for i = 1,#export_type do
      if imgui.SelectableBool(export_type[i], i==select_export) then
        select_export = i
      end
    end
    imgui.EndCombo()
  end
  if select_export ~= 3 then
    imgui.Text("Example: prefix_albedo.png")
  else
    imgui.Text("Example: prefix_D.dds")
  end
  imgui.InputText("Prefix", prefix, 128)
  if imgui.BeginCombo("Format", formats[select_format]) then
    for i = 1,#formats do
      if imgui.SelectableBool(formats[i], i==select_format) then
        select_format = i
      end
    end
    imgui.EndCombo()
  end
  if imgui.Button("Save") then
    local albedo = "";
    local normal = "";
    local RMA = "";
    local rough = "";
    local metal = "";
    local ao = "";
    local emiss = "";
    if select_export == 3 then
      albedo = "D"
      normal = "N"
      RMA = "S"
    else
      albedo = "albedo";
      normal = "normal";
      RMA = "AoRoughMet";
      rough = "roughness";
      metal = "metallic";
      ao = "ao";
      emiss = "emission";
    end
    if select_format ~= 1 then
      if render_texs.albedo then
        local file = io.open(ffi.string(prefix).."_"..albedo.."."..formats[select_format], "w")
        file:write(render_texs.albedo:newImageData():encode(formats[select_format]):getString())
        file:close()
      end

      if select_export ~= 3 then
        if render_texs.normal_data then
          local file = io.open(ffi.string(prefix).."_"..normal.."."..formats[select_format], "w")
          file:write(render_texs.normal_data:encode(formats[select_format]):getString())
          file:close()
        end

        if render_texs.emission then
          local file = io.open(ffi.string(prefix).."_"..emiss.."."..formats[select_format], "w")
          file:write(render_texs.emission:newImageData():encode(formats[select_format]):getString())
          file:close()
        end
        if render_texs.RMA then
          if select_export == 2 then
            local rma = render_texs.RMA:newImageData()
            rma:mapPixel(function(x, y, r, g, b, a)
              r,g,b = b,r,g
              return r, g, b, a
            end)
            local file = io.open(ffi.string(prefix).."_"..RMA.."."..formats[select_format], "w")
            file:write(rma:encode(formats[select_format]):getString())
            file:close()
          else
            local rma = render_texs.RMA:newImageData()
            local roughd = rma:clone()
            roughd:mapPixel(function(x, y, r, g, b, a)
              r,g,b = r,r,r
              return r, g, b, a
            end)
            local metd = rma:clone()
            metd:mapPixel(function(x, y, r, g, b, a)
              r,g,b = g,g,g
              return r, g, b, a
            end)
            local aod = rma:clone()
            aod:mapPixel(function(x, y, r, g, b, a)
              r,g,b = b,b,b
              return r, g, b, a
            end)
            local file = io.open(ffi.string(prefix).."_"..rough.."."..formats[select_format], "w")
            file:write(roughd:encode(formats[select_format]):getString())
            file:close()

            local file = io.open(ffi.string(prefix).."_"..metal.."."..formats[select_format], "w")
            file:write(metd:encode(formats[select_format]):getString())
            file:close()

            local file = io.open(ffi.string(prefix).."_"..ao.."."..formats[select_format], "w")
            file:write(aod:encode(formats[select_format]):getString())
            file:close()
          end
        end

      else
        local nm;
        if render_texs.normal_data then
          nm = render_texs.normal_data:clone()
        else 
          nm = love.image.newImageData(dimen_texture[0],dimen_texture[1])
        end
        local em;
        if render_texs.emission then
          em = render_texs.emission:newImageData()
        else
          em = love.image.newImageData(dimen_texture[0],dimen_texture[1])
        end
        nm:mapPixel(function(x, y, r, g, b, a)
          local _;
          local r1,g1,b1,a1 = em:getPixel(x,y)
          a = (r1+g1+b1)/3
          return r, g, b, a
        end)
        local file = io.open(ffi.string(prefix).."_"..normal.."."..formats[select_format], "w")
        file:write(nm:encode("png"):getString())
        file:close()

        if render_texs.RMA then
          local rma = render_texs.RMA:newImageData()
          rma:mapPixel(function(x, y, r, g, b, a)
            a,r,g,b = 1-g,r,b,0
            return r, g, b, a
          end)
          local file = io.open(ffi.string(prefix).."_"..RMA.."."..formats[select_format], "w")
          file:write(rma:encode("png"):getString())
          file:close()
        end
      end
    end
  end
  imgui.End()
end

function draw_dropfile()
  imgui.SetNextWindowPos(imgui.ImVec2(imgui.GetIO().DisplaySize.x * 0.5-100, imgui.GetIO().DisplaySize.y * 0.5-20))
  if imgui.BeginPopupModal("Drop file",nil,imgui.lib.ImGuiWindowFlags_NoTitleBar+imgui.lib.ImGuiWindowFlags_NoResize+imgui.lib.ImGuiWindowFlags_NoMove+imgui.lib.ImGuiWindowFlags_AlwaysAutoResize+imgui.lib.ImGuiWindowFlags_NoBackground) then
    imgui.Text("Drag file to window area")
    if imgui.IsMouseDoubleClicked(0) then
      imgui.CloseCurrentPopup()
    end
    function love.filedropped(file)
      local dt;
      --print(magick.load_image(file:getFilename()))
      if string.sub(file:getFilename(),-3) ~= "png" then
        local img = magick.load_image_from_blob(file:read())
        img:set_format("tga")
        dt = img:get_blob()
      else
        dt = file:read()
      end
      local data = love.filesystem.newFileData(dt, file:getFilename())
      gui.current_image_data[0] = resizeImageData(love.image.newImageData(data),dimen_texture[0],dimen_texture[1])
      dream:update_texture(gui.current_image_texture)
      gui.current_image_texture = nil
    end
    if not gui.current_image_texture then
      imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
  end
end

return gui
