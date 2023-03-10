--- @meta
--- @module 'ColorF'

--- Creates a new color.
--- @param r number The red value of the color.
--- @param g number The green value of the color.
--- @param b number The blue value of the color.
--- @param a number The alpha value of the color.
--- @return ColorF color The new color.
function ColorF(r, g, b, a) end

--- The ColorF class represents a color in RGBa format.
--- @class ColorF
--- @field r number The red value of the color.
--- @field g number The green value of the color.
--- @field b number The blue value of the color.
--- @field a number The alpha value of the color.
--- @field alpha number The alpha value of the color.
--- Values `a` & `alpha` should always be the same.
local ColorF = {}

--- Converts the color to a string in the format `r g b a` where r, g, b and a are numbers in the range 0-1.
--- @param self ColorF The color to convert.
--- @return string color The color as a string.
function ColorF:asLinear4F() end

--- Converts the color to a string in the format `r, g, b, a` where r, g, b and a are numbers in the range 0-1.
--- @param self ColorF The color to convert.
--- @return string color The color as a string.
function ColorF:__tostring() end
