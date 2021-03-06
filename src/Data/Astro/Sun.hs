{-|
Module: Data.Astro.Sun
Description: Calculation characteristics of the Sun
Copyright: Alexander Ignatyev, 2016

= Calculation characteristics of the Sun.

== /Terms/

* __perihelion__ - minimal distance from the Sun to the planet
* __aphelion__ - maximal distance from the Sun to the planet

* __perigee__ - minimal distance from the Sun to the Earth
* __apogee__ - maximal distance from the Sun to the Earth


= Example

@
import Data.Astro.Time.JulianDate
import Data.Astro.Coordinate
import Data.Astro.Types
import Data.Astro.Sun

ro :: GeographicCoordinates
ro = GeoC (fromDMS 51 28 40) (-(fromDMS 0 0 5))

dt :: LocalCivilTime
dt = lctFromYMDHMS (DH 1) 2017 6 25 10 29 0

today :: LocalCivilDate
today = lcdFromYMD (DH 1) 2017 6 25

jd :: JulianDate
jd = lctUniversalTime dt

verticalShift :: DecimalDegrees
verticalShift = refract (DD 0) 12 1012

-- distance from the Earth to the Sun in kilometres
distance :: Double
distance = sunDistance jd
-- 1.5206375976421073e8

-- Angular Size
angularSize :: DecimalDegrees
angularSize = sunAngularSize jd
-- DD 0.5244849215333616

-- The Sun's coordinates
ec1 :: EquatorialCoordinates1
ec1 = sunPosition2 jd
-- EC1 {e1Declination = DD 23.37339098989099, e1RightAscension = DH 6.29262026252748}

hc :: HorizonCoordinates
hc = ec1ToHC ro jd ec1
-- HC {hAltitude = DD 49.312050979507404, hAzimuth = DD 118.94723825710143}


-- Rise and Set
riseSet :: RiseSetMB
riseSet = sunRiseAndSet ro 0.833333 today
-- RiseSet
--    (Just (2017-06-25 04:44:04.3304 +1.0,DD 49.043237261724215))
--    (Just (2017-06-25 21:21:14.4565 +1.0,DD 310.91655607595595))
@
-}

module Data.Astro.Sun
(
  SunDetails(..)
  , RiseSet(..)
  , sunDetails
  , j2010SunDetails
  , sunMeanAnomaly2
  , sunEclipticLongitude1
  , sunEclipticLongitude2
  , sunPosition1
  , sunPosition2
  , sunDistance
  , sunAngularSize
  , sunRiseAndSet
  , equationOfTime
  , solarElongation
)

where

import qualified Data.Astro.Utils as U
import Data.Astro.Types (DecimalDegrees(..), DecimalHours(..)
                        , toDecimalHours, fromDecimalHours
                        , toRadians, fromRadians
                        , GeographicCoordinates(..) )
import Data.Astro.Time.JulianDate (JulianDate(..), LocalCivilTime(..), LocalCivilDate(..), numberOfDays, numberOfCenturies, splitToDayAndTime, addHours)
import Data.Astro.Time.Sidereal (gstToUT, dhToGST)
import Data.Astro.Time.Epoch (j1900, j2010)
import Data.Astro.Coordinate (EquatorialCoordinates1(..), EclipticCoordinates(..), eclipticToEquatorial)
import Data.Astro.Effects.Nutation (nutationLongitude)
import Data.Astro.CelestialObject.RiseSet (RiseSet(..), RiseSetMB, RSInfo(..), riseAndSet2)
import Data.Astro.Sun.SunInternals (solveKeplerEquation)


-- | Details of the Sun's apparent orbit at the given epoch
data SunDetails = SunDetails {
  sdEpoch :: JulianDate             -- ^ Epoch
  , sdEpsilon :: DecimalDegrees     -- ^ Ecliptic longitude at the Epoch
  , sdOmega :: DecimalDegrees       -- ^ Ecliptic longitude of perigee at the Epoch
  , sdE :: Double                   -- ^ Eccentricity of the orbit at the Epoch
  } deriving (Show)

-- | SunDetails at the Sun's reference Epoch J2010.0
j2010SunDetails :: SunDetails
j2010SunDetails = SunDetails j2010 (DD 279.557208) (DD 283.112438) 0.016705


-- | Semi-major axis
r0 :: Double
r0 = 1.495985e8


-- | Angular diameter at r = r0
theta0 :: DecimalDegrees
theta0 = DD 0.533128


-- | Reduce the value to the range [0, 360)
reduceTo360 :: Double -> Double
reduceTo360 = U.reduceToZeroRange 360


-- | Reduce the value to the range [0, 360)
reduceDegrees :: DecimalDegrees -> DecimalDegrees
reduceDegrees = U.reduceToZeroRange 360


-- | Calculate SunDetails for the given JulianDate.
sunDetails :: JulianDate -> SunDetails
sunDetails jd =
  let t = numberOfCenturies j1900 jd
      epsilon = reduceTo360 $ 279.6966778 + 36000.76892*t + 0.0003025*t*t
      omega = reduceTo360 $ 281.2208444 + 1.719175*t + 0.000452778*t*t
      e = 0.01675104 - 0.0000418*t - 0.000000126*t*t
  in SunDetails jd (DD epsilon) (DD omega) e


-- | Calculate the ecliptic longitude of the Sun with the given SunDetails at the given JulianDate
sunEclipticLongitude1 :: SunDetails -> JulianDate -> DecimalDegrees
sunEclipticLongitude1 sd@(SunDetails epoch (DD eps) (DD omega) e) jd =
  let d = numberOfDays epoch jd
      n = reduceTo360 $ (360/U.tropicalYearLen) * d
      meanAnomaly = reduceTo360 $ n + eps - omega
      ec = (360/pi)*e*(sin $ U.toRadians meanAnomaly)
      DD nutation = nutationLongitude jd
  in DD $ reduceTo360 $ n + ec + eps + nutation


-- | Calculate Equatorial Coordinates of the Sun with the given SunDetails at the given JulianDate.
-- It is recommended to use 'j2010SunDetails' as a first parameter.
sunPosition1 :: SunDetails -> JulianDate -> EquatorialCoordinates1
sunPosition1 sd jd =
  let lambda = sunEclipticLongitude1 sd jd
      beta = DD 0
  in eclipticToEquatorial (EcC beta lambda) jd


-- | Calculate mean anomaly using the second 'more accurate' method
sunMeanAnomaly2 :: SunDetails -> DecimalDegrees
sunMeanAnomaly2 sd = reduceDegrees $ (sdEpsilon sd) - (sdOmega sd)


-- | Calculate true anomaly using the second 'more accurate' method
trueAnomaly2 :: SunDetails -> DecimalDegrees
trueAnomaly2 sd =
  let m = toRadians $ sunMeanAnomaly2 sd
      e = sdE sd
      bigE = solveKeplerEquation e m 0.000000001
      tanHalfNu = sqrt((1+e)/(1-e)) * tan (0.5 * bigE)
      nu = reduceTo360 $ U.fromRadians $ 2 * (atan tanHalfNu)
  in DD nu


-- | Calculate the ecliptic longitude of the Sun
sunEclipticLongitude2 :: SunDetails -> DecimalDegrees
sunEclipticLongitude2 sd =
  let DD omega = sdOmega sd
      DD nu = trueAnomaly2 sd
      DD nutation = nutationLongitude $ sdEpoch sd
  in DD $ reduceTo360 $ nu + omega + nutation


-- | More accurate method to calculate position of the Sun
sunPosition2 :: JulianDate -> EquatorialCoordinates1
sunPosition2 jd =
  let sd = sunDetails jd
      lambda = sunEclipticLongitude2 sd
      beta = DD 0
  in eclipticToEquatorial (EcC beta lambda) jd


-- Distance and Angular Size helper function
dasf sd =
  let e = sdE sd
      nu = toRadians $ trueAnomaly2 sd
  in (1 + e*(cos nu)) / (1 - e*e)


-- | Calculate Sun-Earth distance.
sunDistance :: JulianDate -> Double
sunDistance jd = r0 / (dasf $ sunDetails jd)


-- | Calculate the Sun's angular size (i.e. its angular diameter).
sunAngularSize :: JulianDate -> DecimalDegrees
sunAngularSize jd = theta0 * (DD $ dasf $ sunDetails jd)


-- | Calculatesthe Sun's rise and set
-- It takes coordinates of the observer,
-- local civil date,
-- vertical shift (good value is 0.833333).
-- It returns Nothing if fails to calculate rise and/or set.
-- It should be accurate to within a minute of time.
sunRiseAndSet :: GeographicCoordinates
                 -> DecimalDegrees
                 -> LocalCivilDate
                 -> RiseSetMB
sunRiseAndSet = riseAndSet2 0.000001 (sunPosition1 j2010SunDetails)


-- | Calculates discrepancy between the mean solar time and real solar time
-- at the given date.
equationOfTime :: JulianDate -> DecimalHours
equationOfTime jd =
  let (day, _) = splitToDayAndTime jd
      midday = addHours (DH 12) day  -- mean solar time
      EC1 _ ra = sunPosition1 j2010SunDetails midday
      ut = gstToUT day $ dhToGST ra
      JD time = midday - ut
  in DH $ time*24


-- | Calculates the angle between the lines of sight to the Sun and to a celestial object
-- specified by the given coordinates at the given Universal Time.
solarElongation :: EquatorialCoordinates1 -> JulianDate -> DecimalDegrees
solarElongation (EC1 deltaP alphaP) jd =
  let (EC1 deltaS alphaS) = sunPosition1 j2010SunDetails jd
      deltaP' = toRadians deltaP
      alphaP' = toRadians $ fromDecimalHours alphaP
      deltaS' = toRadians deltaS
      alphaS' = toRadians $ fromDecimalHours alphaS
      eps = acos $ (sin deltaP')*(sin deltaS') + (cos $ alphaP' - alphaS')*(cos deltaP')*(cos deltaS')
  in fromRadians eps
