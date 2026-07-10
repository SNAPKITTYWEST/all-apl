{-# LANGUAGE OverloadedStrings #-}

module Parser where

import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void
import AST (SExpr(..))

type Parser = Parsec Void Text

parseAPL :: Text -> Either (ParseErrorBundle Text Void) SExpr
parseAPL = parse (space *> pSExpr <* eof) ""

pSExpr :: Parser SExpr
pSExpr = pList <|> pString <|> pNumber <|> pAtom <|> pSymbol

pString :: Parser SExpr
pString = String . T.pack <$> (char '"' *> manyTill L.charLiteral (char '"'))

pAtom :: Parser SExpr
pAtom = Atom . T.pack <$> some (letterChar <|> char '_')

pSymbol :: Parser SExpr
pSymbol = Atom . T.pack <$> some (oneOf ("⍳⍴⍝+/*-÷=≠<>≤≥" :: String))

pNumber :: Parser SExpr
pNumber = Number . read <$> some (digitChar <|> char '.')

pList :: Parser SExpr
pList = between (char '(') (char ')') $
  List <$> (space *> pSExpr `sepEndBy` space)
  <|> between (char '{') (char '}') (List . (Atom "lambda" :) <$> (space *> pSExpr `sepEndBy` space))
