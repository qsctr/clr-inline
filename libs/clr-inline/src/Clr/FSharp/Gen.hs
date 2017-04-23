{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeInType        #-}
module Clr.FSharp.Gen (name, compile) where

import           Clr.Inline.Config
import           Clr.Inline.Quoter
import           Clr.Inline.Utils
import           Clr.Inline.Utils.Embed
import           Clr.Inline.Types
import           Control.Monad
import           Control.Monad.Trans.Writer
import qualified Data.ByteString                 as BS
import qualified Data.Map as Map
import           Data.Proxy
import           Language.Haskell.TH.Syntax
import           System.Directory
import           System.FilePath                 ((<.>), (</>))
import           System.IO.Temp
import           System.Process
import           Text.Printf

name :: Proxy "fsharp"
name = Proxy

genCode :: ClrInlinedGroup "fsharp" -> String
genCode ClrInlinedGroup {units, mod} =
  unlines $
  execWriter $ do
    yield $ printf "namespace %s" (getNamespace mod)
    forM_ units $ \case
      ClrInlinedDec _ body -> yield body
      ClrInlinedExp {} -> return ()
    yield $ printf "type %s =" (getClassName mod)
    forM_ units $ \case
      ClrInlinedDec {} -> return ()
      ClrInlinedExp exp@ClrInlinedExpDetails {..} -> do
        let argsString =
              case Map.toList args of
                [] -> "()"
                other -> unwords [printf "(%s:%s)" a t | (a, ClrType t) <- other]
        yield $ printf   "  static member %s %s =" (getMethodName exp) argsString
        yield $ printf "#line %d \"%s\"" (fst $ loc_start loc) (loc_filename loc)
        forM_ (lines body) $ \l ->
          yield $ printf "        %s" l

compile :: ClrInlineConfig -> ClrInlinedGroup "fsharp" -> IO ClrBytecode
compile ClrInlineConfig {..} m@ClrInlinedGroup {..} = do
  temp <- getTemporaryDirectory
  let ass = getAssemblyName name mod
  dir <- createTempDirectory temp "inline-fsharp"
  let src = dir </> ass <.> ".fs"
      tgt = dir </> ass <.> ".dll"
  writeFile src (genCode m)
  callCommand $
    unwords $
    execWriter $ do
      yield configFSharpPath
      yield "--nologo"
      yield "--target:library"
      yield $ "--out:" ++ tgt
      when configDebugSymbols $ yield "--debug:embedded"
      forM_ configExtraIncludeDirs $ \dir -> yield $ "--lib:" ++ dir
      forM_ configDependencies $ \name -> yield $ "--reference:" ++ name
      yieldAll configCustomCompilerFlags
      yield src
  bcode <- BS.readFile tgt
  return $ ClrBytecode bcode
