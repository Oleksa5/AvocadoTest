Import-Module AvocadoTest -Force -DisableNameChecking
Import-Module AvocadoCore -Force -Prefix Core -DisableNameChecking

$PSModuleAutoLoadingPreference = 'None'
$WarningPreference             = 'Continue'
$ErrorActionPreference         = 'Stop'

#region Aliases
#——————————————

  Set-Alias -Name NewTest              -Value New-CoreTest
  Set-Alias -Name ExpectCondition      -Value Expect-CoreCondition
  Set-Alias -Name FormatFunctionScheme -Value Format-CoreFunctionScheme
  Set-Alias -Name FormatExtendedTable  -Value Format-CoreExtendedTable
  Set-Alias -Name FormatExpanded       -Value Format-CoreExpanded
  Set-Alias -Name FormatExpect         -Value Format-CoreExpect
  Set-Alias -Name FormatException      -Value Format-CoreException

#—————————
#endregion

try {
  switch (0..2) {
  0 {
  NewTest -Group "Item factory" -R "Test item" -First {

    NewTest "No arguments" -R "Object with no property values" -First {
      #region Code
      #———————————

        $argmnt = New-TestArgument
        $output = New-TestOutput
        $object = New-TestObject

      #—————————
      #endregion
      #region Format
      #—————————————

        FormatFunctionScheme  `
          ''  New-TestArgument argmnt  `
          ''  New-TestOutput   output  `
          ''  New-TestObject   object

        FormatExtendedTable ([ordered]@{
          argmnt = $argmnt
          output = $output
          object = $object
        })

      #—————————
      #endregion
    }

    NewTest "All arguments" -R "Object" {
      #region Code
      #———————————

        $argmnt = New-TestArgument num0 1
        $output = New-TestOutput   num1 5
        $object = New-TestObject   num2 3

      #—————————
      #endregion
      #region Format
      #—————————————

        FormatFunctionScheme `
          'name, object' New-TestArgument argmnt `
          'name, object' New-TestOutput   output `
          'name, object' New-TestObject   object

        FormatExtendedTable ([ordered]@{
          argmnt = $argmnt
          output = $output
          object = $object
        })

      #—————————
      #endregion
    }
  }
  } 1 {
  NewTest -Group "Expect-Condition" -R "Object | null" {

    NewTest "No arguments" -R "null" -First {
      #region Code
      #———————————

        $expect = Expect-Condition

      #—————————
      #endregion
      #region Format
      #—————————————

        FormatFunctionScheme '' Expect-Condition null/expect

        FormatExtendedTable ([ordered]@{ expect = $expect })

      #—————————
      #endregion
    }

    NewTest "All arguments" -R "" {
      #region Code
      #———————————

        $expect = Expect-Condition { $true  },
                                    "true condition",
                                    "true is always true",
                                    { $false },
                                    "false condition"

      #—————————
      #endregion
      #region Format
      #—————————————

        FormatFunctionScheme `
          'scripts,strings/conditions' Expect-Condition expect

        FormatExtendedTable $expect -Parent expect -ForceExpandable

      #—————————
      #endregion
    }
  }
  } 2 {
  NewTest -Group "Create and invoke test" -R "Test" {
    #region Testee
    #—————————————

      function DoNothing {}

      $added = $false

      function AddNumbers {
        param (
          $number0,
          $number1
        )

        $number0 + $number1
        $script:added = $true
      }

      $tests = [ordered]@{}
      $allComponents = [List[Object]]::new()

      function TestTest {
        param ($test)

        ExpectCondition `
          { $null     -ne    $test      },
          { $test     -isnot [array]    },
          { $test     -isnot [string]   },
          { $test.GetType().IsClass     },
          { 'Initial' -eq    $test.Phas }
      }

      function FormatExpectTest {
        FormatExpect `
          "test isn't null",
          "test isn't array",
          "test isn't string",
          "test is class",
          "phase is initial"
      }

    #—————————
    #endregion

    NewTest "No arguments" -R "Test" -First {
      #region Code
      #———————————

        $o = New-Test

      #—————————
      #endregion
      #region Test
      #———————————

        TestTest $o

        $components = '', 'New-Test', 'noarg'

        $tests['noarg'] = $o
        $allComponents.AddRange($components)

        FormatFunctionScheme $components
        FormatExtendedTable $o

      #—————————
      #endregion
    }

    NewTest "No script" -R "Test" {
      #region Code
      #———————————

        $o = New-Test 1 'NoScript' "does nothing"

      #—————————
      #endregion
      #region Test
      #———————————

        TestTest $o

        $components = 'index, function, name', 'New-Test', 'noscr'

        $tests['noscr'] = $o
        $allComponents.AddRange($components)

        FormatFunctionScheme $components
        FormatExtendedTable $o

      #—————————
      #endregion
    }

    NewTest "All arguments" -R "Test"{
      #region Code
      #———————————

        $o = New-Test 0 'DoNothing' "does nothing" { DoNothing }

      #—————————
      #endregion
      #region Test
      #———————————

        $o1 = New-Test 0 'DoNothing' "does nothing" { DoNothing }

        TestTest $o
        TestTest $o1

        $components = 'index, function, name, script', 'New-Test', 'allarg'

        $tests['allarg' ] = $o
        $tests['allarg1'] = $o1
        $allComponents.AddRange($components)

        FormatFunctionScheme $components
        FormatExtendedTable $o

      #—————————
      #endregion
    }

    NewTest "Set shared props, then create a test specifying no args" -R "Test" {
      #region Code
      #———————————

        $o0 = New-Test 0 'DoNothing' "does nothing" { DoNothing }
        $o1 = Set-Test $o0
        $o2 = New-Test

      #—————————
      #endregion
      #region Test
      #———————————

        ExpectCondition `
          { -not [Object]::ReferenceEquals($o0, $o2) },
          { $null -ne $o0.Scrp },
          { $null -eq $o2.Scrp },
          { $null -eq $o1      }

        TestTest $o0
        TestTest $o2

        $components =
          'index, function, name, script', 'New-Test', 'set',
          'set/test'                     , 'Set-Test', 'null',
          ''                             , 'New-Test', 'newset'

        $tests['set']    = $o0
        $tests['newset'] = $o2
        $allComponents.AddRange($components)

        FormatFunctionScheme $components
        FormatExtendedTable  $o0, $o1, $o2
        FormatExpect `
          "set output is null",
          "new test isn't shared",
          "set test script isn't null",
          "new test script is null",
          "a script isn't a shared prop"

      #—————————
      #endregion
    }

    NewTest "New-Test with a script that outputs test items" -R "Test" {
      #region Code
      #———————————

        $o = New-Test 0 'AddNumbers' "1" {
          $added0 = $added

          $argument00 = 1
          $argument01 = 3
          $argument10 = 1.5
          $argument11 = 3.25
          $output0 = AddNumbers $argument00 $argument01
          $output1 = AddNumbers $argument10 $argument11

          $added1 = $added

          New-TestFunction AddNumbers
          New-TestArgument argument00 $argument00
          New-TestArgument argument01 $argument01
          New-TestOutput   output0    $output0
          New-TestObject   added0     $added0
          New-TestObject   added1     $added1
          Expect-Condition { $null    -ne $output0 },
                           { $output0 -is [int]    },
                             "Output is integer if arguments are integer",
                           { $output0 -eq 4        },
                             "1 plus 3 equals 4",
                           { $added0  -eq $false   },
                           { $added1  -eq $true    },
                             "Records if it was called"

          New-TestFunction AddNumbers
          New-TestArgument argument10 $argument10
          New-TestArgument argument11 $argument11
          New-TestOutput   output1   $output1
          Expect-Condition { $null    -ne $output1 },
                           { $output1 -is [double] },
                             "Output is integer if arguments are integer",
                           { $output1 -eq 4.75     },
                             "1.5 plus 3.25 equals 4.75"
        }

      #—————————
      #endregion
      #region Test
      #———————————

        TestTest $o

        $components = 'index, function, name, script', 'New-Test', 'withitems'

        $tests['withitems'] = $o
        $allComponents.AddRange($components)

        FormatFunctionScheme $components
        FormatExtendedTable $o
        FormatExpanded $o

      #—————————
      #endregion
    }

    NewTest "All tests" -R "" {
      FormatFunctionScheme $allComponents
      FormatExtendedTable $tests -Parent tests
      FormatExpectTest
    }

    NewTest "Invoke-Test may" -R "Complete test" {
      #region Test & Code
      #——————————————————

        foreach ($test in $tests.GetEnumerator()) {
          $key  = $test.Key
          $test = $test.Value

          if ($key -ne 'allarg1') {
            #region Code
            #———————————

              $o = Invoke-Test $test

            #—————————
            #endregion

            ExpectCondition { $null -eq $o }

          } else {
            #region Code
            #———————————

              $o = Invoke-Test $test -PassThru

            #—————————
            #endregion

            ExpectCondition `
              { $null -ne $o },
              { [Object]::ReferenceEquals($o, $test) }
          }
        }

      #—————————
      #endregion
      #region Test
      #———————————

        ExpectCondition `
          { 'Initial'  -eq $tests['noarg'    ].Phas },
          { 'Initial'  -eq $tests['noscr'    ].Phas },
          { 'Initial'  -eq $tests['newset'   ].Phas },
          { 'Complete' -eq $tests['allarg'   ].Phas },
          { 'Complete' -eq $tests['set'      ].Phas },
          { 'Complete' -eq $tests['withitems'].Phas }

      #—————————
      #endregion
      #region Format
      #—————————————

        FormatFunctionScheme        `
          'test' Invoke-Test 'null' `
          'test -PassThru' Invoke-Test 'test'

        FormatExtendedTable $tests -Parent tests -ForceExpandable

        FormatExpanded $tests['withitems'] -Name 'tests.withitems' <# -ShowTypes #>

        FormatExpect `
          "noarg, noscr, newset tests are initial",
          "allarg, set, withitems tests are complete",
          "invoke output is null if no PassThru",
          "invoke argument & output are the same object if PassThru"

      #—————————
      #endregion
    }
  }
  }
  }
} catch {
  FormatException $_
}