module DisplayInterface # PushInterface

# https://github.com/Ableton/push-interface/blob/master/doc/AbletonPush2MIDIDisplayInterface.asc#3-display-interface

const DisplayPixelWidth      = 960
const DisplayPixelHeight     = 160

const DataSourceWidth        = 1024                       #  960+64
const LineSize               = 2DataSourceWidth           #  2 * (960+64)

const LineCountPerSendBuffer = Int(DisplayPixelHeight/1)  #  160
const SendBufferSize         = LineCountPerSendBuffer * LineSize

include("DisplayInterface/Canvas.jl")
include("DisplayInterface/framebuffer.jl")

end # module PushInterface.DisplayInterface
