import PushInterface: RTMIDI
import .RTMIDI: rtmidi_in_create_default, rtmidi_open_port, rtmidi_in_set_callback
import .RTMIDI: RtMidiPtr, RtMidiWrapper, rtmidi_lib
import .RTMIDI: destroy, EventCB, cb_func

device = rtmidi_in_create_default()
rtmidi_open_port(device, 1, "Ableton Push 2 User Port")

cb_ptr = @cfunction cb_func Cvoid (Cdouble, Ptr{Cuchar}, Ptr{EventCB})
cond = Base.AsyncCondition()
handle = Base.unsafe_convert(Ptr{Cvoid}, cond)
ecb = EventCB(handle, 0, C_NULL)
r_ecb = Ref(ecb)
rtmidi_in_set_callback(device, cb_ptr, r_ecb)
finalizer(destroy, device)

function _callback_async_loop(cond, r_ecb)
    while isopen(cond)
        wait(cond)
        s = codeunits(unsafe_string(r_ecb[].message))
        println("message ", s)
    end
end

cbloop = Task() do
    _callback_async_loop(cond, r_ecb)
end
schedule(cbloop)
