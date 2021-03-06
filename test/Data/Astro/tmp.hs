          , testGroup "AU: standard typeclasses" [
              testCase "show" $ "AU 15.5" @=? show (AU 15.5)
              , testCase "showList" $ "[AU 15.3,AU 15.7]" @=? showList [AU 15.3, AU 15.7] ""
              , testCase "showsPrec" $ "AU 15.5" @=? showsPrec 0 (AU 15.5) ""
              , testCase "== (True)" $ True @=? (AU 15.5) == (AU 15.5)
              , testCase "== (False)" $ False @=? (AU 15.3) == (AU 15.5)
              , testCase "/= (True)" $ True @=? (AU 15.3) /= (AU 15.5)
              , testCase "/= (False)" $ False @=? (AU 15.5) /= (AU 15.5)
              , testCase "compare: LT" $ LT @=? (AU 15.3) `compare` (AU 15.5)
              , testCase "compare: EQ" $ EQ @=? (AU 15.5) `compare` (AU 15.5)
              , testCase "compare: GT" $ GT @=? (AU 15.7) `compare` (AU 15.5)
              , testCase "<" $ True @=? (AU 15.3) < (AU 15.7)
              , testCase "<=" $ True @=? (AU 15.3) <= (AU 15.7)
              , testCase ">" $ False @=? (AU 15.3) > (AU 15.7)
              , testCase ">=" $ False @=? (AU 15.3) >= (AU 15.7)
              , testCase "max" $ (AU 15.7) @=? max (AU 15.3) (AU 15.7)
              , testCase "min" $ (AU 15.3) @=? min (AU 15.3) (AU 15.7)
              , testCase "abs" $ (AU 15.7) @=? abs (AU (-15.7))
              , testCase "signum > 0" $ (AU 1.0) @=? signum (AU 15.5)
              , testCase "signum = 0" $ (AU 0.0) @=? signum (AU 0.0)
              , testCase "signum < 0" $ (AU $ -1.0) @=? signum (AU $ -15.5)
              , testCase "toRational" $ (31 % 2) @=? toRational (AU 15.5)
              , testCase "recip" $ (AU 0.01) @=? recip (AU 100)
              , testCase "properFraction" $ (15, AU 0.5) @=? properFraction (AU 15.5)
              ]
