module Main (main) where

import Test.Tasty
import Test.Tasty.HUnit
import qualified Data.Text as T
import MathLib5.Parser (parseModule)
import MathLib5.IR.Typed

main :: IO ()
main = defaultMain $ testGroup "Parser Tests"
  [ testGroup "Basic Parsing"
      [ testCase "Parse simple theorem" testParseSimpleTheorem
      , testCase "Parse function declaration" testParseFunctionDecl
      , testCase "Parse kernel declaration" testParseKernelDecl
      ]
  , testGroup "Type Parsing"
      [ testCase "Parse base types" testParseBaseTypes
      , testCase "Parse function type" testParseFunctionType
      , testCase "Parse dependent type" testParseDependentType
      ]
  , testGroup "Expression Parsing"
      [ testCase "Parse lambda" testParseLambda
      , testCase "Parse let binding" testParseLet
      , testCase "Parse quantum gate" testParseQuantumGate
      ]
  ]

testParseSimpleTheorem :: Assertion
testParseSimpleTheorem = do
  let input = "theorem add_comm (a b : Nat) : a + b = b + a"
  case parseModule input of
    Right (Module _ [DTheorem th]) -> do
      assertEqual "name should be add_comm" "add_comm" (thName th)
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseFunctionDecl :: Assertion
testParseFunctionDecl = do
  let input = "function add (x y : Int) : Int := x + y"
  case parseModule input of
    Right (Module _ [DFunction name _ _ _ _]) ->
      assertEqual "name should be add" "add" name
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseKernelDecl :: Assertion
testParseKernelDecl = do
  let input = "kernel MatrixMultiply : { target = LLVM, vectorize = AVX512, precision = fp64 }"
  case parseModule input of
    Right (Module _ [DKernel ks]) -> do
      assertEqual "name should be MatrixMultiply" "MatrixMultiply" (ksName ks)
      assertEqual "target should be LLVM" [TargetLLVM] (ksTargets ks)
      assertEqual "vectorize should be AVX512" VecAVX512 (ksVectorize ks)
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseBaseTypes :: Assertion
testParseBaseTypes = do
  let input = "function f (x : Int) : Nat := x"
  case parseModule input of
    Right (Module _ [DFunction _ _ [b] retTy _]) -> do
      assertEqual "param type should be Int" TInt (binderType b)
      assertEqual "return type should be Nat" TNat retTy
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseFunctionType :: Assertion
testParseFunctionType = do
  let input = "function apply (f : Int → Int) (x : Int) : Int := f x"
  case parseModule input of
    Right (Module _ [DFunction _ _ [fb, xb] retTy _]) -> do
      assertEqual "first param type should be Int → Int" (TFun TInt TInt) (binderType fb)
      assertEqual "second param type should be Int" TInt (binderType xb)
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseDependentType :: Assertion
testParseDependentType = do
  let input = "function vec (n : Nat) : Tensor [Int] { n } := []"
  case parseModule input of
    Right (Module _ [DFunction _ _ [nb] retTy _]) -> do
      assertEqual "param type should be Nat" TNat (binderType nb)
      case retTy of
        TTensor TNat [DParam "n"] -> pure ()
        _ -> assertFailure $ "Expected Tensor type with param, got " ++ show retTy
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseLambda :: Assertion
testParseLambda = do
  let input = "function id : (Int → Int) := λ (x : Int) → x"
  case parseModule input of
    Right (Module _ [DFunction _ _ [] (TFun TInt TInt) (Lam b body)]) -> do
      assertEqual "binder name should be x" "x" (binderName b)
      assertEqual "binder type should be Int" TInt (binderType b)
      assertEqual "body should be Var x" (Var "x") body
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration with lambda, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseLet :: Assertion
testParseLet = do
  let input = "function f : Int := let x : Int := 5 in x"
  case parseModule input of
    Right (Module _ [DFunction _ _ [] _ (LetIn b val body)]) -> do
      assertEqual "let binding name should be x" "x" (binderName b)
      assertEqual "let value should be 5" (LitInt 5) val
      assertEqual "let body should be Var x" (Var "x") body
    Right (Module _ decls) -> assertFailure $ "Expected 1 declaration with let, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err

testParseQuantumGate :: Assertion
testParseQuantumGate = do
  let input = "function bell : Qubit := H(q0)"
  case parseModule input of
    Right (Module _ [DFunction _ _ [] _ (QGate "H" [QubitLit 0])]) -> pure ()
    Right (Module _ decls) -> assertFailure $ "Expected H gate, got " ++ show (length decls)
    Left err -> assertFailure $ "Parse failed: " ++ show err
