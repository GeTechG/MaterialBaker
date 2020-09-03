-- load ffi
ffi = require "ffi"
new = ffi.new

slash = ''
if jit.os == "Windows" then
    slash = '\\'
else
    slash = '/'
end

layers = {}
current_layer = new("int[1]",0)
dimen_texture = new("int[2]",{1024,1024})

--load 3DreamEngine
dream = require("3DreamEngine")
--load inspect
inspect = require('inspect')
--optionally set settings
imgui = require "imgui.love"

class = require 'middleclass'
classes = require 'classes'
faicons = require 'fonts.fAwesome5'
magick = require("magick.wand")
render_texs = {
	albedo = nil,
	RMA = nil,
	normal = nil,
	normal_data = nil,
	emission = nil
}

--load gui
local gui = require "gui"

function table.moveCell(table,inn,outt)
    local new_t = {}
    for i = 1,#table do
        if i ~= inn then
            new_t[#new_t+1] = table[i]
        end
        if i == outt then
            new_t[#new_t+1] = table[inn]
        end
    end
    return new_t
end

function resizeImageData(data,width,height)
	local img = love.graphics.newImage(data)
	local canvas = love.graphics.newCanvas(width, height)
	local old_width,old_height = data:getDimensions()
	love.graphics.push("all")
	local wasCanvas = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	
	love.graphics.draw(img,0,0,0,width/old_width,height/old_height)
	love.graphics.pop()
	love.graphics.setCanvas(wasCanvas)
	return canvas:newImageData()
end

local instance
love.load = function(table)
	instance = imgui.love_load{use_imgui_docking = true, use_imgui_viewport = false}
	love.window.maximize()
	
	imgui.GetIO().Fonts:AddFontDefault()

	local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    config.SizePixels = 14.0;
    config.FontDataOwnedByAtlas = false
    config.GlyphOffset.y = 1.0 -- смещение на 1 пиксеыот вниз
    local fa_glyph_ranges = new("ImWchar[3]",{ faicons.min_range, faicons.max_range, 0 })
    -- icon
    local faicon = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), config.SizePixels, config, fa_glyph_ranges)

	layers[#layers+1] = classes.material:new()
end

--settings
local camZoom = 5
local camAngle = {0,0}
local sunPos = {100,100,100}

time = 0
lights = dream:newLight(0, 0, 0, 1.0, 0.75, 0.5)
lights.shadow = dream:newShadow("point")
lights.shadow.size = 0.1

--dream.defaultReflection = cimg:load("sky.cimg")
dream.sky_as_reflection = true
dream.defaultShaderType = "PBR"
--inits (applies settings)
dream.alphaBlendMode = "alpha"
dream:init()
--loads a object (optional with args)
yourObject = dream:loadObject("object", {splitMaterials = true, export3do = false, skip3do = true})
print(inspect(yourObject))


local v = 0
love.draw = function()
	dream:setDaytime(gui.world_settings.dayTime[0])

	dream:setWeather(0.25, 1.0 - 0.25)

	--update lights
	dream:resetLight()
	dream:resetLight()
	dream.cam:reset()

	local cx = (camZoom*math.sin(math.rad(camAngle[1]))*math.cos(math.rad(camAngle[2])))
	local cy = (camZoom*math.cos(math.rad(camAngle[1]))*math.cos(math.rad(camAngle[2])))
	local cz = (camZoom*math.sin(math.rad(camAngle[2])))
	--dream:addNewLight(sunPos[1],sunPos[2],sunPos[3], 1, 1, 1, 20, "sun")
	dream.cam:translate(cx,cz,-cy)
	--dream:addNewLight(-cx,-cz,cy, 1, 1, 1, 15)
	dream.cam:rotateY(math.rad(-camAngle[1]))
	dream.cam:rotateX(math.rad(-camAngle[2]))

  --prepare for rendering
  dream:prepare()

  --rotate and draw and offset
	dream:draw(yourObject)

  --render
  dream:present(not gui.world_settings.sky[0])


  instance:NewFrame()
  instance.MainDockSpace()
  gui.draw()
  instance:Render()
end

function love.mousemoved(x, y, dx, dy)
	if love.mouse.isDown(3) then
		camAngle[1] = camAngle[1] + dx
		camAngle[2] = camAngle[2] - dy
	end
end

function love.wheelmoved(x, y)
	camZoom = camZoom + y
end

function love.update(dt)

	gui.world_settings.dayTime[0] = gui.world_settings.dayTime[0] + dt * 0.05 * gui.world_settings.speedDay[0]
	if gui.world_settings.dayTime[0] > 1 then gui.world_settings.dayTime[0] = 0 end
	dream:update()
end

function love.keyreleased(key, scancode)
	if key == 'escape' then
		love.event.quit(0)
	end
	instance.update_key(scancode, false)
end

function love.resize()
	dream:init()
end

love.keypressed = function(key,scancode,isrepeat)
	instance.update_key(scancode, true)
end

love.textinput = function(text)
    instance.textinput(text)
end

love.quit = function()
  instance:destroy()
end
