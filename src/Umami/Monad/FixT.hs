-- | Monad transformer for evaluating to a fixpoint
-- The idea is that some transforms need to be run multiple times.
-- Deciding whether to run a transform again can be somewhat tedious though,
-- as you cannot necessarily just run some transform @f@ on @x@ until @f x == x@.
--
-- This might not be ideal for a few reasons:
-- * @x@ might not implement @Eq@;
-- * @x@ might implement @Eq@, but could contain floats of @NaN@, in which case @NaN /= NaN@; or
-- * checking equality can be expensive.
--
-- Instead, this provides a function called @progress@, with the same type as @return@,
-- that marks the current transform as having "made progress": that is, it should be re-run again.
-- Then you can provide @fixpoint@ with a function of type @a -> FixT _ a@, which will be re-run
-- until no progress is made.
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE BangPatterns      #-}
module Umami.Monad.FixT (
      FixT   (..)
    , Progress (..)
    , fixpoint
    , once
    , fixOfMaybe
    , progress
    ) where

import              P

import              Control.Monad.Trans.Class

-- | Fixpoint monad transformer.
newtype FixT m a
 = FixT
 { runFixT :: m (a, Progress) }

-- | Have we made progress?
data Progress
 = RunAgain
 | NoProgress
 deriving (Eq, Ord, Show)

-- | Apply the transform until it no longer makes progress
fixpoint :: Monad m => (a -> FixT m a) -> a -> m a
fixpoint f a
 = do (a',prog) <- runFixT $! f a
      case prog of
       RunAgain   -> fixpoint f a'
       NoProgress -> return a'
{-# INLINE fixpoint #-}

-- | Run a FixT once, regardless of whether it believes it makes progress or not
once :: Monad m => FixT m a -> m a
once f
 = do (r,_) <- runFixT f
      return r
{-# INLINE once #-}

-- | Take a function that returns @Just@ on progress and @Nothing@ on completion.
fixOfMaybe :: Monad m => (a -> m (Maybe a)) -> a -> FixT m a
fixOfMaybe f a
 = do a' <- lift $ f $! a
      case a' of
       Just a''-> progress a''
       Nothing -> return a
{-# INLINE fixOfMaybe #-}

eitherProgress :: Progress -> Progress -> Progress
eitherProgress RunAgain _ = RunAgain
eitherProgress _ RunAgain = RunAgain
eitherProgress _ _        = NoProgress
{-# INLINE eitherProgress #-}

-- | Return a value and proclaim: "it might be worth running again"
progress :: Monad m => a -> FixT m a
progress a
 = FixT $ return (a, RunAgain)
{-# INLINE progress #-}

instance Monad m => Monad (FixT m) where
 (>>=) p q
  = FixT
  $ do  (res,prog)   <- runFixT $! p
        (res',prog') <- runFixT $! q res
        return (res', eitherProgress prog prog')

 return a = FixT $ return (a, NoProgress)

instance Monad m => Functor (FixT m) where
 fmap f p
  = p >>= (return . f)

instance Monad m => Applicative (FixT m) where
 pure = return
 (<*>) f x
  = do !f' <- f
       !x' <- x
       return $! f' x'

instance MonadTrans FixT where
 lift m
  = FixT
  $ do  v <- m
        return (v, NoProgress)


