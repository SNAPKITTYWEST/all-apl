{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

module MathLib5.Parser
  ( parseModule
  , parseDecl
  , parseExpr
  , parseType
  , ParserError
  ) where

import Control.Applicative ((<|>), (<&>))
import Control.Monad.Combinators.Expr
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void
import Data.Scientific (Scientific)
import Data.Ratio ((%))
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Vector (Vector)
import qualified Data.Vector as V
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as M
import Data.Set (Set)
import qualified Data.Set as S

import MathLib5.IR.Typed hiding (var, lam, app, intL, ratL, boolL, strL, tupleE, vectorE, matrixE, sigmaE, piE, matchE, ifE, quantumGate, measureE, entangleE, qubitE, kernelCallE, intT, natT, ratT, algT, symT, boolT, stringT, unitT, propT, typeT, funT, piT, sigmaT, refineT, tensorT, matrixT, quantumT, qubitT, quregT, appT, varT, metaT, binderName, binderType)

--------------------------------------------------------------------------------
-- Parser Setup
--------------------------------------------------------------------------------

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 (L.skipLineComment "--") (L.skipBlockComment "/-" "-/")

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

brackets :: Parser a -> Parser a
brackets = between (symbol "[") (symbol "]")

braces :: Parser a -> Parser a
braces = between (symbol "{") (symbol "}")

angles :: Parser a -> Parser a
angles = between (symbol "<") (symbol ">")

reserved :: Text -> Parser ()
reserved w = lexeme (string w *> notFollowedBy (alphaNumChar <|> char '_' <|> char '\''))

--------------------------------------------------------------------------------
-- Keywords & Operators
--------------------------------------------------------------------------------

keywords :: Set Text
keywords = S.fromList
  [ "theorem", "lemma", "proof", "qed", "by", "have", "show"
  , "function", "def", "let", "in", "where", "if", "then", "else"
  , "match", "with", "case", "of", "inductive", "structure", "class"
  , "instance", "extend", "namespace", "open", "import", "export"
  , "module", "kernel", "target", "vectorize", "verify", "pragma"
  , "Int", "Nat", "Rational", "Algebraic", "Symbolic"
  , "Tensor", "Matrix", "QuantumState", "Qubit", "Qureg"
  , "H", "X", "Y", "Z", "CNOT", "CZ", "SWAP", "Toffoli"
  , "measure", "reset", "entangle", "superpose"
  , "C--", "LLVM", "MLIR", "PTX", "SPIRV", "Verilog", "Chisel"
  , "AVX512", "NEON", "SVE", "AMX", "TPU", "FPGA"
  , "overflow", "underflow", "precision", "alignment", "pipeline"
  , "true", "false", "Type", "Prop", "Sort", "Kind"
  ]

identifier :: Parser Text
identifier = lexeme $ do
  c <- letterChar <|> char '_'
  cs <- many (alphaNumChar <|> char '_' <|> char '\'' <|> char '?' <|> char '!')
  let name = T.cons c (T.pack cs)
  if S.member name keywords
    then fail $ "keyword " ++ T.unpack name ++ " cannot be an identifier"
    else pure name

--------------------------------------------------------------------------------
-- Literals
--------------------------------------------------------------------------------

integer :: Parser Integer
integer = lexeme L.decimal

scientific :: Parser Scientific
scientific = lexeme L.scientific

stringLit :: Parser Text
stringLit = lexeme (char '"' >> manyTill L.charLiteral (char '"') >>= pure . T.pack)

charLit :: Parser Char
charLit = lexeme (char '\'' >> L.charLiteral <* char '\'')

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

parseType :: Parser Type
parseType = parseTypeExpr

parseTypeExpr :: Parser Type
parseTypeExpr = makeExprParser parseTypeAtom typeOperators

parseTypeAtom :: Parser Type
parseTypeAtom = choice
  [ reserved "Int"        $> intT
  , reserved "Nat"        $> natT
  , reserved "Rational"   $> ratT
  , reserved "Algebraic"  $> algT
  , reserved "Symbolic"   $> symT
  , reserved "Bool"       $> boolT
  , reserved "String"     $> stringT
  , reserved "Unit"       $> unitT
  , reserved "Prop"       $> propT
  , reserved "Type"       $> typeT
  , reserved "Qubit"      $> qubitT
  , try (reserved "Qureg" *> brackets integer >>= pure . quregT . fromInteger)
  , try (reserved "QuantumState" *> brackets integer >>= pure . quantumT . fromInteger)
  , try (do reserved "Tensor"
            t <- brackets parseTypeExpr
            ds <- braces (sepBy1 parseDimSpec (symbol "×"))
            pure (tensorT t ds))
  , try (do reserved "Matrix"
            t <- brackets parseTypeExpr
            r <- braces parseDimSpec
            _ <- symbol "×"
            c <- parseDimSpec
            pure (matrixT t r c))
  , parens parseTypeExpr
  , try (do name <- identifier
            ts <- braces (sepBy parseTypeExpr (symbol ","))
            pure (appT name ts))
  , TVar . T.cons '?' <$> (symbol "?" *> identifier)
  , varT <$> identifier
  ]

parseDimSpec :: Parser DimSpec
parseDimSpec = choice
  [ DStatic . fromInteger <$> integer
  , DParam <$> identifier
  , reserved "?" $> DDynamic
  ]

typeOperators :: [[Operator Parser Type]]
typeOperators =
  [ [ InfixR (symbol "→" $> funT) ]
  ]

--------------------------------------------------------------------------------
-- Binders
--------------------------------------------------------------------------------

parseBinder :: Parser Binder
parseBinder = choice
  [ braces (do name <- identifier
               _ <- symbol ":"
               ty <- parseTypeExpr
               pure (Binder name ty True False))
  , parens (do name <- identifier
               _ <- symbol ":"
               ty <- parseTypeExpr
               pure (Binder name ty False True))
  , do name <- identifier
       _ <- symbol ":"
       ty <- parseTypeExpr
       pure (Binder name ty False True)
  ]

parseBinders :: Parser [Binder]
parseBinders = many parseBinder

--------------------------------------------------------------------------------
-- Expressions
--------------------------------------------------------------------------------

parseExpr :: Parser Term
parseExpr = parseExprPrec

parseExprPrec :: Parser Term
parseExprPrec = makeExprParser parseAtom exprOperators

parseAtom :: Parser Term
parseAtom = choice
  [ try parseLambda
  , try parseLet
  , try parseIf
  , try parseMatch
  , try parseSigma
  , try parsePi
  , try parseIntegral
  , try parseSetComp
  , try parseQuantum
  , try parseKernelCall
  , try parseTuple
  , try parseVector
  , try parseMatrix
  , try parseLiteral
  , try parseVar
  , parens parseExprPrec
  ]

-- Lambda: λ (x : T) → body  or  fun (x : T) => body
parseLambda :: Parser Term
parseLambda = do
  reserved "λ" <|> reserved "fun"
  bs <- some parseBinder
  _ <- symbol "→" <|> symbol "=>"
  body <- parseExprPrec
  pure $ foldr (\b acc -> Lam b acc) body bs

-- Let binding
parseLet :: Parser Term
parseLet = do
  reserved "let"
  _ <- optional (reserved "rec")
  name <- identifier
  ty <- optional (symbol ":" *> parseTypeExpr)
  _ <- symbol "="
  val <- parseExprPrec
  reserved "in"
  body <- parseExprPrec
  let b = Binder name (fromMaybe (metaT "?") ty) False True
  pure $ LetIn b val body

-- If-then-else
parseIf :: Parser Term
parseIf = do
  reserved "if"
  cond <- parseExprPrec
  reserved "then"
  thn <- parseExprPrec
  reserved "else"
  els <- parseExprPrec
  pure $ If cond thn els

-- Match
parseMatch :: Parser Term
parseMatch = do
  reserved "match"
  scrut <- parseExprPrec
  reserved "with"
  cases <- braces (sepBy parseMatchCase (symbol "|"))
  pure $ Match scrut cases

parseMatchCase :: Parser MatchCase
parseMatchCase = do
  pat <- parsePattern
  _ <- symbol "=>"
  body <- parseExprPrec
  pure $ MatchCase pat body

-- Sigma: Σ [x : T .. n] body  or  Σ (x : T) ∈ s, body
parseSigma :: Parser Term
parseSigma = do
  _ <- reserved "Σ" <|> reserved "∑"
  choice
    [ brackets $ do
        b <- parseBinder
        _ <- symbol ".."
        hi <- parseExprPrec
        body <- parseExprPrec
        pure $ Sigma b hi body
    , do
        b <- parseBinder
        _ <- reserved "∈"
        set <- parseExprPrec
        _ <- symbol ","
        body <- parseExprPrec
        pure $ Sigma b set body
    ]

-- Pi: Π [x : T .. n] body
parsePi :: Parser Term
parsePi = do
  _ <- reserved "Π" <|> reserved "∏"
  brackets $ do
    b <- parseBinder
    _ <- symbol ".."
    hi <- parseExprPrec
    body <- parseExprPrec
    pure $ Pi b body

-- Integral: ∫ [a..b] f d(x)
parseIntegral :: Parser Term
parseIntegral = do
  _ <- reserved "∫"
  _ <- symbol "["
  lo <- parseExprPrec
  _ <- symbol ".."
  hi <- parseExprPrec
  _ <- symbol "]"
  f <- parseExprPrec
  _ <- reserved "d"
  varName <- identifier
  pure $ Integral lo hi f (Var varName)

-- Set comprehension: { e | x ∈ s, p }
parseSetComp :: Parser Term
parseSetComp = braces $ do
  e <- parseExprPrec
  _ <- symbol "|"
  b <- parseBinder
  _ <- reserved "∈"
  s <- parseExprPrec
  _ <- symbol ","
  p <- parseExprPrec
  pure $ SetComp e b s p

-- Quantum operations
parseQuantum :: Parser Term
parseQuantum = choice
  [ try $ do _ <- reserved "H"; q <- parens parseQubit; pure $ QGate "H" [q]
  , try $ do _ <- reserved "X"; q <- parens parseQubit; pure $ QGate "X" [q]
  , try $ do _ <- reserved "Y"; q <- parens parseQubit; pure $ QGate "Y" [q]
  , try $ do _ <- reserved "Z"; q <- parens parseQubit; pure $ QGate "Z" [q]
  , try $ do _ <- reserved "CNOT"
             q1 <- parens parseQubit
             _ <- symbol ","
             q2 <- parens parseQubit
             pure $ QGate "CNOT" [q1, q2]
  , try $ do _ <- reserved "CZ"
             q1 <- parens parseQubit
             _ <- symbol ","
             q2 <- parens parseQubit
             pure $ QGate "CZ" [q1, q2]
  , try $ do _ <- reserved "SWAP"
             q1 <- parens parseQubit
             _ <- symbol ","
             q2 <- parens parseQubit
             pure $ QGate "SWAP" [q1, q2]
  , try $ do _ <- reserved "Toffoli"
             q1 <- parens parseQubit
             _ <- symbol ","
             q2 <- parens parseQubit
             _ <- symbol ","
             q3 <- parens parseQubit
             pure $ QGate "Toffoli" [q1, q2, q3]
  , try $ do _ <- reserved "measure"
             basis <- optional (braces identifier)
             q <- parens parseQubit
             pure $ Measure q basis
  , try $ do _ <- reserved "entangle"
             qs <- parens (sepBy parseQubit (symbol ","))
             pure $ Entangle qs
  ]

parseQubit :: Parser Term
parseQubit = choice
  [ QubitLit . fromInteger <$> (char 'q' *> integer)
  , Var <$> identifier
  ]

-- Kernel call
parseKernelCall :: Parser Term
parseKernelCall = do
  _ <- reserved "kernel"
  name <- identifier
  args <- parens (sepBy parseExprPrec (symbol ","))
  pure $ KernelCall name args

-- Tuples, Vectors, Matrices
parseTuple :: Parser Term
parseTuple = parens $ do
  es <- sepBy1 parseExprPrec (symbol ",")
  pure $ Tuple es

parseVector :: Parser Term
parseVector = brackets $ do
  es <- sepBy parseExprPrec (symbol ";")
  pure $ Vector (V.fromList es)

parseMatrix :: Parser Term
parseMatrix = brackets $ do
  rows <- sepBy1 parseMatrixRow (symbol ";")
  pure $ Matrix (V.fromList (map V.fromList rows))

parseMatrixRow :: Parser [Term]
parseMatrixRow = sepBy1 parseExprPrec (symbol ",")

-- Literals
parseLiteral :: Parser Term
parseLiteral = choice
  [ LitInt <$> integer
  , LitRat <$> scientific
  , LitBool True <$ reserved "true"
  , LitBool False <$ reserved "false"
  , LitString <$> stringLit
  ]

-- Variable / Application
parseVar :: Parser Term
parseVar = do
  name <- identifier
  typeAppArg name <|> pure (Var name)
  where
    typeAppArg n = try $ do
      _ <- symbol "@"
      ts <- braces (sepBy parseTypeExpr (symbol ","))
      pure $ TypeApp (Var n) ts

--------------------------------------------------------------------------------
-- Patterns
--------------------------------------------------------------------------------

parsePattern :: Parser Pattern
parsePattern = choice
  [ reserved "_" $> PWildcard
  , PVar <$> identifier
  , PLitInt <$> integer
  , PLitBool True <$ reserved "true"
  , PLitBool False <$ reserved "false"
  , try $ do name <- identifier
             ps <- many parsePattern
             pure $ PConstructor name ps
  , PTuple <$> parens (sepBy parsePattern (symbol ","))
  , PVector <$> brackets (V.fromList <$> sepBy parsePattern (symbol ";"))
  , do name <- identifier
       _ <- symbol "@"
       pat <- parsePattern
       pure $ PAs name pat
  ]

--------------------------------------------------------------------------------
-- Expression Operators
--------------------------------------------------------------------------------

exprOperators :: [[Operator Parser Term]]
exprOperators =
  [ [ Postfix (symbol "'" $> \e -> QGate "†" [e]) ]
  , [ InfixL (symbol "∘" $> \f g -> Lam (Binder "x" (metaT "?") False True) (App f (App g (Var "x")))) ]
  , [ InfixR (symbol "⊗" $> \a b -> QGate "⊗" [a, b]) ]
  , [ InfixL (symbol "*" $> \a b -> App (App (Var "*") a) b)
    , InfixL (symbol "/" $> \a b -> App (App (Var "/") a) b)
    , InfixL (symbol "×" $> \a b -> App (App (Var "×") a) b)
    , InfixL (symbol "÷" $> \a b -> App (App (Var "÷") a) b)
    ]
  , [ InfixL (symbol "+" $> \a b -> App (App (Var "+") a) b)
    , InfixL (symbol "-" $> \a b -> App (App (Var "-") a) b)
    , InfixL (symbol "⊕" $> \a b -> App (App (Var "⊕") a) b)
    ]
  , [ InfixN (symbol "="  $> \a b -> App (App (Var "=") a) b)
    , InfixN (symbol "≠"  $> \a b -> App (App (Var "≠") a) b)
    , InfixN (symbol "<"  $> \a b -> App (App (Var "<") a) b)
    , InfixN (symbol "≤"  $> \a b -> App (App (Var "≤") a) b)
    , InfixN (symbol ">"  $> \a b -> App (App (Var ">") a) b)
    , InfixN (symbol "≥"  $> \a b -> App (App (Var "≥") a) b)
    , InfixN (symbol "≡"  $> \a b -> App (App (Var "≡") a) b)
    , InfixN (symbol "≅"  $> \a b -> App (App (Var "≅") a) b)
    ]
  , [ InfixR (symbol "∧" $> \a b -> App (App (Var "∧") a) b) ]
  , [ InfixR (symbol "∨" $> \a b -> App (App (Var "∨") a) b) ]
  , [ Prefix (symbol "¬" $> \a -> App (Var "¬") a) ]
  ]

--------------------------------------------------------------------------------
-- Declarations
--------------------------------------------------------------------------------

parseModule :: Parser Module
parseModule = do
  sc
  name <- parseModuleName
  ds <- many parseDecl
  eof
  pure $ Module name ds

parseModuleName :: Parser Text
parseModuleName = choice
  [ reserved "module" *> identifier <* symbol "{"
  , pure "Main"
  ]

parseDecl :: Parser Declaration
parseDecl = choice
  [ parseTheoremDecl
  , parseFunctionDecl
  , parseKernelDecl
  , parseInductiveDecl
  , parseStructureDecl
  , parseClassDecl
  , parseInstanceDecl
  , parseImportDecl
  , parseNamespaceDecl
  ]

parseTheoremDecl :: Parser Declaration
parseTheoremDecl = do
  _ <- reserved "theorem" <|> reserved "lemma"
  name <- identifier
  tps <- optional (angles (sepBy identifier (symbol ","))) <&> fromMaybe []
  _ <- symbol ":"
  ty <- parseTypeExpr
  proof <- optional (reserved ":=" *> parseProof)
  pure $ DTheorem Theorem { thName = name, thTypeParams = tps, thType = ty, thProof = proof }

parseProof :: Parser Proof
parseProof = choice
  [ PByTactic <$> (reserved "by" *> sepBy1 parseTactic (symbol ";"))
  , PByTerm <$> parseExprPrec
  ]

parseTactic :: Parser Tactic
parseTactic = choice
  [ TIntro <$> (reserved "intro" *> many identifier)
  , TApply <$> (reserved "apply" *> parseExprPrec)
  , TRewrite <$> (reserved "rw" *> brackets (sepBy parseExprPrec (symbol ",")))
  , TSimp <$> (reserved "simp" *> many identifier)
  , reserved "norm_num" $> TNormNum
  , reserved "linarith" $> TLinarith
  , reserved "ring" $> TRing
  , reserved "field" $> TField
  , TInduction <$> (reserved "induction" *> identifier)
  , TCases <$> (reserved "cases" *> identifier)
  , reserved "constructor" $> TConstructor
  , TExact <$> (reserved "exact" *> parseExprPrec)
  , reserved "assumption" $> TAssumption
  , reserved "tauto" $> TTauto
  , reserved "omega" $> TOmega
  , reserved "decide" $> TDecide
  , do reserved "have"
       name <- identifier
       _ <- symbol ":"
       ty <- parseTypeExpr
       _ <- symbol ":="
       pr <- parseProof
       pure $ THave name ty pr
  , TCalc <$> (reserved "calc" *> braces (sepBy1 parseCalcStep (symbol ";")))
  ]

parseCalcStep :: Parser CalcStep
parseCalcStep = do
  l <- parseExprPrec
  rel <- choice [ symbol "=", symbol "≤", symbol "<", symbol "≥", symbol ">", symbol "≡", symbol "≅" ]
  r <- parseExprPrec
  pr <- optional (symbol ":=" *> parseProof)
  pure $ CalcStep l rel r pr

parseFunctionDecl :: Parser Declaration
parseFunctionDecl = do
  _ <- reserved "function" <|> reserved "def"
  name <- identifier
  tps <- optional (angles (sepBy identifier (symbol ","))) <&> fromMaybe []
  params <- parens (sepBy parseBinder (symbol ","))
  retTy <- optional (symbol ":" *> parseTypeExpr)
  _ <- symbol "="
  body <- parseExprPrec
  pure $ DFunction name tps params (fromMaybe (metaT "?") retTy) body

parseKernelDecl :: Parser Declaration
parseKernelDecl = do
  _ <- reserved "kernel"
  name <- identifier
  tps <- optional (angles (sepBy identifier (symbol ","))) <&> fromMaybe []
  _ <- symbol ":"
  spec <- braces (sepBy parseKernelSpec (symbol ","))
  let ks = foldr ($) (kernelSpec name tps) spec
  pure $ DKernel ks

parseKernelSpec :: Parser (KernelSpec -> KernelSpec)
parseKernelSpec = choice
  [ (\t ks -> ks { ksTargets = [t] }) <$> (reserved "target" *> symbol "=" *> parseTarget)
  , (\v ks -> ks { ksVectorize = v }) <$> (reserved "vectorize" *> symbol "=" *> parseVectorizeSpec)
  , (\v ks -> ks { ksVerify = v }) <$> (reserved "verify" *> symbol "=" *> parseVerifySpec)
  , (\l ks -> ks { ksLayout = l }) <$> (reserved "layout" *> symbol "=" *> parseLayoutSpec)
  , (\p ks -> ks { ksPrecision = p }) <$> (reserved "precision" *> symbol "=" *> parsePrecisionSpec)
  , (\p ks -> ks { ksPragmas = M.insert (fst p) (snd p) (ksPragmas ks) })
      <$> (reserved "pragma" *> symbol "=" *> ((,) <$> identifier <*> stringLit))
  ]

parseTarget :: Parser TargetSpec
parseTarget = choice
  [ reserved "C--" $> TargetCmm
  , reserved "LLVM" $> TargetLLVM
  , reserved "MLIR" $> TargetMLIR
  , reserved "PTX" $> TargetPTX
  , reserved "SPIRV" $> TargetSPIRV
  , reserved "Verilog" $> TargetVerilog
  , reserved "Chisel" $> TargetChisel
  ]

parseVectorizeSpec :: Parser VectorizeSpec
parseVectorizeSpec = choice
  [ reserved "AVX512" $> VecAVX512
  , reserved "NEON" $> VecNEON
  , reserved "SVE" $> VecSVE
  , reserved "AMX" $> VecAMX
  , reserved "TPU" $> VecTPU
  , reserved "FPGA" $> VecFPGA
  , reserved "auto" $> VecAuto
  , reserved "none" $> VecNone
  ]

parseVerifySpec :: Parser VerifySpec
parseVerifySpec = braces $ do
  vs <- sepBy parseVerifyField (symbol ",")
  pure $ foldr ($) (VerifySpec True True PrecFP64 Nothing Nothing True True) vs

parseVerifyField :: Parser (VerifySpec -> VerifySpec)
parseVerifyField = choice
  [ (\b v -> v { vsOverflow = b }) <$> (reserved "overflow" *> symbol "=" *> parseBool)
  , (\b v -> v { vsUnderflow = b }) <$> (reserved "underflow" *> symbol "=" *> parseBool)
  , (\p v -> v { vsPrecision = p }) <$> (reserved "precision" *> symbol "=" *> parsePrecisionSpec)
  , (\a v -> v { vsAlignment = Just (fromInteger a) }) <$> (reserved "alignment" *> symbol "=" *> integer)
  , (\p v -> v { vsPipeline = Just (fromInteger p) }) <$> (reserved "pipeline" *> symbol "=" *> integer)
  , (\b v -> v { vsMemorySafety = b }) <$> (reserved "memory_safety" *> symbol "=" *> parseBool)
  , (\b v -> v { vsTermination = b }) <$> (reserved "termination" *> symbol "=" *> parseBool)
  ]

parseBool :: Parser Bool
parseBool = choice [ reserved "true" $> True, reserved "false" $> False ]

parseLayoutSpec :: Parser LayoutSpec
parseLayoutSpec = choice
  [ reserved "row_major" $> LayoutRowMajor
  , reserved "col_major" $> LayoutColMajor
  , do reserved "blocked"
       _ <- symbol "{"
       r <- integer
       _ <- symbol "×"
       c <- integer
       _ <- symbol "}"
       pure $ LayoutBlocked (fromInteger r) (fromInteger c)
  ]

parsePrecisionSpec :: Parser PrecisionSpec
parsePrecisionSpec = choice
  [ reserved "fp64" $> PrecFP64
  , reserved "fp32" $> PrecFP32
  , reserved "fp16" $> PrecFP16
  , reserved "bf16" $> PrecBF16
  , reserved "int64" $> PrecInt64
  , reserved "int32" $> PrecInt32
  , reserved "int16" $> PrecInt16
  , reserved "int8" $> PrecInt8
  , do reserved "posits"
       _ <- symbol "("
       n <- integer
       _ <- symbol ","
       e <- integer
       _ <- symbol ")"
       pure $ PrecPosits (fromInteger n) (fromInteger e)
  ]

-- Inductive, Structure, Class, Instance (simplified)
parseInductiveDecl :: Parser Declaration
parseInductiveDecl = do
  _ <- reserved "inductive"
  name <- identifier
  tps <- optional (angles (sepBy identifier (symbol ","))) <&> fromMaybe []
  ty <- optional (symbol ":" *> parseTypeExpr)
  cons <- braces (sepBy parseConstructorDecl (symbol "|"))
  pure $ DInductive name tps ty cons

parseConstructorDecl :: Parser ConstructorDecl
parseConstructorDecl = ConstructorDecl <$> identifier <*> optional (symbol ":" *> parseTypeExpr)

parseStructureDecl :: Parser Declaration
parseStructureDecl = do
  _ <- reserved "structure"
  name <- identifier
  tps <- optional (angles (sepBy identifier (symbol ","))) <&> fromMaybe []
  ty <- optional (symbol ":" *> parseTypeExpr)
  fields <- braces (sepBy parseFieldDecl (symbol ","))
  pure $ DStructure name tps ty fields

parseFieldDecl :: Parser FieldDecl
parseFieldDecl = FieldDecl <$> identifier <*> (symbol ":" *> parseTypeExpr)

parseClassDecl :: Parser Declaration
parseClassDecl = do
  _ <- reserved "class"
  name <- identifier
  tps <- optional (angles (sepBy identifier (symbol ","))) <&> fromMaybe []
  ty <- optional (symbol ":" *> parseTypeExpr)
  methods <- braces (sepBy parseMethodDecl (symbol ","))
  pure $ DClass name tps ty methods

parseMethodDecl :: Parser MethodDecl
parseMethodDecl = MethodDecl <$> identifier <*> (symbol ":" *> parseTypeExpr)

parseInstanceDecl :: Parser Declaration
parseInstanceDecl = do
  _ <- reserved "instance"
  name <- optional (identifier <* symbol ":")
  ty <- parseTypeExpr
  impls <- optional (reserved "where" *> braces (sepBy parseMethodImpl (symbol ","))) <&> fromMaybe []
  pure $ DInstance name ty impls

parseMethodImpl :: Parser MethodImpl
parseMethodImpl = MethodImpl <$> identifier <*> (symbol "=" *> parseExprPrec)

parseImportDecl :: Parser Declaration
parseImportDecl = DImport . T.intercalate "." <$> (reserved "import" *> sepBy1 identifier (symbol "."))

parseNamespaceDecl :: Parser Declaration
parseNamespaceDecl = do
  _ <- reserved "namespace"
  name <- identifier
  ds <- braces (many parseDecl)
  pure $ DNamespace name ds

--------------------------------------------------------------------------------
-- Error Type
--------------------------------------------------------------------------------

type ParserError = ParseErrorBundle Text Void
