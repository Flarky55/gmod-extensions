local MAT_DEFAULT = Material( "maps/thumb/noicon.png" )


--[[
        Map Panel
--]]
local PANEL = {}

function PANEL:Init()
    local image = self:Add( "DImage" )
    image:Dock( LEFT )
    self.m_pImage = image
end

function PANEL:SetMapName( mapName )
    self.m_sMapName = mapName

    local mat = Material( "maps/thumb/" .. mapName .. ".png" )
    self.m_pImage:SetMaterial( mat )
end

function PANEL:GetMapName()
    return self.m_sMapName
end

function PANEL:GenerateExample( className, propertySheet, w, h )
    local ctrl = vgui.Create( className )
    ctrl:SetMapName( "gm_flatgrass" )

    propertySheet:AddSheet( className, ctrl, nil, true, true )
end

derma.DefineControl( "MapPanel", "Map panel", PANEL, "Panel" )


--[[
        Map Select
--]]
local PANEL = {}

function PANEL:Init()
    
end

vgui.Register( "MapSelect", PANEL, "DFrame" )