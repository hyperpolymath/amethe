// SPDX-License-Identifier: AGPL-3.0-or-later

/**
 * SafeDOM — Formally Verified DOM Mounting Examples (ReScript).
 *
 * This module demonstrates the usage of the `SafeDOM` library to ensure 
 * that UI components are only mounted to validated DOM nodes. This 
 * eliminates "null-pointer" errors during page hydration and ensures 
 * atomic UI transitions.
 */

open SafeDOM

// PATTERN: BASIC MOUNTING.
// Attempts to mount a component and provides success/failure callbacks.
let mountApp = () => {
  mountSafe(
    "#app",
    "<div><h1>Hello</h1></div>",
    ~onSuccess=el => Console.log("✓ Mounted!"),
    ~onError=err => Console.error("✗ Failed")
  )
}

// PATTERN: BATCH MOUNTING.
// An atomic operation that only succeeds if ALL target selectors exist.
// Prevents "partial" page renders where only some components appear.
let mountMultiple = () => {
  let specs = [
    {selector: "#header", html: "<header></header>"},
    {selector: "#main",   html: "<main></main>"}
  ]

  switch mountBatch(specs) {
  | Ok(elements) => Console.log("✓ All elements mounted successfully.")
  | Error(err)   => Console.error("✗ Atomic mount failed - nothing was changed.")
  }
}

// PATTERN: PRE-VALIDATION.
// Validates inputs BEFORE attempting any DOM manipulation.
let mountWithValidation = () => {
  switch ProvenSelector.validate("#my-app") {
  | Ok(validSelector) =>
      // Only proceed with the mount once the selector is formally proven valid.
      let _ = mount(validSelector, "<div>Valid!</div>")
  | Error(e) => Console.error(e)
  }
}
