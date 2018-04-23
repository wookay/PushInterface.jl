module LIBUSB

include("../deps/deps.jl")

const LibusbContext = Cvoid
const LibusbDevice = Cvoid
const LibusbDeviceHandle = Cvoid
const LibusbTransferCbFn = Cvoid

const LIBUSB_LOG_LEVEL_ERROR = Cint(1)
const LIBUSB_LOG_LEVEL_DEBUG = Cint(4)

const LIBUSB_SUCCESS = Cint(0)

const Cuint8  = UInt8
const Cuint16 = UInt16

struct LibusbDeviceDescriptor
    bLength::Cuint8            # Size of this descriptor (in bytes)
    bDescriptorType::Cuint8    # Descriptor type. Will have value \ref libusb_descriptor_type::LIBUSB_DT_DEVICE LIBUSB_DT_DEVICE in this context.
    bcdUSB::Cuint16            # USB specification release number in binary-coded decimal. A value of 0x0200 indicates USB 2.0, 0x0110 indicates USB 1.1, etc.
    bDeviceClass::Cuint8       # USB-IF class code for the device. See \ref libusb_class_code.
    bDeviceSubClass::Cuint8    # USB-IF subclass code for the device, qualified by the bDeviceClass value
    bDeviceProtocol::Cuint8    # USB-IF protocol code for the device, qualified by the bDeviceClass and bDeviceSubClass values
    bMaxPacketSize0::Cuint8    # Maximum packet size for endpoint 0
    idVendor::Cuint16          # USB-IF vendor ID
    idProduct::Cuint16         # USB-IF product ID
    bcdDevice::Cuint16         # Device release number in binary-coded decimal
    iManufacturer::Cuint8      # Index of string descriptor describing manufacturer
    iProduct::Cuint8           # Index of string descriptor describing product
    iSerialNumber::Cuint8      # Index of string descriptor containing device serial number
    bNumConfigurations::Cuint8 # Number of possible configurations
end

const LibusbTransferStatus = Cint # enum
# 0 LIBUSB_TRANSFER_COMPLETED
# 1 LIBUSB_TRANSFER_ERROR
# 2 LIBUSB_TRANSFER_TIMED_OUT
# 3 LIBUSB_TRANSFER_CANCELLED
# 4 LIBUSB_TRANSFER_STALL
# 5 LIBUSB_TRANSFER_NO_DEVICE
# 6 LIBUSB_TRANSFER_OVERFLOW

struct LibusbIsoPacketDescriptor
    length::Cuint # Length of data to request in this packet
    actual_length::Cuint # Amount of data that was actually transferred
    status::LibusbTransferStatus # Status code for this packet
end

mutable struct LibusbTransfer
    dev_handle::Ptr{LibusbDeviceHandle} # Handle of the device that this transfer will be submitted to
    flags::Cuint8 # A bitwise OR combination of \ref libusb_transfer_flags.
    endpoint::Cuchar # Address of the endpoint where this transfer will be sent.
    typ::Cuchar # Type of the endpoint from \ref libusb_transfer_type
    timeout::Cuint # Timeout for this transfer in milliseconds. A value of 0 indicates no timeout.
    status::LibusbTransferStatus
    #= The status of the transfer. Read-only, and only for use within
       transfer callback function.
       If this is an isochronous transfer, this field may read COMPLETED even
       if there were errors in the frames. Use the
       \ref libusb_iso_packet_descriptor::status "status" field in each packet
       to determine if errors occurred. =#
    length::Cint # Length of the data buffer
    actual_length::Cint
    #= Actual length of data that was transferred. Read-only, and only for
       use within transfer callback function. Not valid for isochronous
       endpoint transfers. =#
    callback::Ptr{LibusbTransferCbFn} # Callback function. This will be invoked when the transfer completes, fails, or is cancelled.
    user_data::Ptr{Cvoid} # User context data to pass to the callback function.
    buffer::Ptr{Cuchar} # Data buffer
    num_iso_packets::Cint # Number of isochronous packets. Only used for I/O with isochronous endpoints.
    iso_packet_desc::LibusbIsoPacketDescriptor # Isochronous packet descriptors, for isochronous transfers only.
end

# int LIBUSB_CALL libusb_init(libusb_context **ctx)
function libusb_init(ctx::Ptr{Ptr{LibusbContext}})
    ccall((:libusb_init, libusb), Cint, (Ptr{Ptr{LibusbContext}},), ctx)
end

# libusb_device_handle * LIBUSB_CALL libusb_open_device_with_vid_pid(libusb_context *ctx, uint16_t vendor_id, uint16_t product_id)
function libusb_open_device_with_vid_pid(ctx::Ptr{LibusbContext}, vendor_id::Cuint16, product_id::Cuint16)::Ptr{LibusbDeviceHandle}
    ccall((:libusb_open_device_with_vid_pid, libusb), Ptr{LibusbDeviceHandle}, (Ptr{LibusbContext}, Cuint16, Cuint16), ctx, vendor_id, product_id)
end

# void LIBUSB_CALL libusb_set_debug(libusb_context *ctx, int level)
function libusb_set_debug(ctx::Ptr{LibusbContext}, level::Cint)
    ccall((:libusb_set_debug, libusb), Cvoid, (Ptr{LibusbContext}, Cint), ctx, level)
end

# const char * LIBUSB_CALL libusb_error_name(int errcode)
function libusb_error_name(errcode::Cint)
    error_name = ccall((:libusb_error_name, libusb), Cstring, (Cint,), errcode)
    unsafe_string(error_name)
end

# libusb_device * LIBUSB_CALL libusb_get_device(libusb_device_handle *dev_handle)
function libusb_get_device(dev_handle::Ptr{LibusbDeviceHandle})
    ccall((:libusb_get_device, libusb), Ptr{LibusbDevice}, (Ptr{LibusbDeviceHandle},), dev_handle)
end

# int LIBUSB_CALL libusb_open(libusb_device *dev, libusb_device_handle **dev_handle)
function libusb_open(dev::Ptr{LibusbDevice}, dev_handle::Ptr{Ptr{LibusbDeviceHandle}})
    ccall((:libusb_open, libusb), Cint, (Ptr{LibusbDevice}, Ptr{Ptr{LibusbDeviceHandle}}), dev, dev_handle)
end

# int LIBUSB_CALL libusb_kernel_driver_active(libusb_device_handle *dev_handle, int interface_number)
function libusb_kernel_driver_active(dev_handle::Ptr{LibusbDeviceHandle}, interface_number::Cint)
    ccall((:libusb_kernel_driver_active, libusb), Cint, (Ptr{LibusbDeviceHandle}, Cint), dev_handle, interface_number)
end

# int LIBUSB_CALL libusb_detach_kernel_driver(libusb_device_handle *dev_handle, int interface_number)
function libusb_detach_kernel_driver(dev_handle::Ptr{LibusbDeviceHandle}, interface_number::Cint)
    ccall((:libusb_detach_kernel_driver, libusb), Cint, (Ptr{LibusbDeviceHandle}, Cint), dev_handle, interface_number)
end

# int LIBUSB_CALL libusb_claim_interface(libusb_device_handle *dev_handle, int interface_number)
function libusb_claim_interface(dev_handle::Ptr{LibusbDeviceHandle}, interface_number::Cint)
    ccall((:libusb_claim_interface, libusb), Cint, (Ptr{LibusbDeviceHandle}, Cint), dev_handle, interface_number)
end

# int LIBUSB_CALL libusb_release_interface(libusb_device_handle *dev_handle, int interface_number)
function libusb_release_interface(dev_handle::Ptr{LibusbDeviceHandle}, interface_number::Cint)
    ccall((:libusb_release_interface, libusb), Cint, (Ptr{LibusbDeviceHandle}, Cint), dev_handle, interface_number)
end

# void LIBUSB_CALL libusb_close(libusb_device_handle *dev_handle)
function libusb_close(dev_handle::Ptr{LibusbDeviceHandle})
    ccall((:libusb_close, libusb), Cvoid, (Ptr{LibusbDeviceHandle},), dev_handle)
end

# int LIBUSB_CALL libusb_get_device_descriptor(libusb_device *dev, struct libusb_device_descriptor *desc)
function libusb_get_device_descriptor(dev::Ptr{LibusbDevice}, desc::Ref{Ptr{LibusbDeviceDescriptor}})
    ccall((:libusb_get_device_descriptor, libusb), Cint, (Ptr{LibusbDevice}, Ptr{Ptr{LibusbDeviceDescriptor}}), dev, desc)
end

# struct libusb_transfer * LIBUSB_CALL libusb_alloc_transfer(int iso_packets)
function libusb_alloc_transfer(iso_packets::Cint)
    ccall((:libusb_alloc_transfer, libusb), Ptr{LibusbTransfer}, (Cint,), iso_packets)
end

# int LIBUSB_CALL libusb_submit_transfer(struct libusb_transfer *transfer)
function libusb_submit_transfer(transfer::Ptr{LibusbTransfer})
    ccall((:libusb_submit_transfer, libusb), Cint, (Ptr{LibusbTransfer},), transfer)
end

# int LIBUSB_CALL libusb_cancel_transfer(struct libusb_transfer *transfer)
function libusb_cancel_transfer(transfer::Ptr{LibusbTransfer})
    ccall((:libusb_cancel_transfer, libusb), Cint, (Ptr{LibusbTransfer},), transfer)
end

# void LIBUSB_CALL libusb_free_transfer(struct libusb_transfer *transfer)
function libusb_free_transfer(transfer::Ptr{LibusbTransfer})
    ccall((:libusb_free_transfer, libusb), Cvoid, (Ptr{LibusbTransfer},), transfer)
end

# int LIBUSB_CALL libusb_handle_events_completed(libusb_context *ctx, int *completed);
function libusb_handle_events_completed(ctx::Ptr{LibusbContext}, completed::Ptr{Cint})
    ccall((:libusb_handle_events_completed, libusb), Cint, (Ptr{LibusbContext}, Ptr{Cint}), ctx, completed)
end

const LIBUSB_TRANSFER_TYPE_BULK = Cuchar(2)

# static inline void libusb_fill_bulk_transfer(struct libusb_transfer *transfer, libusb_device_handle *dev_handle, unsigned char endpoint, unsigned char *buffer, int length, libusb_transfer_cb_fn callback, void *user_data, unsigned int timeout)
function libusb_fill_bulk_transfer(transfer::Ptr{LibusbTransfer}, dev_handle::Ptr{LibusbDeviceHandle}, endpoint::Cuchar, buffer::Ptr{Cuchar}, length::Int, callback::Ptr{LibusbTransferCbFn}, user_data::Ptr{Cvoid}, timeout::Cuint)
    t = unsafe_load(transfer)
    t.dev_handle = dev_handle
    t.endpoint = endpoint
    t.typ = LIBUSB_TRANSFER_TYPE_BULK
    t.timeout = timeout
    t.buffer = buffer
    t.length = length
    t.user_data = user_data
    t.callback = callback
    unsafe_store!(transfer, t)
end

end # module LIBUSB
