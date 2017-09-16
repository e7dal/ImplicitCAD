-- Implicit CAD. Copyright (C) 2011, Christopher Olah (chris@colah.ca)
-- Copyright 2014 2015 2016, Julia Longtin (julial@turinglace.com)
-- Released under the GNU AGPLV3+, see LICENSE

-- Allow us to use explicit foralls when writing function type declarations.
{-# LANGUAGE ExplicitForAll #-}

module Graphics.Implicit.Export.Render.GetLoops (getLoops) where

-- Explicitly include what we want from Prelude.
import Prelude (Eq, head, last, tail, (==), Bool(False), (.), null, error, (++))

import Data.List (partition)
-- The goal of getLoops is to extract loops from a list of segments.

-- The input is a list of segments.
-- the output a list of loops, where each loop is a list of 
-- segments, which each piece representing a "side".

-- For example:
-- Given input [[1,2],[5,1],[3,4,5]] 
-- notice that there is a loop 1,2,3,4,5... <repeat>
-- But we give the output [ [1,2], [3,4,5], [5,1] ]
-- so that we have the loop, and also knowledge of how
-- the list is built (the "sides" of it).

getLoops :: Eq a => [[a]] -> [[[a]]]

-- We will be actually doing the loop extraction with
-- getLoops'

-- getLoops' has a first argument of the segments as before,
-- but a *second argument* which is the loop presently being
-- built.

-- so we begin with the "building loop" being empty.

getLoops a = getLoops' a []

getLoops' :: Eq a => [[a]] -> [[a]] -> [[[a]]]

-- If there aren't any segments,
-- and the "building loop" is empty, 
-- we produce no loops.

getLoops' [] [] = []

-- If the building loop is empty,
-- we stick the first segment we have onto it
-- to give us something to build on.

getLoops' (x:xs) [] = getLoops' xs [x]

-- A loop is finished if its start and end are the same.
-- In this case, we return it and start searching for another loop.

getLoops' segs workingLoop | head (head workingLoop) == last (last workingLoop) =
    workingLoop : getLoops' segs []

-- Finally, we search for pieces that can continue the working loop,
-- and stick one on if we find it.
-- Otherwise... something is really screwed up.

getLoops' segs workingLoop =
    let
        presEnd :: forall c. [[c]] -> c
        presEnd = last . last
        connects (x:_) = x == presEnd workingLoop
        connects [] = False -- Handle the empty case.
        -- divide our set into sequences that connect, and sequences that don't.
        (possibleConts,nonConts) = partition connects segs
        (next, unused) = if null possibleConts
            then error "unclosed loop in paths given"
            else (head possibleConts, tail possibleConts ++ nonConts)
    in
        if null next
        then workingLoop : getLoops' segs []
        else getLoops' unused (workingLoop ++ [next])

