{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeFamilies          #-}

module Render where

import           Apecs
import           Apecs.Types
import           Data.Foldable
import           Data.Maybe                           (fromMaybe)
import           Graphics.Gloss                       as G
import           Graphics.Gloss.Geometry.Angle
import           Graphics.Gloss.Interface.IO.Simulate
import           Linear.V2

import           Instances                            as P
import           Shape                                as P
import           Types                                as P
import           Wrapper                              as P

toPicture :: Shape -> Picture
toPicture (Shape (P.Circle (V2 x y) radius) _) = translate (realToFrac x) (realToFrac y) $ circle (realToFrac radius)
toPicture (Shape (Segment a b radius) _) = Line [v2ToTuple a, v2ToTuple b]
toPicture (Shape (Convex verts radius) _) = Line (v2ToTuple <$> verts)

v2ToTuple (V2 x y) = (realToFrac x, realToFrac y)

drawWorld :: (Has w Physics, Has w Color) => w -> IO Picture
drawWorld w = runWith w . fmap fold . cimapM $ \(ety, (Position (V2 x y), Angle theta, Shapes sh)) -> do
  let pic = foldMap toPicture sh
      rotated = rotate (negate . radToDeg . realToFrac $ theta) pic
      translated = translate (realToFrac x) (realToFrac y) rotated
  Safe mcolor :: Safe Color <- get (cast ety)
  return . color (fromMaybe white mcolor) $ translated

simulateWorld :: (Has w Color, Has w Physics) => Display -> Float -> IO w -> System w a -> IO ()
simulateWorld disp scaleFactor initialWorld intializeSys = do
    w <- initialWorld
    runSystem intializeSys w
    simulateIO disp black 60 w (fmap (scale scaleFactor scaleFactor) . drawWorld) stepSys
  where
    stepSys viewport dT w = do
      runSystem (stepPhysicsSys $ realToFrac dT) w
      return w

instance Component Color where
  type Storage Color = Map Color
