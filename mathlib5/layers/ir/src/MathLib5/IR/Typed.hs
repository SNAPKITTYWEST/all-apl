{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module MathLib5.IR.Typed
  ( -- * Core Types
    Sort (..)
  , Type (..)
  , Kind (..)
  , Term (..)
  , Pattern (..)
  , Binder (..)
  , Theorem (..)
  , Proof (..)
  , KernelSpec (..)
  , Module (..)
  , Declaration (..)

    -- * Type Constructors (Smart)
  , intT, natT, ratT, algT, symT, boolT, stringT, unitT
  , propT, typeT, sortT
  , funT, piT, sigmaT, forallT
  , refineT, tensorT, matrixT, quantumT
  , qubitT, quregT
  , appT, varT, metaT

    -- * Term Constructors
  , var, lam, letIn, app, typeApp
  , sigmaE, piE, integralE, setCompE
  , tupleE, vectorE, matrixE
  , litE, intL, ratL, strL, boolL
  , quantumGate, measureE, entangleE, qubitE
  , kernelCallE
  , matchE, ifE

    -- * Kernel Spec Builders
  , kernelSpec, targetCmm, targetLLVM, targetMLIR
  , vectorizeAVX512, vectorizeNEON, verifyOverflowFalse

    -- * Utilities
  , freeVars
  , substitute
  , typeOf
  , prettyTerm
  , prettyType
  ) where

import GHC.Generics (Generic)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Vector (Vector)
import qualified Data.Vector as V
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as M
import Data.Set (Set)
import qualified Data.Set as S
import Data.Scientific (Scientific)
import Data.Ratio (Ratio)
import Data.Complex (Complex)
import Control.DeepSeq (NFData)
import Data.Hashable (Hashable)
import Data.Maybe (fromMaybe)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Kind (Type)

--------------------------------------------------------------------------------
-- Kinds & Sorts
--------------------------------------------------------------------------------

data Kind = KType | KProp | KSort Int | KKind Kind Kind
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data Sort = SType | SProp | SSort Int
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

sortToKind :: Sort -> Kind
sortToKind SType      = KType
sortToKind SProp      = KProp
sortToKind (SSort n)  = KSort n

--------------------------------------------------------------------------------
-- Types (Dependent + Refinement + Hardware + Quantum)
--------------------------------------------------------------------------------

data Type
  = TInt
  | TNat
  | TRational
  | TAlgebraic
  | TSymbolic
  | TBool
  | TString
  | TUnit
  | TProp
  | TType
  | TSort Int
  -- Dependent types
  | TFun Type Type                    -- Non-dependent function
  | TPi Binder Type                   -- Dependent product (∀/Π)
  | TSigma Binder Type                -- Dependent sum (∃/Σ)
  | TForall [Binder] Type             -- Explicit forall
  -- Refinement
  | TRefine Text Type Term            -- { x : T | p x }
  -- Tensor / Matrix
  | TTensor Type [DimSpec]            -- Tensor [Type] { dim1 × dim2 × ... }
  | TMatrix Type DimSpec DimSpec      -- Matrix [Type] { rows × cols }
  -- Quantum
  | TQuantumState Int                 -- QuantumState [n] (n-qubit state vector)
  | TQubit                            -- Single qubit
  | TQureg Int                        -- Qureg [n] (n-qubit register)
  -- Type application / variables
  | TApp Text [Type]                  -- User-defined type constructor
  | TVar Text                         -- Type variable (for polymorphism)
  | TMeta Text                        -- Metavariable (for unification)
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data DimSpec
  = DStatic Int                       -- Known at compile time
  | DParam Text                       -- Dependent on parameter
  | DDynamic                          -- Runtime only (?)
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

--------------------------------------------------------------------------------
-- Binders
--------------------------------------------------------------------------------

data Binder = Binder
  { binderName :: Text
  , binderType :: Type
  , binderImplicit :: Bool            -- {} vs ()
  , binderRelevant :: Bool            -- Erased at runtime?
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

--------------------------------------------------------------------------------
-- Terms (Typed AST)
--------------------------------------------------------------------------------

data Term
  -- Variables & Binders
  = Var Text                          -- Variable reference
  | Lam Binder Term                   -- λ (x : T) → body
  | LetIn Binder Term Term            -- let x : T := t1 in t2
  -- Application
  | App Term Term                     -- f x
  | TypeApp Term [Type]               -- f @{T1, T2}
  -- Literals
  | LitInt Integer
  | LitRat Scientific                 -- Rational
  | LitBool Bool
  | LitString Text
  | LitUnit
  -- Dependent constructs
  | Sigma Binder Term Term            -- Σ (x : T), body  (dependent pair)
  | Pi Binder Term                    -- Π (x : T), body  (dependent function type)
  | Integral Term Term Term Term      -- ∫ [a..b] f dx
  | SetComp Term Binder Term Term     -- { e | x ∈ s, p }
  -- Data structures
  | Tuple [Term]
  | Vector (Vector Term)
  | Matrix (Vector (Vector Term))     -- Row-major
  -- Quantum
  | QGate Text [Term]                 -- H(q), CNOT(q1,q2), etc.
  | Measure Term (Maybe Text)         -- measure(q) or measure{basis}(q)
  | Entangle [Term]                   -- entangle(q1,q2,...)
  | QubitLit Int                      -- q0, q1, ...
  -- Kernel / Hardware
  | KernelCall Text [Term]            -- kernel name args
  -- Control flow
  | Match Term [MatchCase]
  | If Term Term Term
  -- Proof terms
  | ProofTerm Proof
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data MatchCase = MatchCase
  { casePattern :: Pattern
  , caseBody    :: Term
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data Pattern
  = PWildcard
  | PVar Text
  | PLitInt Integer
  | PLitBool Bool
  | PConstructor Text [Pattern]
  | PTuple [Pattern]
  | PVector (Vector Pattern)
  | PAs Text Pattern
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

--------------------------------------------------------------------------------
-- Proof Terms (Lean-style)
--------------------------------------------------------------------------------

data Proof
  = PByTactic [Tactic]
  | PByTerm Term
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data Tactic
  = TIntro [Text]
  | TApply Term
  | TRewrite [Term]
  | TSimp [Text]
  | TNormNum
  | TLinarith
  | TRing
  | TField
  | TInduction Text
  | TCases Text
  | TConstructor
  | TExact Term
  | TAssumption
  | TTauto
  | TOmega
  | TDecide
  | THave Text Type Proof
  | TCalc [CalcStep]
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data CalcStep = CalcStep
  { calcLeft  :: Term
  , calcRel   :: Text       -- =, ≤, <, ≡, ≅
  , calcRight :: Term
  , calcProof :: Maybe Proof
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

--------------------------------------------------------------------------------
-- Kernel Specifications
--------------------------------------------------------------------------------

data KernelSpec = KernelSpec
  { ksName       :: Text
  , ksTypeParams :: [Text]
  , ksTargets    :: [TargetSpec]
  , ksVectorize  :: VectorizeSpec
  , ksVerify     :: VerifySpec
  , ksLayout     :: LayoutSpec
  , ksPrecision  :: PrecisionSpec
  , ksPragmas    :: Map Text Text
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data TargetSpec
  = TargetCmm
  | TargetLLVM
  | TargetMLIR
  | TargetPTX
  | TargetSPIRV
  | TargetVerilog
  | TargetChisel
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data VectorizeSpec
  = VecAVX512
  | VecNEON
  | VecSVE
  | VecAMX
  | VecTPU
  | VecFPGA
  | VecAuto
  | VecNone
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data VerifySpec = VerifySpec
  { vsOverflow       :: Bool
  , vsUnderflow      :: Bool
  , vsPrecision      :: PrecisionSpec
  , vsAlignment      :: Maybe Int
  , vsPipeline       :: Maybe Int
  , vsMemorySafety   :: Bool
  , vsTermination    :: Bool
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data LayoutSpec
  = LayoutRowMajor
  | LayoutColMajor
  | LayoutBlocked Int Int
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data PrecisionSpec
  = PrecFP64 | PrecFP32 | PrecFP16 | PrecBF16
  | PrecInt64 | PrecInt32 | PrecInt16 | PrecInt8
  | PrecPosits Int Int          -- (nbits, es)
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

--------------------------------------------------------------------------------
-- Theorems & Declarations
--------------------------------------------------------------------------------

data Theorem = Theorem
  { thName       :: Text
  , thTypeParams :: [Text]
  , thType       :: Type
  , thProof      :: Maybe Proof
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data Declaration
  = DTheorem Theorem
  | DFunction Text [Text] [Binder] Type Term    -- name, typeParams, params, retType, body
  | DKernel KernelSpec
  | DInductive Text [Text] (Maybe Type) [ConstructorDecl]
  | DStructure Text [Text] (Maybe Type) [FieldDecl]
  | DClass Text [Text] (Maybe Type) [MethodDecl]
  | DInstance (Maybe Text) Type [MethodImpl]
  | DModule Text [Declaration]
  | DImport Text
  | DNamespace Text [Declaration]
  deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data ConstructorDecl = ConstructorDecl
  { conName :: Text
  , conType :: Maybe Type
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data FieldDecl = FieldDecl
  { fieldName :: Text
  , fieldType :: Type
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data MethodDecl = MethodDecl
  { methodName :: Text
  , methodType :: Type
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data MethodImpl = MethodImpl
  { implName :: Text
  , implBody :: Term
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

data Module = Module
  { modName :: Text
  , modDecls :: [Declaration]
  } deriving (Eq, Ord, Show, Generic, NFData, Hashable)

--------------------------------------------------------------------------------
-- Smart Constructors for Types
--------------------------------------------------------------------------------

intT, natT, ratT, algT, symT, boolT, stringT, unitT, propT, typeT :: Type
intT      = TInt
natT      = TNat
ratT      = TRational
algT      = TAlgebraic
symT      = TSymbolic
boolT     = TBool
stringT   = TString
unitT     = TUnit
propT     = TProp
typeT     = TType

sortT :: Int -> Type
sortT n = TSort n

funT :: Type -> Type -> Type
funT = TFun

piT :: Binder -> Type -> Type
piT = TPi

sigmaT :: Binder -> Type -> Type
sigmaT = TSigma

forallT :: [Binder] -> Type -> Type
forallT = TForall

refineT :: Text -> Type -> Term -> Type
refineT = TRefine

tensorT :: Type -> [DimSpec] -> Type
tensorT = TTensor

matrixT :: Type -> DimSpec -> DimSpec -> Type
matrixT = TMatrix

quantumT :: Int -> Type
quantumT = TQuantumState

qubitT :: Type
qubitT = TQubit

quregT :: Int -> Type
quregT = TQureg

appT :: Text -> [Type] -> Type
appT = TApp

varT :: Text -> Type
varT = TVar

metaT :: Text -> Type
metaT = TMeta

--------------------------------------------------------------------------------
-- Smart Constructors for Terms
--------------------------------------------------------------------------------

var :: Text -> Term
var = Var

lam :: Binder -> Term -> Term
lam = Lam

letIn :: Binder -> Term -> Term -> Term
letIn = LetIn

app :: Term -> Term -> Term
app = App

typeApp :: Term -> [Type] -> Term
typeApp = TypeApp

sigmaE :: Binder -> Term -> Term -> Term
sigmaE = Sigma

piE :: Binder -> Term -> Term
piE = Pi

integralE :: Term -> Term -> Term -> Term -> Term
integralE = Integral

setCompE :: Term -> Binder -> Term -> Term -> Term
setCompE = SetComp

tupleE :: [Term] -> Term
tupleE = Tuple

vectorE :: Vector Term -> Term
vectorE = Vector

matrixE :: Vector (Vector Term) -> Term
matrixE = Matrix

litE :: Term
litE = LitUnit

intL :: Integer -> Term
intL = LitInt

ratL :: Scientific -> Term
ratL = LitRat

boolL :: Bool -> Term
boolL = LitBool

strL :: Text -> Term
strL = LitString

quantumGate :: Text -> [Term] -> Term
quantumGate = QGate

measureE :: Term -> Maybe Text -> Term
measureE = Measure

entangleE :: [Term] -> Term
entangleE = Entangle

qubitE :: Int -> Term
qubitE = QubitLit

kernelCallE :: Text -> [Term] -> Term
kernelCallE = KernelCall

matchE :: Term -> [MatchCase] -> Term
matchE = Match

ifE :: Term -> Term -> Term -> Term
ifE = If

--------------------------------------------------------------------------------
-- Kernel Spec Builders
--------------------------------------------------------------------------------

kernelSpec :: Text -> [Text] -> KernelSpec
kernelSpec name tps = KernelSpec
  { ksName       = name
  , ksTypeParams = tps
  , ksTargets    = [TargetLLVM]
  , ksVectorize  = VecAuto
  , ksVerify     = VerifySpec True True PrecFP64 Nothing Nothing True True
  , ksLayout     = LayoutRowMajor
  , ksPrecision  = PrecFP64
  , ksPragmas    = M.empty
  }

targetCmm, targetLLVM, targetMLIR :: KernelSpec -> KernelSpec
targetCmm  ks = ks { ksTargets = [TargetCmm] }
targetLLVM ks = ks { ksTargets = [TargetLLVM] }
targetMLIR ks = ks { ksTargets = [TargetMLIR] }

vectorizeAVX512, vectorizeNEON :: KernelSpec -> KernelSpec
vectorizeAVX512 ks = ks { ksVectorize = VecAVX512 }
vectorizeNEON   ks = ks { ksVectorize = VecNEON }

verifyOverflowFalse :: KernelSpec -> KernelSpec
verifyOverflowFalse ks = ks { ksVerify = (ksVerify ks) { vsOverflow = False } }

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

freeVars :: Term -> Set Text
freeVars = \case
  Var x           -> S.singleton x
  Lam b body      -> freeVars body S.\\ S.singleton (binderName b)
  LetIn b t1 t2   -> freeVars t1 `S.union` (freeVars t2 S.\\ S.singleton (binderName b))
  App f x         -> freeVars f `S.union` freeVars x
  TypeApp t _     -> freeVars t
  Sigma b t1 t2   -> freeVars t1 `S.union` (freeVars t2 S.\\ S.singleton (binderName b))
  Pi b t          -> freeVars t S.\\ S.singleton (binderName b)
  Integral a b f _ -> freeVars a `S.union` freeVars b `S.union` freeVars f
  SetComp e b s p -> freeVars e `S.union` freeVars s `S.union` (freeVars p S.\\ S.singleton (binderName b))
  Tuple ts        -> S.unions (map freeVars ts)
  Vector v        -> S.unions (V.toList (V.map freeVars v))
  Matrix m        -> S.unions (concatMap (V.toList . V.map freeVars) (V.toList m))
  QGate _ args    -> S.unions (map freeVars args)
  Measure q _     -> freeVars q
  Entangle qs     -> S.unions (map freeVars qs)
  KernelCall _ as -> S.unions (map freeVars as)
  Match s cs      -> freeVars s `S.union` S.unions [ freeVars (caseBody c) S.\\ patVars (casePattern c) | c <- cs ]
  If c t e        -> freeVars c `S.union` freeVars t `S.union` freeVars e
  ProofTerm{}     -> S.empty
  LitInt{}        -> S.empty
  LitRat{}        -> S.empty
  LitBool{}       -> S.empty
  LitString{}     -> S.empty
  LitUnit         -> S.empty
  QubitLit{}      -> S.empty
  where
    patVars = \case
      PVar x      -> S.singleton x
      PConstructor _ ps -> S.unions (map patVars ps)
      PTuple ps   -> S.unions (map patVars ps)
      PVector v   -> S.unions (V.toList (V.map patVars v))
      PAs x p     -> S.insert x (patVars p)
      _           -> S.empty

substitute :: Map Text Term -> Term -> Term
substitute subst = go
  where
    go = \case
      Var x -> fromMaybe (Var x) (M.lookup x subst)
      Lam b body -> Lam b (go body)
      LetIn b t1 t2 -> LetIn b (go t1) (go t2)
      App f x -> App (go f) (go x)
      TypeApp t ts -> TypeApp (go t) ts
      Sigma b t1 t2 -> Sigma b (go t1) (go t2)
      Pi b t -> Pi b (go t)
      Integral a b f d -> Integral (go a) (go b) (go f) d
      SetComp e b s p -> SetComp (go e) b (go s) (go p)
      Tuple ts -> Tuple (map go ts)
      Vector v -> Vector (V.map go v)
      Matrix m -> Matrix (V.map (V.map go) m)
      QGate g args -> QGate g (map go args)
      Measure q mb -> Measure (go q) mb
      Entangle qs -> Entangle (map go qs)
      KernelCall n as -> KernelCall n (map go as)
      Match s cs -> Match (go s) [ MatchCase p (go b) | MatchCase p b <- cs ]
      If c t e -> If (go c) (go t) (go e)
      ProofTerm pr -> ProofTerm pr
      LitInt n -> LitInt n
      LitRat r -> LitRat r
      LitBool b -> LitBool b
      LitString s -> LitString s
      LitUnit -> LitUnit
      QubitLit n -> QubitLit n

typeOf :: Term -> Maybe Type
typeOf = \case
  Var _           -> Nothing
  Lam b body      -> Just (funT (binderType b) (fromMaybe typeT (typeOf body)))
  LetIn _ _ body  -> typeOf body
  App f _         -> case typeOf f of
    Just (TFun _ ret) -> Just ret
    _                 -> Nothing
  TypeApp t _     -> typeOf t
  LitInt _        -> Just intT
  LitRat _        -> Just ratT
  LitBool _       -> Just boolT
  LitString _     -> Just stringT
  LitUnit         -> Just unitT
  QubitLit _      -> Just qubitT
  Tuple ts        -> TForall [] . TFun typeT <$> traverse typeOf ts
  Vector v        -> (\t -> tensorT t [DStatic (V.length v)]) <$> (typeOf =<< (v V.!? 0))
  Matrix m        -> do
    row <- m V.!? 0
    cell <- row V.!? 0
    t <- typeOf cell
    let rows = V.length m
        cols = V.length row
    Just (matrixT t (DStatic rows) (DStatic cols))
  QGate _ _       -> Just qubitT
  Measure _ _     -> Just TBool
  Entangle _      -> Just unitT
  KernelCall _ _  -> Nothing  -- Requires context
  Match _ []      -> Nothing
  Match _ (c:_)   -> typeOf (caseBody c)
  If _ t _        -> typeOf t
  Sigma b body _  -> Just (TSigma b (binderType b) (fromMaybe typeT (typeOf body)))
  Pi b body       -> Just (TPi b (fromMaybe typeT (typeOf body)))
  Integral{}      -> Just ratT
  SetComp _ _ _ p -> Just boolT  -- Simplified
  ProofTerm{}     -> Nothing

prettyTerm :: Term -> Text
prettyTerm = \case
  Var x         -> x
  Lam b body    -> "λ (" <> binderName b <> " : " <> prettyType (binderType b) <> ") → " <> prettyTerm body
  LetIn b t1 t2 -> "let " <> binderName b <> " := " <> prettyTerm t1 <> " in " <> prettyTerm t2
  App f x       -> "(" <> prettyTerm f <> " " <> prettyTerm x <> ")"
  TypeApp t ts  -> prettyTerm t <> "@{" <> T.intercalate ", " (map prettyType ts) <> "}"
  LitInt n      -> T.pack (show n)
  LitRat r      -> T.pack (show r)
  LitBool True  -> "true"
  LitBool False -> "false"
  LitString s   -> "\"" <> s <> "\""
  LitUnit       -> "()"
  QubitLit n    -> "q" <> T.pack (show n)
  Tuple ts      -> "(" <> T.intercalate ", " (map prettyTerm ts) <> ")"
  Vector v      -> "[" <> T.intercalate "; " (map prettyTerm (V.toList v)) <> "]"
  Matrix m      -> "[" <> T.intercalate "; " (map (\row -> T.intercalate ", " (map prettyTerm (V.toList row))) (V.toList m)) <> "]"
  QGate g args  -> g <> "(" <> T.intercalate ", " (map prettyTerm args) <> ")"
  Measure q mb  -> "measure" <> maybe "" (\b -> "{" <> b <> "}") mb <> "(" <> prettyTerm q <> ")"
  Entangle qs   -> "entangle(" <> T.intercalate ", " (map prettyTerm qs) <> ")"
  KernelCall n args -> "kernel " <> n <> "(" <> T.intercalate ", " (map prettyTerm args) <> ")"
  _             -> "<expr>"

prettyType :: Type -> Text
prettyType = \case
  TInt          -> "Int"
  TNat          -> "Nat"
  TRational     -> "Rational"
  TAlgebraic    -> "Algebraic"
  TSymbolic     -> "Symbolic"
  TBool         -> "Bool"
  TString       -> "String"
  TUnit         -> "Unit"
  TProp         -> "Prop"
  TType         -> "Type"
  TSort n       -> "Sort " <> T.pack (show n)
  TFun a b      -> prettyType a <> " → " <> prettyType b
  TPi b body    -> "Π (" <> binderName b <> " : " <> prettyType (binderType b) <> "), " <> prettyType body
  TSigma b body -> "Σ (" <> binderName b <> " : " <> prettyType (binderType b) <> "), " <> prettyType body
  TForall bs t  -> "∀ " <> T.intercalate ", " (map (\b -> "(" <> binderName b <> " : " <> prettyType (binderType b) <> ")") bs) <> ", " <> prettyType t
  TRefine x t _ -> "{ " <> x <> " : " <> prettyType t <> " | ... }"
  TTensor t ds  -> "Tensor [" <> prettyType t <> "] {" <> T.intercalate " × " (map prettyDim ds) <> "}"
  TMatrix t r c -> "Matrix [" <> prettyType t <> "] {" <> prettyDim r <> " × " <> prettyDim c <> "}"
  TQuantumState n -> "QuantumState [" <> T.pack (show n) <> "]"
  TQubit        -> "Qubit"
  TQureg n      -> "Qureg [" <> T.pack (show n) <> "]"
  TApp n ts     -> n <> "{" <> T.intercalate ", " (map prettyType ts) <> "}"
  TVar x        -> "?" <> x
  TMeta x       -> "?" <> x

prettyDim :: DimSpec -> Text
prettyDim (DStatic n) = T.pack (show n)
prettyDim (DParam x)  = x
prettyDim DDynamic    = "?"
