//! PRISM Skills — C FFI Layer
//! Exposes canonical serialization, SHA-256d hashing, and WORM sealing to C99/Fortran

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

use crate::canonical::canonical_bytes;
use crate::sha256d::{hash_bytes, hash_string, hash_double, snapsha256d};
use crate::seal::WormSeal;

/// Compute canonical JSON bytes from a JSON string.
/// Returns canonical form with sorted keys (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_canonicalize(json_str: *const c_char) -> *mut c_char {
    if json_str.is_null() { return ptr::null_mut(); }
    unsafe {
        let cstr = CStr::from_ptr(json_str);
        match cstr.to_str() {
            Ok(s) => match serde_json::from_str::<serde_json::Value>(s) {
                Ok(val) => {
                    let bytes = canonical_bytes(&val);
                    match String::from_utf8(bytes) {
                        Ok(canonical) => match CString::new(canonical) {
                            Ok(cs) => cs.into_raw(),
                            Err(_) => ptr::null_mut(),
                        },
                        Err(_) => ptr::null_mut(),
                    }
                }
                Err(_) => ptr::null_mut(),
            },
            Err(_) => ptr::null_mut(),
        }
    }
}

/// SHA-256 hash of bytes (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_hash_bytes(data: *const u8, len: usize) -> *mut c_char {
    if data.is_null() || len == 0 { return ptr::null_mut(); }
    unsafe {
        let slice = std::slice::from_raw_parts(data, len);
        let hash = hash_bytes(slice);
        match CString::new(hash) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// SHA-256 hash of a string (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_hash_string(s: *const c_char) -> *mut c_char {
    if s.is_null() { return ptr::null_mut(); }
    unsafe {
        match CStr::from_ptr(s).to_str() {
            Ok(rust_str) => {
                let hash = hash_string(rust_str);
                match CString::new(hash) {
                    Ok(cs) => cs.into_raw(),
                    Err(_) => ptr::null_mut(),
                }
            }
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Double SHA-256 hash (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_hash_double(data: *const u8, len: usize) -> *mut c_char {
    if data.is_null() || len == 0 { return ptr::null_mut(); }
    unsafe {
        let slice = std::slice::from_raw_parts(data, len);
        let hash = hash_double(slice);
        match CString::new(hash) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// SnapSHA-256d label (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_snapsha256d(data: *const u8, len: usize) -> *mut c_char {
    if data.is_null() || len == 0 { return ptr::null_mut(); }
    unsafe {
        let slice = std::slice::from_raw_parts(data, len);
        let label = snapsha256d(slice);
        match CString::new(label) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Create a WORM seal. Returns opaque pointer (caller frees with prism_seal_free).
#[no_mangle]
pub extern "C" fn prism_seal_new(
    label: *const c_char,
    payload: *const c_char,
    steps: u64,
) -> *mut WormSeal {
    if label.is_null() || payload.is_null() { return ptr::null_mut(); }
    unsafe {
        let l = match CStr::from_ptr(label).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let p = match CStr::from_ptr(payload).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let seal = WormSeal::seal(l, p, steps);
        Box::into_raw(Box::new(seal))
    }
}

/// Verify a WORM seal. Returns 1 if valid.
#[no_mangle]
pub extern "C" fn prism_seal_verify(seal: *const WormSeal) -> i32 {
    if seal.is_null() { return 0; }
    unsafe { if (*seal).verify() { 1 } else { 0 } }
}

/// Get seal hash (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_seal_hash(seal: *const WormSeal) -> *mut c_char {
    if seal.is_null() { return ptr::null_mut(); }
    unsafe {
        match CString::new((*seal).seal_hash.clone()) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Get seal artifact name (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_seal_artifact(seal: *const WormSeal) -> *mut c_char {
    if seal.is_null() { return ptr::null_mut(); }
    unsafe {
        match CString::new((*seal).artifact.clone()) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Get content hash (caller frees with prism_string_free).
#[no_mangle]
pub extern "C" fn prism_seal_content_hash(seal: *const WormSeal) -> *mut c_char {
    if seal.is_null() { return ptr::null_mut(); }
    unsafe {
        match CString::new((*seal).content_hash()) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Free a WORM seal
#[no_mangle]
pub extern "C" fn prism_seal_free(seal: *mut WormSeal) {
    if !seal.is_null() {
        unsafe { drop(Box::from_raw(seal)); }
    }
}

/// Free a string returned by prism functions
#[no_mangle]
pub extern "C" fn prism_string_free(s: *mut c_char) {
    if !s.is_null() {
        unsafe { drop(CString::from_raw(s)); }
    }
}
