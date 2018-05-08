

x = 1
y = 1
z = 1





# MIDI Mapping
# https://github.com/Ableton/push-interface/blob/master/doc/AbletonPush2MIDIDisplayInterface.asc#23-midi-mapping
function midi_event(msg)
    global x, y, z
    if 0xb0 == first(msg) # knobs
        length(msg) < 3 && return
        knob = msg[2]
        val = 0x7f == msg[3] ? -1 : 1
        if 0x47 == knob     # knob 1
            x += val
        elseif 0x48 == knob # knob 2
            y += val
        elseif 0x49 == knob # knob 3
            z += val
        end
        Atom.msg("updateWorkspace")
    end
end


function midi_callback(msg)
    # @info :midi_callback msg
    midi_event(msg)
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
        midi_callback(msg)
    end
end

cbloop = Task() do
    _callback_async_loop(cond, r_ecb)
end
schedule(cbloop)
