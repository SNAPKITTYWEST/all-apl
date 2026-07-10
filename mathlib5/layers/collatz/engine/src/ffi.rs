//! Collatz Engine — C FFI Layer
//! Exposes parallel trajectory search and WORM sealing to C99/Fortran

use std::ffi::CString;
use std::os::raw::c_char;
use std::ptr;

use crate::{compute_trajectory, parallel_search, compute_merkle_root, seal_to_worm, WormEntry};

/// Compute a single Collatz trajectory. Returns 0 on success.
#[no_mangle]
pub extern "C" fn collatz_compute(
    start: u64,
    out_length: *mut u64,
    out_max_value: *mut u64,
    out_steps: *mut u64,
) -> i32 {
    if out_length.is_null() || out_max_value.is_null() || out_steps.is_null() {
        return -1;
    }
    match compute_trajectory(start) {
        Some(t) => {
            unsafe {
                *out_length = t.length;
                *out_max_value = t.max_value;
                *out_steps = t.steps.len() as u64;
            }
            0
        }
        None => -1,
    }
}

/// Parallel search across range [start, end). Returns number of trajectories found.
#[no_mangle]
pub extern "C" fn collatz_parallel_search(
    start: u64,
    end: u64,
    out_count: *mut u64,
    out_max_length: *mut u64,
    out_max_length_start: *mut u64,
    out_max_value: *mut u64,
    out_max_value_start: *mut u64,
) -> i32 {
    if out_count.is_null() || out_max_length.is_null() || out_max_value.is_null() {
        return -1;
    }
    let trajectories = parallel_search(start, end);
    unsafe {
        *out_count = trajectories.len() as u64;
        if let Some(max_len) = trajectories.iter().max_by_key(|t| t.length) {
            *out_max_length = max_len.length;
            *out_max_length_start = max_len.start;
        }
        if let Some(max_val) = trajectories.iter().max_by_key(|t| t.max_value) {
            *out_max_value = max_val.max_value;
            *out_max_value_start = max_val.start;
        }
    }
    0
}

/// Compute Merkle root from range of trajectories (caller frees with collatz_string_free).
#[no_mangle]
pub extern "C" fn collatz_merkle_root(start: u64, end: u64) -> *mut c_char {
    let trajectories = parallel_search(start, end);
    let root = compute_merkle_root(&trajectories);
    match CString::new(root) {
        Ok(s) => s.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// Seal a range of trajectories to WORM ledger. Returns number sealed.
#[no_mangle]
pub extern "C" fn collatz_seal_range(
    start: u64,
    end: u64,
    out_entries: *mut *mut u64,
    out_count: *mut u64,
) -> i32 {
    if out_entries.is_null() || out_count.is_null() {
        return -1;
    }
    let trajectories = parallel_search(start, end);
    let merkle_root = compute_merkle_root(&trajectories);
    let entries: Vec<WormEntry> = trajectories.iter()
        .map(|t| seal_to_worm(t, &merkle_root))
        .collect();
    unsafe {
        *out_count = entries.len() as u64;
    }
    0
}

/// Free a string returned by collatz functions
#[no_mangle]
pub extern "C" fn collatz_string_free(s: *mut c_char) {
    if !s.is_null() {
        unsafe { drop(CString::from_raw(s)); }
    }
}
