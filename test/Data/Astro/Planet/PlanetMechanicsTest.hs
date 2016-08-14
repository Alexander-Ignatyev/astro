module Data.Astro.Planet.PlanetMechanicsTest
(
  tests
)

where


import Test.Framework (testGroup)
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.HUnit
import Test.HUnit.Approx
import Test.QuickCheck


import Data.Astro.TypesTest (testDecimalDegrees)
import Data.Astro.CoordinateTest (testEC1)

import Data.Astro.Types (DecimalDegrees(..), DecimalHours(..))
import Data.Astro.Time.JulianDate (JulianDate(..))
import Data.Astro.Time.Epoch (j2010)
import Data.Astro.Coordinate (EquatorialCoordinates1(..))
import Data.Astro.Planet.PlanetDetails (Planet(..), j2010PlanetDetails)
import Data.Astro.Planet.PlanetMechanics

nov222003 = JD 2452965.5
jupiterDetails = j2010PlanetDetails Jupiter
earthDetails = j2010PlanetDetails Earth

tests = [testGroup "mechanics" [
            testDecimalDegrees "jupiter mean anomaly"
                0.0000001
                137.8097641
                (planetMeanAnomaly jupiterDetails nov222003)
            , testDecimalDegrees "jupiter true anomaly"
                0.0000001
                141.5736000
                (planetTrueAnomaly1 jupiterDetails nov222003)
            , testDecimalDegrees "planetHeliocentricLongitude"
                0.0000001
                114.6633
                (planetHeliocentricLongitude jupiterDetails 100)
            , testDecimalDegrees "planetHeliocentricLatitude"
                0.0000001
                1.1220101
                (planetHeliocentricLatitude jupiterDetails 160)
            , testCase "planetHeliocentricRadiusVector" $ assertApproxEqual ""
                0.0000001
                5.4403612
                (planetHeliocentricRadiusVector jupiterDetails 160)
            , testDecimalDegrees "planetProjectedLongitude"
                0.0000001
                159.9935029
                (planetProjectedLongitude jupiterDetails 160)
            , testCase "planetProjectedRadiusVector" $ assertApproxEqual ""
                0.0000001
                5.4387668
                (planetProjectedRadiusVector jupiterDetails 1.22 5.44)
            , testDecimalDegrees "planetEclipticLongitude"
                0.0000001
                169.793671
                (planetEclipticLongitude 160 5.43 59 0.988)
            , testDecimalDegrees "planetEclipticLatitude"
                0.0000001
                1.1861236
                (planetEclipticLatitude 1.22 160 5.43 59 0.988 170)
            , testEC1 "planetPosition1"
                0.0000001
                (EC1 (DD 6.3569686) (DH 11.1871664))
                (planetPosition1 jupiterDetails earthDetails nov222003)
            , testEC1 "planetPosition"
                0.0000001
                (planetPosition1 jupiterDetails earthDetails nov222003)
                (planetPosition planetTrueAnomaly1 jupiterDetails earthDetails nov222003)
            ]
        ]

