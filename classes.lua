classes = {}

classes.material = class("material")

function classes.material:initialize()
    self.name = "material #"..#layers
    self.albedo = {}
    self.normal = {}
    self.roughness = {}
    self.metallic = {}
    self.metallic_value = new("float[1]",0)
    self.ao = {}
    self.emission = {}
    self.mask = {}
end

return classes