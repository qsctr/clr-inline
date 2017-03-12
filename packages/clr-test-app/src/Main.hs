{-# LANGUAGE TemplateHaskell, QuasiQuotes, TypeInType, FlexibleInstances,
  MultiParamTypeClasses, TypeFamilies, TypeApplications #-}

module Main where

import Clr
import Clr.CSharp.Inline
import Clr.FSharp.Inline
import Clr.Host
import Clr.Bindings

import Data.Int(Int32, Int64)
import Foreign.Ptr(Ptr, FunPtr)

import Other

instance MethodS1 (T "System.Console" '[]) (T "WriteLine" '[]) () where
  type ResultTypeS1 (T "System.Console" '[]) (T "WriteLine" '[]) () = 'Nothing
  rawInvokeS1 x = rawInvokeMakeWriteLine

rawInvokeMakeWriteLine = getMethodStub "System.Console, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" "WriteLine" "" >>= makeWriteLineType0

foreign import ccall "dynamic" makeWriteLineType0 :: FunPtr (IO ()) -> IO ()

instance MethodS1 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.String" '[]) where
  type ResultTypeS1 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.String" '[]) = 'Nothing
  rawInvokeS1 x = rawInvokeMakeWriteLine1 >>= \f -> f x

rawInvokeMakeWriteLine1 = getMethodStub "System.Console, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" "WriteLine" "System.String" >>= return . makeWriteLineType1

foreign import ccall "dynamic" makeWriteLineType1 :: FunPtr (BStr -> IO ()) -> (BStr -> IO ())

instance MethodS1 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.Int32" '[]) where
  type ResultTypeS1 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.Int32" '[]) = 'Nothing
  rawInvokeS1 x = getMethodStub "System.Console, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" "WriteLine" "System.Int32" >>= return . makeWriteLineType2 >>= \f-> f x

foreign import ccall "dynamic" makeWriteLineType2 :: FunPtr (Int32 -> IO ()) -> (Int32 -> IO ())

instance MethodS2 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.String" '[]) (T "System.Object" '[]) where
  type ResultTypeS2 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.String" '[]) (T "System.Object" '[]) = 'Nothing
  rawInvokeS2 x y = getMethodStub "System.Console, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" "WriteLine" "System.String;System.Object" >>= return . makeWriteLineType3 >>= \f-> f x y

foreign import ccall "dynamic" makeWriteLineType3 :: FunPtr (BStr -> (ObjectID a) -> IO ()) -> (BStr -> (ObjectID a) -> IO ())

instance MethodS3 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.String" '[]) (T "System.Object" '[]) (T "System.Object" '[]) where
  type ResultTypeS3 (T "System.Console" '[]) (T "WriteLine" '[]) (T "System.String" '[]) (T "System.Object" '[]) (T "System.Object" '[]) = 'Nothing
  rawInvokeS3 x y z = getMethodStub "System.Console, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" "WriteLine" "System.String;System.Object;System.Object" >>= return . makeWriteLineType4 >>= \f-> f x y z

foreign import ccall "dynamic" makeWriteLineType4 :: FunPtr (BStr -> (ObjectID a) -> (ObjectID b) -> IO ()) -> (BStr -> (ObjectID a) -> (ObjectID b) -> IO ())



type instance Candidates (T "System.Console" '[]) (T "WriteLine" '[]) = '[ '[                                                                     ]
                                                                         , '[ T "System.String" '[]                                               ]
                                                                         , '[ T "System.Int32"  '[]                                               ]
                                                                         , '[ T "System.String" '[], T "System.Object" '[]                        ]
                                                                         , '[ T "System.String" '[], T "System.Object" '[], T "System.Object" '[] ] ]

main1 :: IO ()
main1 = do
  invokeS @"WriteLine" @"System.Console" ()                                     -- Console.WriteLine()
  invokeS @"WriteLine" @"System.Console" "Hello CLR!!!"                         -- Console.WriteLine(String)
  invokeS @"WriteLine" @"System.Console" (2 :: Int32)                           -- Console.WriteLine(Int32)
  invokeS @"WriteLine" @"System.Console" ("The year is {0}", 2017::Int64)       -- Console.WriteLine(String, Object)
  invokeS @"WriteLine" @"System.Console" ("Well {0} {1}", "This", "Is Cool")    -- Console.WriteLine(String, Object, Object)

[csharp|
using System;|]

main1Inline =
  [csharp|
         Console.WriteLine();
         Console.WriteLine("Hello CLR inline !!!");
         Console.WriteLine(2);
         Console.WriteLine("The year is {0}", 2017);
         Console.WriteLine("Well {0} {1}", "This", "Is Cool");
         return;

         |]


main = do
  startClr
  main1
  main1Inline
  main2
  [fsharp| printfn "And this is %d in F#" (System.DateTime.Today.Year) |]

