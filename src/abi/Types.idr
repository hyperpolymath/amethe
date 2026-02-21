-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

||| AMETHE — ABI Type Definitions
|||
||| This module defines the Application Binary Interface for the Amethe 
||| high-assurance storage layer. It provides the formal foundations 
||| for verified data persistence and retrieval.

module AMETHE.ABI.Types

import Data.Bits
import Data.So
import Data.Vect

%default total

--------------------------------------------------------------------------------
-- Platform Context
--------------------------------------------------------------------------------

||| Supported targets for verified storage operations.
public export
data Platform = Linux | Windows | MacOS | BSD | WASM

||| Resolves the execution environment at compile time.
public export
thisPlatform : Platform
thisPlatform =
  %runElab do
    pure Linux

--------------------------------------------------------------------------------
-- Core Result Codes
--------------------------------------------------------------------------------

||| Formal outcome of a storage transaction.
public export
data Result : Type where
  ||| Transaction Committed
  Ok : Result
  ||| Transaction Failed: Generic IO error
  Error : Result
  ||| Malformed Data: Input did not match schema
  InvalidParam : Result
  ||| Exhaustion: Out of memory or disk space
  OutOfMemory : Result
  ||| Safety Error: Internal null pointer encountered
  NullPointer : Result

--------------------------------------------------------------------------------
-- Resource Handles
--------------------------------------------------------------------------------

||| Opaque handle to a Storage Session.
||| INVARIANT: The internal pointer is guaranteed to be non-null.
public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> Handle

||| Safe constructor for storage handles.
public export
createHandle : Bits64 -> Maybe Handle
createHandle 0 = Nothing
createHandle ptr = Just (MkHandle ptr)
