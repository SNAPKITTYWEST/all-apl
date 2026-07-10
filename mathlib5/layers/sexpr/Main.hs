module Main where

import AST
import System.Environment (getArgs)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Aeson (encode)
import qualified Data.ByteString.Lazy.Char8 as BSL

prettyPrint :: SExpr -> T.Text
prettyPrint (Atom t) = t
prettyPrint (Number n) = T.pack $ show n
prettyPrint (String s) = T.pack $ show s
prettyPrint (List l) = "(" <> T.unwords (map prettyPrint l) <> ")"

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--print", s] -> TIO.putStrLn $ prettyPrint (Atom (T.pack s)) -- placeholder
    _ -> putStrLn "Usage: sexpr_normalize [--print expr]"
