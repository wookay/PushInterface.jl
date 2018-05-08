using Cairo
using Test

# CairoSurface
#     ptr::Ptr{Nothing}
#     width::Float64
#     height::Float64
#     data::Matrix{T}

c = CairoARGBSurface(160, 90)
@test c isa CairoSurface{UInt32}

ctx = CairoContext(c)
@test ctx isa CairoContext
