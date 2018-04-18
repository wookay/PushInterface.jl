import PushInterface: RTMIDI
import .RTMIDI: rtmidi_out_create_default, rtmidi_open_port, rtmidi_out_send_message

device = rtmidi_out_create_default()
rtmidi_open_port(device, 1, "Ableton Push 2 User Port")

function set_led(msg)
    message = [0xF0, 0x00, 0x21, 0x1D, 0x01, 0x01, msg..., 0xF7]
    rtmidi_out_send_message(device, pointer(message), length(message))
end

# 10010000 00100100 01111110
# 0x90 0x24 0x7E
# set the bottom left pad RGB LED to green
msg = [0x90, 0x24, 0x7E]
set_led(msg)
