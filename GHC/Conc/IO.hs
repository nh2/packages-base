{-# OPTIONS_GHC -XNoImplicitPrelude #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_HADDOCK not-home #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  GHC.Conc.IO
-- Copyright   :  (c) The University of Glasgow, 1994-2002
-- License     :  see libraries/base/LICENSE
--
-- Maintainer  :  cvs-ghc@haskell.org
-- Stability   :  internal
-- Portability :  non-portable (GHC extensions)
--
-- Basic concurrency stuff.
--
-----------------------------------------------------------------------------

-- No: #hide, because bits of this module are exposed by the stm package.
-- However, we don't want this module to be the home location for the
-- bits it exports, we'd rather have Control.Concurrent and the other
-- higher level modules be the home.  Hence:

#include "Typeable.h"

-- #not-home
module GHC.Conc.IO
        ( ensureIOManagerIsRunning

        -- * Waiting
        , threadDelay           -- :: Int -> IO ()
        , registerDelay         -- :: Int -> IO (TVar Bool)
        , threadWaitRead        -- :: Int -> IO ()
        , threadWaitWrite       -- :: Int -> IO ()

#ifdef mingw32_HOST_OS
        , asyncRead     -- :: Int -> Int -> Int -> Ptr a -> IO (Int, Int)
        , asyncWrite    -- :: Int -> Int -> Int -> Ptr a -> IO (Int, Int)
        , asyncDoProc   -- :: FunPtr (Ptr a -> IO Int) -> Ptr a -> IO Int

        , asyncReadBA   -- :: Int -> Int -> Int -> Int -> MutableByteArray# RealWorld -> IO (Int, Int)
        , asyncWriteBA  -- :: Int -> Int -> Int -> Int -> MutableByteArray# RealWorld -> IO (Int, Int)

        , ConsoleEvent(..)
        , win32ConsoleHandler
        , toWin32ConsoleEvent
#endif
        ) where

import Control.Monad
import Foreign
import GHC.Base
import GHC.Conc.Sync as Sync
import GHC.Real ( fromIntegral )
import System.Posix.Types

#ifdef mingw32_HOST_OS
import qualified GHC.Conc.Windows as Windows
import GHC.Conc.Windows (asyncRead, asyncWrite, asyncDoProc, asyncReadBA,
                         asyncWriteBA, ConsoleEvent(..), win32ConsoleHandler,
                         toWin32ConsoleEvent)
#else
import qualified System.Event.Thread as Event
#endif

ensureIOManagerIsRunning :: IO ()
#ifndef mingw32_HOST_OS
ensureIOManagerIsRunning = Event.ensureIOManagerIsRunning
#else
ensureIOManagerIsRunning = Windows.ensureIOManagerIsRunning
#endif

-- | Block the current thread until data is available to read on the
-- given file descriptor (GHC only).
threadWaitRead :: Fd -> IO ()
threadWaitRead fd
#ifndef mingw32_HOST_OS
  | threaded  = Event.threadWaitRead fd
#endif
  | otherwise = IO $ \s ->
        case fromIntegral fd of { I# fd# ->
        case waitRead# fd# s of { s' -> (# s', () #)
        }}

-- | Block the current thread until data can be written to the
-- given file descriptor (GHC only).
threadWaitWrite :: Fd -> IO ()
threadWaitWrite fd
#ifndef mingw32_HOST_OS
  | threaded  = Event.threadWaitWrite fd
#endif
  | otherwise = IO $ \s ->
        case fromIntegral fd of { I# fd# ->
        case waitWrite# fd# s of { s' -> (# s', () #)
        }}

-- | Suspends the current thread for a given number of microseconds
-- (GHC only).
--
-- There is no guarantee that the thread will be rescheduled promptly
-- when the delay has expired, but the thread will never continue to
-- run /earlier/ than specified.
--
threadDelay :: Int -> IO ()
threadDelay time
#ifdef mingw32_HOST_OS
  | threaded  = Windows.threadDelay time
#else
  | threaded  = Event.threadDelay time
#endif
  | otherwise = IO $ \s ->
        case fromIntegral time of { I# time# ->
        case delay# time# s of { s' -> (# s', () #)
        }}

-- | Set the value of returned TVar to True after a given number of
-- microseconds. The caveats associated with threadDelay also apply.
--
registerDelay :: Int -> IO (TVar Bool)
registerDelay usecs
#ifdef mingw32_HOST_OS
  | threaded = Windows.registerDelay usecs
#else
  | threaded = Event.registerDelay usecs
#endif
  | otherwise = error "registerDelay: requires -threaded"

foreign import ccall unsafe "rtsSupportsBoundThreads" threaded :: Bool