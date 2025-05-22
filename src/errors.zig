pub const MacAddressError = error{
    /// An error occurred while interfacing with the operating system
    OsError,

    /// No valid devices found
    NoDevice,
};
