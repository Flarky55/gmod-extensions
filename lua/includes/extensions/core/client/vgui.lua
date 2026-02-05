local PANEL = FindMetaTable( "Panel" )

local min, Round = math.min, math.Round


local Scale; do
    local baseW, baseH = 1920, 1080
    local scrW, scrH = ScrW(), ScrH()

    Scale = function( n )
        local scale = min( scrW / baseW, scrH / baseH )
        return Round( n * scale )
    end
end
vgui.Scale = Scale

local function CreateFont( name, font, size, fontData )
    fontData = fontData or {}
    fontData.font = font
    fontData.size = Scale( size )
    fontData.extended = true

    surface.CreateFont( name, fontData )

    return name
end
vgui.CreateFont = CreateFont