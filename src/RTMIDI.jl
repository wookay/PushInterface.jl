module RTMIDI # PushInterface

include("../deps/deps.jl")

const RtMidiCCallback = Ptr{Cvoid} 
struct RtMidiInData
    c_callback::RtMidiCCallback
    user_data::Ptr{Cvoid}
end

struct RtMidiWrapper
    ptr::Ptr{Cvoid}
    data::Ptr{RtMidiInData}
    ok::Bool
    msg::Cstring
end
const RtMidiPtr = Ref{RtMidiWrapper}

function rtmidi_in_create_default()::RtMidiPtr
    ccall((:rtmidi_in_create_default, rtmidi_lib), RtMidiPtr, ())
end

function rtmidi_sizeof_rtmidi_api()::Int
    Int(ccall((:rtmidi_sizeof_rtmidi_api, rtmidi_lib), Cint, ()))
end

function rtmidi_get_port_count(device::RtMidiPtr)::Int
    Int(ccall((:rtmidi_get_port_count, rtmidi_lib), Cuint, (Ptr{Cvoid},), device))
end

function rtmidi_get_port_name(device::RtMidiPtr, portNumber)::String
    unsafe_string(ccall((:rtmidi_get_port_name, rtmidi_lib), Cstring, (Ptr{Cvoid}, Cuint), device, Cuint(portNumber)))
end

function rtmidi_open_port(device::RtMidiPtr, portNumber, portName)
    ccall((:rtmidi_open_port, rtmidi_lib), Cvoid, (RtMidiPtr, Cuint, Cstring), device, portNumber, portName)
end

function rtmidi_in_get_message(device::RtMidiPtr, message, size)
    ccall((:rtmidi_in_get_message, rtmidi_lib), Cdouble, (RtMidiPtr, Ptr{Cstring}, Ptr{Csize_t}), device, message, size)
end

function rtmidi_in_set_callback(device::RtMidiPtr, callback, data)
    ccall((:rtmidi_in_set_callback, rtmidi_lib), Cvoid, (RtMidiPtr, Ptr{Cvoid}, Ptr{Cvoid}), device, callback, data)
end

struct EventCB
    handle::Ptr{Cvoid}
    timeStamp::Cdouble
    message::Ptr{Cuchar}
end

function cb_func(timeStamp::Cdouble, message::Ptr{Cuchar}, ptr::Ptr{EventCB})::Cvoid
    handle = unsafe_load(ptr, 1).handle
    val = EventCB(handle, timeStamp, message)
    unsafe_store!(ptr, val, 1)
    ccall(:uv_async_send, Cvoid, (Ptr{Cvoid},), handle)
    nothing
end

function destroy(device::RtMidiPtr)
   ccall((:rtmidi_close_port, rtmidi_lib), Cvoid, (RtMidiPtr,), device)
end

end # module PushInterface.RTMIDI
