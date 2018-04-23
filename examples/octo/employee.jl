import PushInterface: RTMIDI
import .RTMIDI: rtmidi_in_create_default, rtmidi_open_port, rtmidi_in_set_callback, rtmidi_in_cancel_callback
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


module OctoStuff

using Octo.Adapters.PostgreSQL
Repo.debug_sql()
Repo.connect(
           adapter = Octo.Adapters.PostgreSQL,
           dbname = "postgresqltest",
           user = "postgres",
       )
Repo.execute([DROP TABLE IF EXISTS :Employee])
Repo.execute(Raw("""
           CREATE TABLE Employee (
               ID SERIAL,
               Name VARCHAR(255),
               Salary FLOAT(8),
               PRIMARY KEY (ID)
           )"""))

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

function midi_callback(msg)
    @info :msg repr(msg)
    if 0x90 == first(msg)
        name = rand(["Jeremy", "Cloris", "John", "Hyunden", "Justin", "Tom"])
        Repo.insert!(Employee, (Name=name,  Salary=10000.50))
    end
end

Repo.query(Employee)

end # module OctoStuff

import .OctoStuff: midi_callback

function _callback_async_loop(cond, r_ecb)
    while isopen(cond)
        try
            wait(cond)
            msg = codeunits(unsafe_string(r_ecb[].message))
            midi_callback(msg)
        end
    end
end

cbloop = Task() do
    _callback_async_loop(cond, r_ecb)
end
schedule(cbloop)


#=
midi_callback(msg) = @info :EDIT repr(msg)

rtmidi_in_cancel_callback(device)
close(cond)
istaskdone(cbloop) # true
cond = Base.AsyncCondition()
handle = Base.unsafe_convert(Ptr{Cvoid}, cond)
ecb = EventCB(handle, 0, C_NULL)
r_ecb = Ref(ecb)
rtmidi_in_set_callback(device, cb_ptr, r_ecb)
cbloop = Task() do
    _callback_async_loop(cond, r_ecb)
end
schedule(cbloop)
=#
