# module PushInterface.DisplayInterface

import ColorTypes
import FixedPointNumbers
import Cairo: CairoSurface, CairoContext, CairoARGBSurface, read_from_png, set_source_surface, set_source_rgb, rectangle, fill, save, restore, width, height, paint
import Cairo: _jl_libcairo

mutable struct Canvas
    surface::CairoSurface
    ctx::CairoContext
    function Canvas()
        surface = CairoARGBSurface(DisplayPixelWidth, DisplayPixelHeight)
        ctx = CairoContext(surface)
        new(surface, ctx)
    end
end

function draw(f::Function, canvas::Canvas)
    save(canvas.ctx)
    f(canvas.ctx)
    restore(canvas.ctx)
end

import Base: fill!
function fill!(canvas::Canvas, color::ColorTypes.RGB{FixedPointNumbers.Normed{UInt8,8}})
    draw(canvas) do ctx
        set_source_rgb(ctx, color.r, color.g, color.b) 
        rectangle(ctx, 0, 0, width(canvas.surface), height(canvas.surface))
        fill(ctx)
    end
end

function draw!(canvas::Canvas, path::String)
    image = read_from_png(path)
    draw(canvas) do ctx
        set_source_surface(ctx, image, 0, 0)
        paint(ctx)
    end
end

# module PushInterface.DisplayInterface
