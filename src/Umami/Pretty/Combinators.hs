{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE OverloadedStrings #-}
module Umami.Pretty.Combinators (
    emptyDoc, text, line, space, tab, indent
  , (</>), (<+>), (<#>)
  , hsep, vcat, hcat
  , annotate

  , encloseSep, punctuate
  , joinIf, joinAlways
  , prefixIf, suffixIf
  , emptyNotWhite
  ) where

import              Umami.Pretty.Base

import              P


{-
list :: [Doc a] -> Doc a
list            = encloseSep lbracket rbracket comma

tupled :: [Doc a] -> Doc a
tupled          = encloseSep lparen   rparen  comma

semiBraces :: [Doc a] -> Doc a
semiBraces      = encloseSep lbrace   rbrace  semi

-}

hsep :: [Doc a] -> Doc a
hsep = punctuate space

vcat :: [Doc a] -> Doc a
vcat = punctuate line

hcat :: [Doc a] -> Doc a
hcat = punctuate emptyDoc


emptyDoc :: Doc a
emptyDoc = Empty


text :: Text -> Doc a
text = Text

line :: Doc a
line = Line

tab :: Doc a
tab = Tab

space :: Doc a
space = Space

indent :: Doc a -> Doc a
indent = Indent


infixr 5 </>
infixr 6 <+>

(</>) :: Doc a -> Doc a -> Doc a
(</>) = joinIf line

(<+>) :: Doc a -> Doc a -> Doc a
(<+>) = joinIf space

(<#>) :: Doc a -> Doc a -> Doc a
(<#>) = joinAlways tab


joinIf :: Doc a -> Doc a -> Doc a -> Doc a
joinIf m l r = CatWith CatFunAnd l m r

prefixIf :: Doc a -> Doc a -> Doc a
prefixIf l r = CatWith CatFunOr emptyDoc l r

suffixIf :: Doc a -> Doc a -> Doc a
suffixIf r l = CatWith CatFunOr l r emptyDoc

joinAlways :: Doc a -> Doc a -> Doc a -> Doc a
joinAlways m l r = l <> m <> r

-- TODO: this should really be a primitive, and text "" should be considered white
-- Or, 'text' and literal IsString should strip white, while providing a textRaw function that does not strip
emptyNotWhite :: Doc a
emptyNotWhite = Text ""

annotate :: a -> Doc a -> Doc a
annotate a d = Annotate a d


punctuate :: Doc a -> [Doc a] -> Doc a
punctuate _ []      = emptyDoc
punctuate _ [d]     = d
punctuate p (d:ds)  = joinIf p d (punctuate d ds)


encloseSep :: Doc a -> Doc a -> Doc a -> [Doc a] -> Doc a
encloseSep left right sep ds
 = left <> punctuate sep ds <> right

