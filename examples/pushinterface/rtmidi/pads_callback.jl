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
        println("message ", msg)
    end
end

cbloop = Task() do
    _callback_async_loop(cond, r_ecb)
end
schedule(cbloop)
