# module PushInterface.DisplayInterface

# The display uses 16 bit per pixels in a 5:6:5 format
#     MSB                             LSB
#       b b b b|b g g g|g g g r|r r r r

# reference: https://github.com/Ableton/push2-display-with-juce/blob/master/Source/push2/Push2-Bitmap.h#L75
function rgb_to_pixel(x, alpha::UInt8, r::UInt8, g::UInt8, b::UInt8)::Tuple{UInt8,UInt8}
    if alpha == 0x00
        r, g, b = UInt8.((0, 0, 0))
    else
        r, g, b = (x -> UInt8(UInt16(x) * 0xff / UInt16(alpha))).((r, g, b))
    end
    pixel = (UInt16(b) & 0xf8) >> 3
    pixel <<= 6
    pixel += (UInt16(g) & 0xFC) >> 2
    pixel <<= 5;
    pixel += (UInt16(r) & 0xF8) >> 3
    pixel = xor(iseven(x) ? 0xffe7 : 0xf3e7, pixel)
    h = UInt8(pixel & 0xff)
    l = UInt8(pixel >> 8)
    (h, l)
end

const FillerBytes = fill(0x00, 128)

function framebuffer(canvas::Canvas)
    data = ccall((:cairo_image_surface_get_data, _jl_libcairo), Ptr{Cuchar}, (Ptr{Cvoid},), canvas.surface.ptr)
    stride = ccall((:cairo_image_surface_get_stride, _jl_libcairo), Cint, (Ptr{Cvoid},), canvas.surface.ptr) # 3840
    componentsize = Int(stride/width(canvas.surface)) # a r g b
    pixeldata = reshape(unsafe_wrap(Array, data, stride*DisplayPixelHeight), (componentsize, DisplayPixelWidth, DisplayPixelHeight))
    buf = UInt8[]
    for y in 1:DisplayPixelHeight
        for x in 1:DisplayPixelWidth
            argb = reverse(pixeldata[:, x, y])
            (h, l) = rgb_to_pixel(x, argb...)
            push!(buf, h, l)
        end
        push!(buf, FillerBytes...)
    end
    buf
end

#import Cairo: write_to_png
#write_to_png(canvas.surface, "sample_line.png")

# module PushInterface.DisplayInterface
