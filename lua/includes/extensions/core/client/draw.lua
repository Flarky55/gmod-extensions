local SimpleText = draw.SimpleText


function draw.SimpleTextShadowed( text, font, x, y, color, xAlign, yAlign, fontShadow, colorShadow )
    colorShadow = colorShadow or color_black

    SimpleText( text, fontShadow, x, y, colorShadow, xAlign, yAlign )
    SimpleText( text, font, x, y, color, xAlign, yAlign )
end