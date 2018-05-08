# julia -i transfer_image.jl

import PushInterface: LIBUSB, DisplayInterface
import .LIBUSB: libusb_init, libusb_set_debug, libusb_open_device_with_vid_pid, libusb_get_device, libusb_get_device_descriptor, libusb_kernel_driver_active, libusb_detach_kernel_driver, libusb_claim_interface, libusb_error_name, libusb_alloc_transfer, libusb_fill_bulk_transfer, libusb_submit_transfer, libusb_cancel_transfer, libusb_handle_events_completed, libusb_handle_events_timeout_completed, libusb_free_transfer, libusb_release_interface, libusb_close, libusb_exit, libusb_reset_device
import .LIBUSB: LibusbContext, LibusbDeviceDescriptor, LibusbTransfer, Ctimeval # Ptr
import .LIBUSB: LIBUSB_LOG_LEVEL_DEBUG, LIBUSB_SUCCESS, LIBUSB_TRANSFER_COMPLETED

const ABLETON_VENDOR_ID = 0x2982
const PUSH2_PRODUCT_ID  = 0x1967

ctx = Ptr{LibusbContext}(C_NULL)
init_result = libusb_init(Ptr{Ptr{LibusbContext}}(ctx))
# libusb_set_debug(ctx, LIBUSB_LOG_LEVEL_DEBUG)
device_handle = libusb_open_device_with_vid_pid(ctx, ABLETON_VENDOR_ID, PUSH2_PRODUCT_ID)
if C_NULL == device_handle
    @error :libusb_open_device_with_vid_pid "could not found ableton push 2"
    exit(1)
end
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


frame_header = [
  0xff, 0xcc, 0xaa, 0x88,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00]

const PUSH2_BULK_EP_OUT = Cuchar(0x01)
const TRANSFER_TIMEOUT  = Cuint(1000) # milliseconds

function libusb_frame_header_transfer_cb(transfer::Ptr{LibusbTransfer})
end
libusb_frame_header_transfer_callback = @cfunction libusb_frame_header_transfer_cb Cvoid (Ptr{LibusbTransfer},)

function on_transfer_finished
end

function libusb_pixel_data_transfer_cb(transfer::Ptr{LibusbTransfer})
    t = unsafe_load(transfer)
    if t.status != LIBUSB_TRANSFER_COMPLETED
    elseif t.length != t.actual_length
    else
        # @info :libusb_pixel_data_transfer_cb transfer
        on_transfer_finished(transfer)
    end
    nothing
end
libusb_pixel_data_transfer_callback = @cfunction libusb_pixel_data_transfer_cb Cvoid (Ptr{LibusbTransfer},)

iso_packets = Cint(0)
frame_header_transfer = libusb_alloc_transfer(iso_packets)
    libusb_fill_bulk_transfer(
        frame_header_transfer,
        device_handle,
        PUSH2_BULK_EP_OUT,
        pointer(frame_header),
        length(frame_header),
        libusb_frame_header_transfer_callback,
        C_NULL,
        TRANSFER_TIMEOUT)

    iso_packets = Cint(0)
    pixel_data_transfer = libusb_alloc_transfer(iso_packets)

function submit_buffers(row_idx, buffer)
    if 1 == row_idx
        frame_header_transfer_result = libusb_submit_transfer(frame_header_transfer)
        if frame_header_transfer_result != LIBUSB_SUCCESS
            @info :frame_header_transfer_result frame_header_transfer_result
        end
    end
     
    libusb_fill_bulk_transfer(
        pixel_data_transfer,
        device_handle,
        PUSH2_BULK_EP_OUT,
        pointer(buffer),
        length(buffer),
        libusb_pixel_data_transfer_callback,
        C_NULL,
        TRANSFER_TIMEOUT);
    pixel_data_transfer_result = libusb_submit_transfer(pixel_data_transfer)
    if pixel_data_transfer_result != LIBUSB_SUCCESS
        @info :pixel_data_transfer_result pixel_data_transfer_result
    end
end

function close_device()
    libusb_cancel_transfer(frame_header_transfer)
    libusb_cancel_transfer(pixel_data_transfer)
    libusb_free_transfer(frame_header_transfer)
    libusb_free_transfer(pixel_data_transfer)
    libusb_release_interface(device_handle, interface_number)
    libusb_reset_device(device_handle)
    C_NULL != ctx && libusb_close(device_handle)
    libusb_exit(ctx)
end

const counting_the_callback_to_close = true
const callback_count_limit = 5
callback_count = 1
function periodic_callback(timer)
    completed = Ptr{Cint}(C_NULL)
    tv = Ref(Ctimeval(0, 500000))
    events_completed_result = libusb_handle_events_timeout_completed(ctx, tv, completed)
    if events_completed_result != LIBUSB_SUCCESS
        @info :events_completed_result events_completed_result completed
    end
    if counting_the_callback_to_close
        global callback_count
        if callback_count_limit < callback_count
            # @info :close_timer
            close(timer)
            close_device()
        end
        callback_count += 1
    end
end

import .DisplayInterface: Canvas, fill!, draw!
import .DisplayInterface: framebuffer
import .DisplayInterface: DisplayPixelHeight, LineCountPerSendBuffer, SendBufferSize
import Colors: @colorant_str
using Pkg

path = joinpath(Pkg.dir("PushInterface"), "examples/pushinterface/usb", "logo.png")

canvas = Canvas()
fill!(canvas, colorant"white") # @colorant_str
draw!(canvas, path)

const buf = framebuffer(canvas)
row_idx = 1

const line_count = Int(DisplayPixelHeight/LineCountPerSendBuffer)
function on_transfer_finished(transfer)
    global row_idx
    buffer = buf[SendBufferSize*(row_idx-1)+1:SendBufferSize*row_idx]
    submit_buffers(row_idx, buffer)
    if row_idx == line_count
        row_idx = 1
    else
        row_idx +=1 
    end
end

on_transfer_finished(nothing)

t = Timer(periodic_callback, 0, interval = 0.5) # Timer(callback::Function, delay; interval)
finalizer(t) do timer
end
