{-# LANGUAGE Safe #-}
{-# LANGUAGE CPP #-}
#ifdef __GLASGOW_HASKELL__
{-# LANGUAGE ForeignFunctionInterface #-}
#endif

-----------------------------------------------------------------------------
-- |
-- Module      :  System.Mem
-- Copyright   :  (c) The University of Glasgow 2001
-- License     :  BSD-style (see the file libraries/base/LICENSE)
-- 
-- Maintainer  :  libraries@haskell.org
-- Stability   :  provisional
-- Portability :  portable
--
-- Memory-related system things.
--
-----------------------------------------------------------------------------

module System.Mem (
        performGC
      , performMajorGC
      , performMinorGC
  ) where
 
import Prelude


#ifdef __HUGS__
import Hugs.IOExts

performMajorGC :: IO ()
performMajorGC = performGC

performMinorGC :: IO ()
performMinorGC = performGC
#endif

#ifdef __GLASGOW_HASKELL__
performGC :: IO ()
performGC = performMajorGC

-- | Triggers an immediate garbage collection
foreign import ccall {-safe-} "performMajorGC" performMajorGC :: IO ()

-- | Triggers an immediate minor garbage collection,
-- or possibly a major GC if one is due.
foreign import ccall {-safe-} "performGC" performMinorGC :: IO ()
#endif

