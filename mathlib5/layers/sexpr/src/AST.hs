{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module AST where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Data.Hashable (Hashable)
import Data.Text (Text)

data SExpr
  = Atom Text
  | List [SExpr]
  | Number Double
  | String Text
  deriving (Show, Eq, Generic)

instance ToJSON SExpr
instance FromJSON SExpr
instance Hashable SExpr
