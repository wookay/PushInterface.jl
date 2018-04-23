import PushInterface: LIBUSB
import .LIBUSB: libusb_init, libusb_set_debug, libusb_open_device_with_vid_pid, libusb_get_device, libusb_get_device_descriptor, libusb_kernel_driver_active, libusb_detach_kernel_driver, libusb_claim_interface, libusb_error_name, libusb_alloc_transfer, libusb_fill_bulk_transfer, libusb_submit_transfer, libusb_cancel_transfer, libusb_handle_events_completed, libusb_free_transfer, libusb_release_interface, libusb_close
import .LIBUSB: LibusbContext, LibusbDeviceDescriptor, LibusbTransfer # Ptr
import .LIBUSB: LIBUSB_LOG_LEVEL_DEBUG, LIBUSB_SUCCESS

const ABLETON_VENDOR_ID = 0x2982
const PUSH2_PRODUCT_ID  = 0x1967

ctx = Ptr{LibusbContext}(C_NULL)
init_result = libusb_init(Ptr{Ptr{LibusbContext}}(ctx))
libusb_set_debug(ctx, LIBUSB_LOG_LEVEL_DEBUG)
device_handle = libusb_open_device_with_vid_pid(ctx, ABLETON_VENDOR_ID, PUSH2_PRODUCT_ID)
device = libusb_get_device(device_handle)
descriptor = Ref{Ptr{LibusbDeviceDescriptor}}()
libusb_get_device_descriptor(device, descriptor)
# @info :descriptor_bDeviceClass descriptor[].bDeviceClass # 0 LIBUSB_CLASS_PER_INTERFACE
# @info :descriptor_idVendor     descriptor[].idVendor
# @info :descriptor_idProduct    descriptor[].idProduct

interface_number = Cint(0)

# 0 no kernel driver is active
# 1 if a kernel driver is active
kernel_driver_is_active = libusb_kernel_driver_active(device_handle, interface_number) == 1
if kernel_driver_is_active
    detach_result = libusb_detach_kernel_driver(device_handle, interface_number)
    @info :detach_result detach_result
end

claim_result = libusb_claim_interface(device_handle, interface_number)
if claim_result != LIBUSB_SUCCESS
    @info :claim_result libusb_error_name(claim_result)
end

iso_packets = Cint(0)
frame_header_transfer = libusb_alloc_transfer(iso_packets)
C_NULL == frame_header_transfer && @error "could not allocate frame header transfer handle"

frame_header = [
  0xff, 0xcc, 0xaa, 0x88,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00]

const PUSH2_BULK_EP_OUT = Cuchar(0x01)
const TRANSFER_TIMEOUT  = Cuint(1000) # milliseconds

function libusb_transfer_cb(transfer::Ptr{LibusbTransfer})
    t = unsafe_load(transfer)
    @info :libusb_transfer_cb t.callback t.user_data
end
on_frame_header_transfer_finished = @cfunction libusb_transfer_cb Cvoid (Ptr{LibusbTransfer},)

libusb_fill_bulk_transfer(
    frame_header_transfer,
    device_handle,
    PUSH2_BULK_EP_OUT,
    pointer(frame_header),
    length(frame_header),
    on_frame_header_transfer_finished,
    C_NULL,
    TRANSFER_TIMEOUT)

transfer_result = libusb_submit_transfer(frame_header_transfer)
if transfer_result != LIBUSB_SUCCESS
    @info :transfer_result transfer_result
end

libusb_cancel_transfer(frame_header_transfer)
completed = Ptr{Cint}(C_NULL)
events_completed_result = libusb_handle_events_completed(ctx, completed)
if events_completed_result != LIBUSB_SUCCESS
    @info :events_completed_result events_completed_result completed
end
libusb_free_transfer(frame_header_transfer)
libusb_release_interface(device_handle, interface_number)
libusb_close(device_handle)
