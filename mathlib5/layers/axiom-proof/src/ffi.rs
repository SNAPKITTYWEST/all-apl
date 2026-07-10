//! AXIOM Proof Kernel — C FFI Layer
//! Exposes type checking, beta reduction, and WORM sealing to C99/Fortran

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

use crate::kernel::checker::{Env, Term, infer, check, def_eq, verify_proof};
use crate::kernel::worm::WormDb;

/// Opaque pointer to typing environment
pub struct AxiomEnv {
    pub inner: Env,
}

/// Opaque pointer to WORM database
pub struct AxiomWorm {
    pub inner: WormDb,
}

/// Create a new typing environment
#[no_mangle]
pub extern "C" fn axiom_env_new() -> *mut AxiomEnv {
    let env = AxiomEnv { inner: Env::new() };
    Box::into_raw(Box::new(env))
}

/// Free a typing environment
#[no_mangle]
pub extern "C" fn axiom_env_free(env: *mut AxiomEnv) {
    if !env.is_null() {
        unsafe { drop(Box::from_raw(env)); }
    }
}

/// Extend environment with a variable binding
#[no_mangle]
pub extern "C" fn axiom_env_extend(
    env: *mut AxiomEnv,
    name: *const c_char,
    level: u32,
) {
    if env.is_null() || name.is_null() { return; }
    unsafe {
        let cstr = CStr::from_ptr(name);
        if let Ok(s) = cstr.to_str() {
            (*env).inner.extend(
                s.to_string(),
                Term::Type(level),
                None,
            );
        }
    }
}

/// Create a Type term
#[no_mangle]
pub extern "C" fn axiom_term_type(level: u32) -> *mut Term {
    Box::into_raw(Box::new(Term::Type(level)))
}

/// Create a variable term
#[no_mangle]
pub extern "C" fn axiom_term_var(name: *const c_char) -> *mut Term {
    if name.is_null() { return ptr::null_mut(); }
    unsafe {
        let cstr = CStr::from_ptr(name);
        match cstr.to_str() {
            Ok(s) => Box::into_raw(Box::new(Term::Var(s.to_string()))),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Create a Pi type: Π(x : A). B
#[no_mangle]
pub extern "C" fn axiom_term_pi(
    name: *const c_char,
    arg_type: *mut Term,
    body: *mut Term,
) -> *mut Term {
    if name.is_null() || arg_type.is_null() || body.is_null() {
        return ptr::null_mut();
    }
    unsafe {
        let cstr = CStr::from_ptr(name);
        match cstr.to_str() {
            Ok(s) => Box::into_raw(Box::new(Term::Pi(
                s.to_string(),
                Box::from_raw(arg_type),
                Box::from_raw(body),
            ))),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Create a Lambda: λ(x : A). body
#[no_mangle]
pub extern "C" fn axiom_term_lam(
    name: *const c_char,
    arg_type: *mut Term,
    body: *mut Term,
) -> *mut Term {
    if name.is_null() || arg_type.is_null() || body.is_null() {
        return ptr::null_mut();
    }
    unsafe {
        let cstr = CStr::from_ptr(name);
        match cstr.to_str() {
            Ok(s) => Box::into_raw(Box::new(Term::Lam(
                s.to_string(),
                Box::from_raw(arg_type),
                Box::from_raw(body),
            ))),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Create an application: f x
#[no_mangle]
pub extern "C" fn axiom_term_app(func: *mut Term, arg: *mut Term) -> *mut Term {
    if func.is_null() || arg.is_null() { return ptr::null_mut(); }
    unsafe {
        Box::into_raw(Box::new(Term::App(
            Box::from_raw(func),
            Box::from_raw(arg),
        )))
    }
}

/// Free a term
#[no_mangle]
pub extern "C" fn axiom_term_free(term: *mut Term) {
    if !term.is_null() {
        unsafe { drop(Box::from_raw(term)); }
    }
}

/// Infer the type of a term. Returns 0 on success, -1 on error.
#[no_mangle]
pub extern "C" fn axiom_infer(
    env: *const AxiomEnv,
    term: *const Term,
    out_type: *mut *mut Term,
) -> i32 {
    if env.is_null() || term.is_null() || out_type.is_null() {
        return -1;
    }
    unsafe {
        match infer(&(*env).inner, &*term) {
            Ok(t) => {
                *out_type = Box::into_raw(Box::new(t));
                0
            }
            Err(_) => -1,
        }
    }
}

/// Check that a term has the expected type. Returns 0 on success.
#[no_mangle]
pub extern "C" fn axiom_check(
    env: *const AxiomEnv,
    term: *const Term,
    expected: *const Term,
) -> i32 {
    if env.is_null() || term.is_null() || expected.is_null() {
        return -1;
    }
    unsafe {
        match check(&(*env).inner, &*term, &*expected) {
            Ok(()) => 0,
            Err(_) => -1,
        }
    }
}

/// Check definitional equality. Returns 1 if equal, 0 otherwise.
#[no_mangle]
pub extern "C" fn axiom_def_eq(
    env: *const AxiomEnv,
    t1: *const Term,
    t2: *const Term,
) -> i32 {
    if env.is_null() || t1.is_null() || t2.is_null() {
        return 0;
    }
    unsafe {
        if def_eq(&(*env).inner, &*t1, &*t2) { 1 } else { 0 }
    }
}

/// Verify a proof term against a theorem. Returns 0 on success.
#[no_mangle]
pub extern "C" fn axiom_verify_proof(
    env: *const AxiomEnv,
    theorem: *const Term,
    proof: *const Term,
) -> i32 {
    if env.is_null() || theorem.is_null() || proof.is_null() {
        return -1;
    }
    unsafe {
        match verify_proof(&(*env).inner, &*theorem, &*proof) {
            Ok(()) => 0,
            Err(_) => -1,
        }
    }
}

/// Create a new WORM database
#[no_mangle]
pub extern "C" fn axiom_worm_new(path: *const c_char) -> *mut AxiomWorm {
    if path.is_null() { return ptr::null_mut(); }
    unsafe {
        let cstr = CStr::from_ptr(path);
        match cstr.to_str() {
            Ok(s) => {
                let worm = AxiomWorm { inner: WormDb::new(s) };
                Box::into_raw(Box::new(worm))
            }
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Free a WORM database
#[no_mangle]
pub extern "C" fn axiom_worm_free(worm: *mut AxiomWorm) {
    if !worm.is_null() {
        unsafe { drop(Box::from_raw(worm)); }
    }
}

/// Seal a proof to the WORM ledger. Returns seal hash (caller must free).
#[no_mangle]
pub extern "C" fn axiom_worm_seal(
    worm: *mut AxiomWorm,
    theorem_name: *const c_char,
    theorem: *const c_char,
    proof: *const c_char,
) -> *mut c_char {
    if worm.is_null() || theorem_name.is_null() || theorem.is_null() || proof.is_null() {
        return ptr::null_mut();
    }
    unsafe {
        let name = match CStr::from_ptr(theorem_name).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let thm = match CStr::from_ptr(theorem).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let prf = match CStr::from_ptr(proof).to_str() { Ok(s) => s, Err(_) => return ptr::null_mut() };
        let entry = (*worm).inner.seal_proof(name, thm, prf);
        match CString::new(entry.seal) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Verify a proof against WORM ledger. Returns 1 if verified.
#[no_mangle]
pub extern "C" fn axiom_worm_verify(
    worm: *const AxiomWorm,
    theorem_name: *const c_char,
    theorem: *const c_char,
    proof: *const c_char,
) -> i32 {
    if worm.is_null() || theorem_name.is_null() || theorem.is_null() || proof.is_null() {
        return 0;
    }
    unsafe {
        let name = match CStr::from_ptr(theorem_name).to_str() { Ok(s) => s, Err(_) => return 0 };
        let thm = match CStr::from_ptr(theorem).to_str() { Ok(s) => s, Err(_) => return 0 };
        let prf = match CStr::from_ptr(proof).to_str() { Ok(s) => s, Err(_) => return 0 };
        if (*worm).inner.verify_proof(name, thm, prf) { 1 } else { 0 }
    }
}

/// Get Merkle root (caller must free returned string)
#[no_mangle]
pub extern "C" fn axiom_worm_merkle_root(worm: *const AxiomWorm) -> *mut c_char {
    if worm.is_null() { return ptr::null_mut(); }
    unsafe {
        let root = (*worm).inner.get_merkle_root().to_string();
        match CString::new(root) {
            Ok(s) => s.into_raw(),
            Err(_) => ptr::null_mut(),
        }
    }
}

/// Free a string returned by axiom functions
#[no_mangle]
pub extern "C" fn axiom_string_free(s: *mut c_char) {
    if !s.is_null() {
        unsafe { drop(CString::from_raw(s)); }
    }
}
