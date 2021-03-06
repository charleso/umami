{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE LambdaCase #-}
module Umami.Pretty.Simple (
    SimpleDoc(..)
  , simpleDocOfDoc
  ) where

import qualified    Umami.Pretty.Base as D

import              P

data SimpleDoc a
 = Empty
 -- Perhaps surprisingly, making the remainder document strict is detrimental to performance
 | Text   !Text (SimpleDoc a)
 | Space        (SimpleDoc a)
 | Line         (SimpleDoc a)
 | Tab          (SimpleDoc a)
 | IndentOn     (SimpleDoc a)
 | IndentNo     (SimpleDoc a)
 | AnnotOn  !a  (SimpleDoc a)
 | AnnotNo  !a  (SimpleDoc a)
 deriving (Eq, Ord, Show)

simpleDocOfDoc :: D.Doc a -> SimpleDoc a
simpleDocOfDoc
 = fst . convert Empty

convert :: SimpleDoc a -> D.Doc a -> (SimpleDoc a, Bool)
convert rest
 = \case
    D.Empty     -> (rest, False)
    D.Text t    -> (Text t rest, True)
    D.Space     -> (Space  rest, False)
    D.Line      -> (Line   rest, False)
    D.Tab       -> (Tab    rest, False)
    D.Indent d
     -> let (d',de) = convert (IndentNo rest) d
        in  (IndentOn d', de)

    D.CatWith cf l m r
     -> let (r',re) = convert rest r
            (m',_)  = convert r' m
            (l',le) = convert m' l
        in if   cfun cf re le
           then (l', True)
           else (fst $ convert r' l, re || le)
    D.Annotate a d
     -> let (d',de) = convert (AnnotNo a rest) d
        in  (AnnotOn a d', de)

 where
  cfun D.CatFunAnd = (&&)
  cfun D.CatFunOr  = (||)

