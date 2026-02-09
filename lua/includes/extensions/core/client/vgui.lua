local min, Round = math.min, math.Round


local Scale; do
    local baseW, baseH = 1920, 1080
    
    local scale = 1
    local setup = function( scrW, scrH ) scale = min( scrW / baseW, scrH / baseH ) end

    Scale = function( n )
        return Round( n * scale )
    end

    setup( ScrW(), ScrH() )
    
    -- Why would anyone even need to change screen resolution? 
    hook.Add( "OnScreenSizeChanged", "vgui", function( oldW, oldH, newW, newH ) 
        setup( newW, newH )
    end )
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