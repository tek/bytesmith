{-# language FlexibleInstances #-}
{-# language MagicHash #-}
{-# language MultiParamTypeClasses #-}
{-# language RankNTypes #-}
{-# language ScopedTypeVariables #-}
{-# language TypeInType #-}
{-# language UnboxedSums #-}
{-# language UnboxedTuples #-}

-- | This is a giant hack to let authors of high-performance use
-- levity-polymorphic variants of @>>=@, @>>@, and @pure@.
module Data.Bytes.Parser.Rebindable
  ( Bind(..)
  , Pure(..)
  , Join(..)
  ) where

import Prelude () 
import GHC.Exts (TYPE,RuntimeRep(..))
import Data.Bytes.Parser.Internal (Parser(..))

class Bind (ra :: RuntimeRep) (rb :: RuntimeRep) where
  (>>=) :: forall e s (a :: TYPE ra) (b :: TYPE rb).
    Parser e s a -> (a -> Parser e s b) -> Parser e s b
  (>>) :: forall e s (a :: TYPE ra) (b :: TYPE rb).
    Parser e s a -> Parser e s b -> Parser e s b

class Pure (ra :: RuntimeRep) where
  pure :: forall e s (a :: TYPE ra). a -> Parser e s a

class Join (ra :: RuntimeRep) where
  join :: forall e s (a :: TYPE ra).
    Parser e s (Parser e s a) -> Parser e s a

pureParser :: a -> Parser e s a
{-# inline pureParser #-}
pureParser a = Parser
  (\(# _, b, c #) s -> (# s, (# | (# a, b, c #) #) #))

bindParser :: Parser e s a -> (a -> Parser e s b) -> Parser e s b
{-# inline bindParser #-}
bindParser (Parser f) g = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# y, b, c #) #) ->
        runParser (g y) (# arr, b, c #) s1
  )

sequenceParser :: Parser e s a -> Parser e s b -> Parser e s b
{-# inline sequenceParser #-}
sequenceParser (Parser f) (Parser g) = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# _, b, c #) #) -> g (# arr, b, c #) s1
  )

pureIntParser :: forall (a :: TYPE 'IntRep) e s.
  a -> Parser e s a
{-# inline pureIntParser #-}
pureIntParser a = Parser
  (\(# _, b, c #) s -> (# s, (# | (# a, b, c #) #) #))

bindIntParser :: forall (a :: TYPE 'IntRep) e s b.
  Parser e s a -> (a -> Parser e s b) -> Parser e s b
{-# inline bindIntParser #-}
bindIntParser (Parser f) g = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# y, b, c #) #) ->
        runParser (g y) (# arr, b, c #) s1
  )

sequenceIntParser :: forall (a :: TYPE 'IntRep) e s b.
  Parser e s a -> Parser e s b -> Parser e s b
{-# inline sequenceIntParser #-}
sequenceIntParser (Parser f) (Parser g) = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# _, b, c #) #) -> g (# arr, b, c #) s1
  )

pureIntPairParser :: forall (a :: TYPE ('TupleRep '[ 'IntRep, 'IntRep])) e s.
  a -> Parser e s a
{-# inline pureIntPairParser #-}
pureIntPairParser a = Parser
  (\(# _, b, c #) s -> (# s, (# | (# a, b, c #) #) #))

bindIntPairParser :: forall (a :: TYPE ('TupleRep '[ 'IntRep, 'IntRep])) e s b.
  Parser e s a -> (a -> Parser e s b) -> Parser e s b
{-# inline bindIntPairParser #-}
bindIntPairParser (Parser f) g = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# y, b, c #) #) ->
        runParser (g y) (# arr, b, c #) s1
  )

sequenceIntPairParser :: forall (a :: TYPE ('TupleRep '[ 'IntRep, 'IntRep])) e s b.
  Parser e s a -> Parser e s b -> Parser e s b
{-# inline sequenceIntPairParser #-}
sequenceIntPairParser (Parser f) (Parser g) = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# _, b, c #) #) -> g (# arr, b, c #) s1
  )

instance Bind 'LiftedRep 'LiftedRep where
  {-# inline (>>=) #-}
  {-# inline (>>) #-}
  (>>=) = bindParser
  (>>) = sequenceParser

instance Bind 'IntRep 'LiftedRep where
  {-# inline (>>=) #-}
  {-# inline (>>) #-}
  (>>=) = bindIntParser
  (>>) = sequenceIntParser

instance Bind ('TupleRep '[ 'IntRep, 'IntRep]) 'LiftedRep where
  {-# inline (>>=) #-}
  {-# inline (>>) #-}
  (>>=) = bindIntPairParser
  (>>) = sequenceIntPairParser

instance Bind 'LiftedRep ('TupleRep '[ 'IntRep, 'IntRep]) where
  {-# inline (>>=) #-}
  {-# inline (>>) #-}
  (>>=) = bindFromLiftedToIntPair
  (>>) = sequenceLiftedToIntPair

instance Bind 'IntRep ('TupleRep '[ 'IntRep, 'IntRep]) where
  {-# inline (>>=) #-}
  {-# inline (>>) #-}
  (>>=) = bindFromIntToIntPair
  (>>) = sequenceIntToIntPair

instance Bind 'LiftedRep 'IntRep where
  {-# inline (>>=) #-}
  {-# inline (>>) #-}
  (>>=) = bindFromLiftedToInt
  (>>) = sequenceLiftedToInt

instance Pure 'LiftedRep where
  {-# inline pure #-}
  pure = pureParser

instance Pure 'IntRep where
  {-# inline pure #-}
  pure = pureIntParser

instance Pure ('TupleRep '[ 'IntRep, 'IntRep]) where
  {-# inline pure #-}
  pure = pureIntPairParser

bindFromIntToIntPair ::
     forall s e
       (a :: TYPE 'IntRep)
       (b :: TYPE ('TupleRep '[ 'IntRep, 'IntRep ])).
     Parser s e a
  -> (a -> Parser s e b)
  -> Parser s e b
{-# inline bindFromIntToIntPair #-}
bindFromIntToIntPair (Parser f) g = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# y, b, c #) #) ->
        runParser (g y) (# arr, b, c #) s1
  )

sequenceIntToIntPair ::
     forall s e
       (a :: TYPE 'IntRep)
       (b :: TYPE ('TupleRep '[ 'IntRep, 'IntRep ])).
     Parser s e a
  -> Parser s e b
  -> Parser s e b
{-# inline sequenceIntToIntPair #-}
sequenceIntToIntPair (Parser f) (Parser g) = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# _, b, c #) #) -> g (# arr, b, c #) s1
  )

bindFromLiftedToIntPair ::
     forall s e
       (a :: TYPE 'LiftedRep)
       (b :: TYPE ('TupleRep '[ 'IntRep, 'IntRep ])).
     Parser s e a
  -> (a -> Parser s e b)
  -> Parser s e b
{-# inline bindFromLiftedToIntPair #-}
bindFromLiftedToIntPair (Parser f) g = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# y, b, c #) #) ->
        runParser (g y) (# arr, b, c #) s1
  )

sequenceLiftedToIntPair ::
     forall s e
       (a :: TYPE 'LiftedRep)
       (b :: TYPE ('TupleRep '[ 'IntRep, 'IntRep ])).
     Parser s e a
  -> Parser s e b
  -> Parser s e b
{-# inline sequenceLiftedToIntPair #-}
sequenceLiftedToIntPair (Parser f) (Parser g) = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# _, b, c #) #) -> g (# arr, b, c #) s1
  )

bindFromLiftedToInt ::
     forall s e
       (a :: TYPE 'LiftedRep)
       (b :: TYPE 'IntRep).
     Parser s e a
  -> (a -> Parser s e b)
  -> Parser s e b
{-# inline bindFromLiftedToInt #-}
bindFromLiftedToInt (Parser f) g = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# y, b, c #) #) ->
        runParser (g y) (# arr, b, c #) s1
  )

sequenceLiftedToInt ::
     forall s e
       (a :: TYPE 'LiftedRep)
       (b :: TYPE 'IntRep).
     Parser s e a
  -> Parser s e b
  -> Parser s e b
{-# inline sequenceLiftedToInt #-}
sequenceLiftedToInt (Parser f) (Parser g) = Parser
  (\x@(# arr, _, _ #) s0 -> case f x s0 of
    (# s1, r0 #) -> case r0 of
      (# e | #) -> (# s1, (# e | #) #)
      (# | (# _, b, c #) #) -> g (# arr, b, c #) s1
  )