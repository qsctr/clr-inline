{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TypeInType             #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE ViewPatterns           #-}
module Clr.Inline.Types where

import           Clr.Bindings.Marshal ()
import           Clr.Bindings.Host
import           Clr.Host.BStr
import           Clr.Marshal
import           Data.Char
import           Data.Int
import           Data.IORef
import           Data.List.Extra
import           Data.Text            (Text)
import           Data.Word
import           Foreign
import           GHC.TypeLits
import           Language.Haskell.TH
import           System.IO.Unsafe

newtype ObjectPtr (name::Symbol)= ObjectPtr Int64
data Object (name::Symbol) = Object (ObjectPtr name) (IORef ())

foreign import ccall "dynamic" releaseObject :: FunPtr (Int64 -> IO ()) -> (Int64 -> IO ())

type instance UnmarshalAs (ObjectPtr n) = (Object n)

-- | Slightly dodgy instance that adds a finalizer to release the CLR object
instance Unmarshal (ObjectPtr n) (Object n) where
  unmarshal o@(ObjectPtr id) = do
    ref <- newIORef ()
    _ <- mkWeakIORef ref $ do
      let f = unsafeDupablePerformIO (unsafeGetPointerToMethod "ReleaseObject")
      releaseObject f id
    return (Object o ref)

instance Marshal (Object n) (ObjectPtr n) where
  marshal (Object ptr ref) f = do
    () <- readIORef ref
    f ptr

newtype ClrType = ClrType {getClrType :: String}

toClrType :: Type -> Maybe ClrType
toClrType t =
  ClrType <$>
  case t of
    ConT t | t == ''Bool -> Just "System.Boolean"
    ConT t | t == ''Double -> Just "System.Double"
    ConT t | t == ''Int -> Just "System.Int32"
    ConT t | t == ''Int32 -> Just "System.Int32"
    ConT t | t == ''Int64 -> Just "System.Int64"
    ConT t | t == ''TextBStr -> Just "System.String"
    ConT t | t == ''BStr -> Just "System.String"
    ConT t | t == ''String -> Just "System.String"
    ConT t | t == ''Text -> Just "System.String"
    AppT (ConT t) (LitT (StrTyLit s)) | t == ''ObjectPtr -> Just s
    _ | otherwise -> Nothing

newtype TextBStr = TextBStr BStr
type instance UnmarshalAs TextBStr = Text
instance Unmarshal TextBStr Text where unmarshal (TextBStr t) = unmarshal t

-- | Rudimentary parser for stringy Haskell types.
--   If successful, produces two types:
--     1. when parsing a return type
--     2. when parsing an argument type
toTHType :: String -> (TypeQ,TypeQ)
toTHType (trim -> s) =
  case map toLower s of
    "string" -> ([t|BStr|]     ,[t|BStr|])
    "text"   -> ([t|TextBStr|] ,[t|BStr|])
    "double" -> ([t|Double|]   ,[t|Double|])
    "bool"   -> ([t|Bool|]     ,[t|Bool|])
    "int"    -> ([t|Int|]      ,[t|Int|])
    "int32"  -> ([t|Int32|]    ,[t|Int32|])
    "int64"  -> ([t|Int64|]    ,[t|Int64|])
    "word"   -> ([t|Word64|]   ,[t|Word64|])
    "void"   -> ([t|()|]       ,[t|()|])
    _        -> let t = return $ ConT ''ObjectPtr `AppT` LitT (StrTyLit s) in (t, t)