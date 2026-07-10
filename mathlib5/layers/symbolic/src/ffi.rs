use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

use crate::mathir::MathIR;
use crate::normalizer::Normalizer;
use crate::dispatcher::Dispatcher;
use crate::oracle;

#[no_mangle]
pub extern "C" fn mathlib5_normalize(json: *const c_char) -> *mut c_char {
    if json.is_null() { return ptr::null_mut(); }
    unsafe {
        let s = match CStr::from_ptr(json).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let expr = match serde_json::from_str::<MathIR>(s) { Ok(e) => e, Err(_) => return ptr::null_mut() };
        let n = Normalizer::new();
        let result = n.normalize(&expr);
        match CString::new(serde_json::to_string(&result).unwrap()) { Ok(c) => c.into_raw(), Err(_) => ptr::null_mut() }
    }
}

#[no_mangle]
pub extern "C" fn mathlib5_dispatch(kind: *const c_char) -> *mut c_char {
    if kind.is_null() { return ptr::null_mut(); }
    unsafe {
        let k = match CStr::from_ptr(kind).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let d = Dispatcher::new();
        let result = d.dispatch(k);
        match CString::new(serde_json::to_string(&result).unwrap()) { Ok(c) => c.into_raw(), Err(_) => ptr::null_mut() }
    }
}

#[no_mangle]
pub extern "C" fn mathlib5_verify_proof(proof: *const c_char) -> i32 {
    if proof.is_null() { return 0; }
    unsafe {
        let s = match CStr::from_ptr(proof).to_str() { Ok(s) => s, Err(_) => return 0 };
        if oracle::prolog_fallback(s) { 1 } else { 0 }
    }
}

#[no_mangle]
pub extern "C" fn mathlib5_parse_oracle(text: *const c_char) -> *mut c_char {
    if text.is_null() { return ptr::null_mut(); }
    unsafe {
        let s = match CStr::from_ptr(text).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        match oracle::parse_boolean_output(s) {
            Ok(o) => match CString::new(serde_json::to_string(&o).unwrap()) { Ok(c) => c.into_raw(), Err(_) => ptr::null_mut() },
            Err(e) => match CString::new(e) { Ok(c) => c.into_raw(), Err(_) => ptr::null_mut() },
        }
    }
}

#[no_mangle]
pub extern "C" fn mathlib5_receipt_hash(status: *const c_char, proof: *const c_char) -> *mut c_char {
    if status.is_null() || proof.is_null() { return ptr::null_mut(); }
    unsafe {
        let st = match CStr::from_ptr(status).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let pr = match CStr::from_ptr(proof).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let h = oracle::make_receipt_hash(st, pr);
        match CString::new(h) { Ok(c) => c.into_raw(), Err(_) => ptr::null_mut() }
    }
}

#[no_mangle]
pub extern "C" fn mathlib5_string_free(s: *mut c_char) {
    if !s.is_null() { unsafe { drop(CString::from_raw(s)); } }
}

// ============================================================
// C-- Kernel FFI Functions for SorryHunter
// ============================================================

/// Sum of squares: ∑_{k=1}^n k² = n(n+1)(2n+1)/6
#[no_mangle]
pub extern "C" fn mathlib5_sum_squares(n: u64) -> u64 {
    n * (n + 1) * (2 * n + 1) / 6
}

/// Sum of linear: ∑_{k=1}^n k = n(n+1)/2
#[no_mangle]
pub extern "C" fn mathlib5_sum_linear(n: u64) -> u64 {
    n * (n + 1) / 2
}

/// Sum of cubes: ∑_{k=1}^n k³ = (n(n+1)/2)²
#[no_mangle]
pub extern "C" fn mathlib5_sum_cubes(n: u64) -> u64 {
    let s = n * (n + 1) / 2;
    s * s
}

/// Factor polynomial (placeholder - uses normalizer)
#[no_mangle]
pub extern "C" fn mathlib5_factor_poly(coeffs_ptr: *const u64, len: u64, result_ptr: *mut u64) -> bool {
    if coeffs_ptr.is_null() || result_ptr.is_null() || len == 0 {
        return false;
    }
    // Placeholder - in real implementation would factor polynomial
    unsafe {
        for i in 0..len as usize {
            *result_ptr.add(i) = *coeffs_ptr.add(i);
        }
    }
    true
}

/// Solve linear equation: a*x + b = c
#[no_mangle]
pub extern "C" fn mathlib5_solve_linear(a: u64, b: u64, c: u64, result_ptr: *mut u64) -> bool {
    if a == 0 || result_ptr.is_null() {
        return false;
    }
    // a*x + b = c => x = (c - b) / a
    if c < b {
        return false;
    }
    let x = (c - b) / a;
    if a * x + b == c {
        unsafe { *result_ptr = x; }
        true
    } else {
        false
    }
}

/// Greatest common divisor
#[no_mangle]
pub extern "C" fn mathlib5_gcd(a: u64, b: u64) -> u64 {
    let mut a = a;
    let mut b = b;
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}

/// Primality test (simple trial division)
#[no_mangle]
pub extern "C" fn mathlib5_is_prime(n: u64) -> bool {
    if n < 2 { return false; }
    if n == 2 || n == 3 { return true; }
    if n % 2 == 0 || n % 3 == 0 { return false; }
    let mut i = 5;
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 { return false; }
        i += 6;
    }
    true
}

/// Symbolic normalization via C-- kernel
#[no_mangle]
pub extern "C" fn mathlib5_sym_norm(expr_json_ptr: *const c_char, result_ptr: *mut *mut c_char) -> bool {
    if expr_json_ptr.is_null() || result_ptr.is_null() {
        return false;
    }
    unsafe {
        let expr_str = match CStr::from_ptr(expr_json_ptr).to_str() {
            Ok(s) => s,
            Err(_) => return false,
        };
        let expr = match serde_json::from_str::<MathIR>(expr_str) {
            Ok(e) => e,
            Err(_) => return false,
        };
        let normalizer = Normalizer::new();
        let result = normalizer.normalize(&expr);
        let result_str = match serde_json::to_string(&result) {
            Ok(s) => s,
            Err(_) => return false,
        };
        let c_str = match CString::new(result_str) {
            Ok(c) => c,
            Err(_) => return false,
        };
        *result_ptr = c_str.into_raw();
    }
    true
}

/// Symbolic differentiation
#[no_mangle]
pub extern "C" fn mathlib5_sym_diff(expr_json_ptr: *const c_char, var_json_ptr: *const c_char, result_ptr: *mut *mut c_char) -> bool {
    if expr_json_ptr.is_null() || var_json_ptr.is_null() || result_ptr.is_null() {
        return false;
    }
    unsafe {
        let expr_str = match CStr::from_ptr(expr_json_ptr).to_str() { Ok(s) => s, Err(_) => return false };
        let var_str = match CStr::from_ptr(var_json_ptr).to_str() { Ok(s) => s, Err(_) => return false };
        let expr = match serde_json::from_str::<MathIR>(expr_str) { Ok(e) => e, Err(_) => return false };
        let var = match crate::mathir::from_json(var_str) { Some(v) => v, None => return false };
        
        // Derivative: d/dx expr
        let deriv = MathIR::Derivative { expr: Box::new(expr), var: var_str.to_string() };
        let normalizer = Normalizer::new();
        let result = normalizer.normalize(&deriv);
        let result_str = match serde_json::to_string(&result) { Ok(s) => s, Err(_) => return false };
        let c_str = match CString::new(result_str) { Ok(c) => c, Err(_) => return false };
        *result_ptr = c_str.into_raw();
    }
    true
}

/// Symbolic integration
#[no_mangle]
pub extern "C" fn mathlib5_sym_integrate(expr_json_ptr: *const c_char, var_json_ptr: *const c_char, result_ptr: *mut *mut c_char) -> bool {
    if expr_json_ptr.is_null() || var_json_ptr.is_null() || result_ptr.is_null() {
        return false;
    }
    unsafe {
        let expr_str = match CStr::from_ptr(expr_json_ptr).to_str() { Ok(s) => s, Err(_) => return false };
        let var_str = match CStr::from_ptr(var_json_ptr).to_str() { Ok(s) => s, Err(_) => return false };
        let expr = match serde_json::from_str::<MathIR>(expr_str) { Ok(e) => e, Err(_) => return false };
        let var = match crate::mathir::from_json(var_str) { Some(v) => v, None => return false };
        
        // Integral: ∫ expr d(var)
        let integral = MathIR::Integral { expr: Box::new(expr), var: var_str.to_string(), lower: None, upper: None };
        let normalizer = Normalizer::new();
        let result = normalizer.normalize(&integral);
        let result_str = match serde_json::to_string(&result) { Ok(s) => s, Err(_) => return false };
        let c_str = match CString::new(result_str) { Ok(c) => c, Err(_) => return false };
        *result_ptr = c_str.into_raw();
    }
    true
}