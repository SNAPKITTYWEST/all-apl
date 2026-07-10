> {-# LANGUAGE LiquidHaskell #-}
> module Refinements where

This is a literate Haskell file with Liquid Haskell refinements.

> {-@ type Nat = {v:Int | v >= 0} @-}

> {-@ checkNat :: Nat -> Bool @-}
> checkNat :: Int -> Bool
> checkNat n = n >= 0
