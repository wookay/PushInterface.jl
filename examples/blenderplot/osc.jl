# julia -i osc.jl 

# (v0.7) pkg> add https://github.com/fundamental/OSC.jl#master


#=
* Requirements
  - [BlenderPlot.jl](https://github.com/wookay/BlenderPlot.jl)

* Run OSC Server in Blender Julia Console

@pyimport osc
serv = osc.Server("bpy")
serv.start(5005)
# serv.stop()      # stop it to quit Blender gracefully

=#

using Sockets, OSC
function send_osc(oscmsg, port=5005)
    udp = UDPSocket()
    send(udp, ip"127.0.0.1", port, oscmsg.data)
end

function handle_knob(msg)
    println("handle_knob ", msg)
    if length(msg) >= 3
        oscmsg = OscMsg("/knob", "ii", Int32(msg[2]), Int32(msg[3]))
        send_osc(oscmsg)
    end
end

import PushInterface: RTMIDI
import .RTMIDI: rtmidi_in_create_default, rtmidi_open_port, rtmidi_in_set_callback
import .RTMIDI: destroy, EventCB, rtmidi_callback_func

device = rtmidi_in_create_default()
rtmidi_open_port(device, 1, "Ableton Push 2 User Port")

cb_ptr = @cfunction rtmidi_callback_func Cvoid (Cdouble, Ptr{Cuchar}, Ptr{EventCB})
cond = Base.AsyncCondition()
handle = Base.unsafe_convert(Ptr{Cvoid}, cond)
ecb = EventCB(handle, 0, C_NULL)
r_ecb = Ref(ecb)
rtmidi_in_set_callback(device, cb_ptr, r_ecb)
finalizer(destroy, device)

function _callback_async_loop(cond, r_ecb)
    while isopen(cond)
        wait(cond)
        msg = codeunits(unsafe_string(r_ecb[].message))
        handle_knob(msg)
    end
end

cbloop = Task() do
    _callback_async_loop(cond, r_ecb)
end
schedule(cbloop)
