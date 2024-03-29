--[[
#part of the 3DreamEngine by Luke100000
shader.lua - loads the shaders
--]]

local lib = _3DreamEngine

local testForOpenES = true

--enables auto shader validator
if _DEBUGMODE then
	love.graphics.newShader_old = love.graphics.newShader
	function love.graphics.newShader(pixel, vertex)
		local status, err = love.graphics.validateShader(testForOpenES, pixel, vertex)
		if not status then
			print()
			print("-----------------")
			print("SHADER ERROR")
			if not vertex and #pixel < 1024 and not pixel:find("\n") then
				print(pixel)
			end
			print(err)
			print(debug.traceback())
			print("-----------------")
			print()
			
			--dump shader in case of error
			love.filesystem.write("shader_errored.glsl", pixel)
		end
		local sh = love.graphics.newShader_old(pixel, vertex)
		local warnings = sh:getWarnings()
		if #warnings ~= 29 then
			if not vertex and #pixel < 1024 and not pixel:find("\n") then
				print(pixel)
			end
			print(warnings)
			print()
		end
		return sh
	end
end

--shader library
lib.shaderLibrary = {
	base = { },
	vertex = { },
	light = { },
	module = { },
}

--shader register
function lib:registerShader(path)
	local name = (path:match("^.+/(.+)$") or path):sub(1, -5)
	local sh = require(path:sub(1, -5))
	self.shaderLibrary[sh.type][name] = sh
end

--register inbuild shaders
for i,v in ipairs({"base", "vertex", "light", "modules"}) do
	for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/" .. v)) do
		if s:sub(-4) == ".lua" then
			lib:registerShader(lib.root .. "/shaders/" .. v .. "/" .. s)
		end
	end
end

--load code snippsets
local codes = { }
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/functions")) do
	codes[s:sub(1, #s-5)] = love.filesystem.read(lib.root .. "/shaders/functions/" .. s)
end

lib.shaders = { }

--blur
lib.shaders.blur = love.graphics.newShader(lib.root .. "/shaders/blur.glsl")
lib.shaders.blur_cube = love.graphics.newShader(lib.root .. "/shaders/blur_cube.glsl")

--applies bloom at a given strength
lib.shaders.bloom = love.graphics.newShader(lib.root .. "/shaders/bloom.glsl")

--the sky sphere shader
lib.shaders.sky = love.graphics.newShader(lib.root .. "/shaders/sky.glsl")
lib.shaders.sky_hdri = love.graphics.newShader(lib.root .. "/shaders/sky_hdri.glsl")
lib.shaders.sky_WilkieHosek = love.graphics.newShader(lib.root .. "/shaders/sky_WilkieHosek.glsl")

--the shadow shader
lib.shaders.shadow = love.graphics.newShader(lib.root .. "/shaders/shadow.glsl")

--particle shader, draw textures at a given depth
lib.shaders.particle = love.graphics.newShader(lib.root .. "/shaders/particle.glsl")
lib.shaders.billboard = love.graphics.newShader(lib.root .. "/shaders/billboard.glsl")
lib.shaders.billboard_moon = love.graphics.newShader(lib.root .. "/shaders/billboard_moon.glsl")
lib.shaders.billboard_sun = love.graphics.newShader(lib.root .. "/shaders/billboard_sun.glsl")

--autoExposure vignette
lib.shaders.autoExposure = love.graphics.newShader(lib.root .. "/shaders/autoExposure.glsl")

--clouds
lib.shaders.clouds = love.graphics.newShader(lib.root .. "/shaders/clouds.glsl")

--debug shaders
if _DEBUGMODE then
	for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/debug")) do
		lib.shaders[s:sub(1, #s-5)] = love.graphics.newShader(lib.root .. "/shaders/debug/" .. s)
	end
end

--load all setting depending shaders
function lib.loadShader(self)
	self.shaders.final = { }
	self.mainShaders = { }

	--the ambient occlusion shader
	local code = (
		"#define SAMPLE_COUNT " .. self.AO_quality .. "\n" ..
		love.filesystem.read(self.root .. "/shaders/SSAO.glsl")
	):gsub("	", "")
	self.shaders.SSAO = love.graphics.newShader(code)
	
	--pass samples to the shader
	local f = { }
	local range = 64.0
	for i = 1, self.AO_quality do
		local r = i / self.AO_quality * math.pi * 2
		local d = (0.5 + i % 4) / 4
		f[#f+1] = {math.cos(r)*d*range / love.graphics.getWidth(), math.sin(r)*d*range / love.graphics.getHeight(), (1-d)^2 / self.AO_quality}
	end
	self.shaders.SSAO:send("samples", unpack(f))
end

--the final canvas combines all resources into one result
local sh_final = love.filesystem.read(lib.root .. "/shaders/final.glsl")
function lib.getFinalShader(self, canvases)
	local parts = { }
	parts[#parts+1] = canvases.postEffects_enabled and "#define POSTEFFECTS_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.autoExposure_enabled and "#define AUTOEXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.exposure > 0 and "#define EXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.bloom_enabled and "#define BLOOM_ENABLED" or nil
	
	parts[#parts+1] = self.fog_enabled and "#define FOG_ENABLED" or nil
	
	parts[#parts+1] = self.AO_enabled and "#define AO_ENABLED" or nil
	parts[#parts+1] = self.SSR_enabled and "#define SSR_ENABLED" or nil
	
	parts[#parts+1] = canvases.alphaBlendMode == "average" and "#define AVERAGE_ALPHA" or nil
	parts[#parts+1] = (self.fxaa and canvases.msaa == 0) and "#define FXAA_ENABLED" or nil
	
	parts[#parts+1] = self.refraction_enabled and "#define REFRACTION_ENABLED" or nil
	
	local ID = table.concat(parts, "\n")
	if not self.shaders.final[ID] then
		self.shaders.final[ID] = love.graphics.newShader("#pragma language glsl3\n" .. ID .. "\n" .. sh_final)
	end
	return self.shaders.final[ID]
end

--returns and initializes if not already done
local moduleIDs = { }
local lastModuleID = 1
function lib:getShaderModule(name)
	if not moduleIDs[name] then
		lastModuleID = lastModuleID + 1
		moduleIDs[name] = 1.0 / lastModuleID
	end
	
	local sh = self.shaderLibrary.module[name]
	self.allActiveShaderModules[name] = sh
	if not sh.initilized then
		sh.initilized = true
		if sh.init then
			sh:init(self)
		end
	end
	return sh
end

--returns a fitting shader construction instruction for the current material and meshtype
function lib:getShaderInfo(s, obj)
	local mat = s.material
	local shaderType = s.shaderType
	local reflection = s.reflection or obj.reflection
	local modules = s.modules or obj.modules
	
	local vertexShader = mat.shader or "default"
	
	--group shader and vertex shader
	if not self.mainShaders[shaderType] then
		self.mainShaders[shaderType] = { }
	end
	if not self.mainShaders[shaderType][vertexShader] then
		self.mainShaders[shaderType][vertexShader] = { }
	end
	
	--add new type of shader to list
	local shs = self.mainShaders[shaderType][vertexShader]
	
	--get a unique ID
	assert(self.shaderLibrary.base[shaderType], "Shader '" .. shaderType .. "' does not exist!")
	local ID = self.shaderLibrary.base[shaderType]:getShaderInfoID(self, mat, shaderType, reflection)
	
	--reflection module
	ID = ID + ((reflection or dream.defaultReflection) and 1024 or 0)
	
	--global modules
	local m = { }
	for d,s in pairs(self.activeShaderModules) do
		m[d] = self:getShaderModule(d)
		ID = ID + moduleIDs[d]
	end
	
	--local modules
	if modules then
		for d,s in pairs(modules) do
			if not self.activeShaderModules[d] then
				m[d] = self:getShaderModule(d)
				ID = ID + moduleIDs[d]
			end
		end
	end
	
	--create new shader info object if necessary
	if not shs[ID] then
		shs[ID] = self.shaderLibrary.base[shaderType]:getShaderInfo(self, mat, shaderType, reflection)
		shs[ID].shaderType = shaderType
		shs[ID].vertexShader = vertexShader
		shs[ID].reflection = reflection or dream.defaultReflection
		shs[ID].shaders = { }
		shs[ID].modules = m
	end
	
	return shs[ID]
end

--construct a shader
local baseShader = love.filesystem.read(lib.root .. "/shaders/base.glsl")
local lastID = 0
local lightRequirementIDs = { }
function lib:getShader(info, lighting, lightRequirements)
	--get a unique ID for this specific light setup
	local ID = 0
	for d,s in pairs(lightRequirements) do
		if not lightRequirementIDs[d] then
			lightRequirementIDs[d] = 16 ^ lastID
			lastID = lastID + 1
		end
		ID = ID + lightRequirementIDs[d] * s
	end
	
	if not info.shaders[ID] then
		--construct shader
		local code = baseShader
		
		--setting specific defines
		code = code:gsub("#import globalDefines", [[
			#define REFRACTION_ENABLED
		]])
		
		--the shader might need additional code
		code = code:gsub("#import mainDefines", self.shaderLibrary.base[info.shaderType]:constructDefines(self, info) or "")
		code = code:gsub("#import mainPixelPre", self.shaderLibrary.base[info.shaderType]:constructPixelPre(self, info) or "")
		code = code:gsub("#import mainPixelPost", self.shaderLibrary.base[info.shaderType]:constructPixelPost(self, info) or "")
		code = code:gsub("#import mainPixel", self.shaderLibrary.base[info.shaderType]:constructPixel(self, info) or "")
		code = code:gsub("#import mainVertex", self.shaderLibrary.base[info.shaderType]:constructVertex(self, info) or "")
		
		--import vertex module
		assert(self.shaderLibrary.vertex[info.vertexShader], "Vertex shader '" .. info.vertexShader .. "' does not exist!")
		code = code:gsub("#import vertexDefines", self.shaderLibrary.vertex[info.vertexShader]:constructDefines(self, info) or "")
		code = code:gsub("#import vertexPixel", self.shaderLibrary.vertex[info.vertexShader]:constructPixel(self, info) or "")
		code = code:gsub("#import vertexVertex", self.shaderLibrary.vertex[info.vertexShader]:constructVertex(self, info) or "")
		
		--import reflection function
		code = code:gsub("#import reflections", info.reflection and codes.reflections or codes.ambientOnly)
		
		--import additional modules
		local define = { }
		local vertex = { }
		local pixel = { }
		local pixelPost = { }
		for d,s in pairs(info.modules) do
			assert(s, "Shader module '" .. d .. "' does not exist!")
			table.insert(define, s:constructDefines(self, info) or "")
			table.insert(vertex, s:constructVertex(self, info) or "")
			table.insert(pixel, s:constructPixel(self, info) or "")
			table.insert(pixelPost, s:constructPixelPost(self, info) or "")
		end
		code = code:gsub("#import modulesDefines", table.concat(define, "\n"))
		code = code:gsub("#import modulesVertex", table.concat(vertex, "\n"))
		code = code:gsub("#import modulesPixelPost", table.concat(pixelPost, "\n"))
		code = code:gsub("#import modulesPixel", table.concat(pixel, "\n"))
		
		--construct forward lighting system
		if #lighting > 0 then
			local lcInit = { }
			local lc = { }
			
			local lightSignature = self.shaderLibrary.base[info.shaderType]:getLightSignature(self)
			
			--light positions, colors and meters (not always used)
			lcInit[#lcInit+1] = [[
				extern vec3 lightPos[]] .. #lighting .. [[];
				extern vec3 lightColor[]] .. #lighting .. [[];
			]]
			
			--global defines
			for d,s in pairs(lightRequirements) do
				assert(self.shaderLibrary.light[d], "Light of type '" .. d .. "' does not exist!")
				lcInit[#lcInit+1] = self.shaderLibrary.light[d]:constructDefinesGlobal(self, info)
			end
			
			--defines
			for	 d,s in ipairs(lighting) do
				lcInit[#lcInit+1] = self.shaderLibrary.light[s.light_typ]:constructDefines(self, info, d-1)
			end
			
			--code
			for d,s in ipairs(lighting) do
				lc[#lc+1] = "{" .. self.shaderLibrary.light[s.light_typ]:constructPixel(self, info, d-1, lightSignature) .. "}"
			end
			
			code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
			code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
			code = code:gsub("#import lightFunction", self.shaderLibrary.base[info.shaderType].constructLightFunction and self.shaderLibrary.base[info.shaderType]:constructLightFunction(self, info) or codes.Phong)
		end
		
		--remove unused imports and remove tabs
		code = code:gsub("#import", "//#import")
		code = code:gsub("	", "")
		
		--compile
		local ok, shader = pcall(love.graphics.newShader, code)
		if ok then
			info.shaders[ID] = shader
		end
		
		--love.filesystem.write(ID .. ".glsl", code)
	end
	
	return info.shaders[ID]
end