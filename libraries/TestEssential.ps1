using namespace System.Collections.Generic

<#
.SYNOPSIS
Essential test functionality.
.DESCRIPTION
The library provides essential functionality needed
to run a test. This doesn't include test formatting.
The library allows to collect as much information as
possible about a test and test objects.
.IMPLEMENTATION
Possible names for the library: TestBase, BareTest, TestEssential
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='Expect-*')]
param()

#region NewTest
#——————————————

  enum TestPhase {
    Uninit
    Initial
    Complete
  }

  class Test {
    [TestPhase     ] $Phas
    [string        ] $Indx
    [string        ] $Func
    [string        ] $Name
    [scriptblock   ] $Scrp
    [FunctionTest[]] $TstF
    [Test        []] $Test
  }

  <#
  .SYNOPSIS
  Create a test object.
  .DESCRIPTION
  Creates a new test object. Default
  value for each argument except Scrp
  is the corresponding value of a test
  previously set by Set-Test or null if
  no test is set.
  .PARAMETER Indx
  Index of the test.
  .PARAMETER Func
  .PARAMETER Name
  .PARAMETER Scrp
  Script that returns test objects known by
  Invoke-Test.
  .EFFECTS
  No side effects.
  .OUTPUTS
  Test
  #>
  function New-Test {
    [OutputType([Test])]
    param (
      [string]      $Indx,
      [string]      $Func,
      [string]      $Name,
      [scriptblock] $Scrp
    )

    $test = [Test]::new()

    $test.Indx = $Indx ? $Indx : $script:test.Indx
    $test.Name = $Name ? $Name : $script:test.Name
    $test.Func = $Func ? $Func : $script:test.Func
    $test.Scrp = $Scrp
    $test.Phas = 'Initial'

    $test
  }

  [Test] $test = $null

  <#
  .SYNOPSIS
  Set a test for default values for new tests.
  .DESCRIPTION
  Sets a test used by New-Test to provide default
  values for the arguments.
  .PARAMETER Test
  .EFFECTS
  Set or reset a test object.
  .OUTPUTS
  #>
  function Set-Test {
    [OutputType([void])]
    param(
      [Test] $Test
    )

    $script:test = $Test
  }

#endregion

#region NewFunctionTest
#——————————————————————

  class FunctionTest {
    [string      ] $Func
    [TestObject[]] $Argm
    [TestObject  ] $Outp
    [TestObject[]] $Objc
    [TestExpect[]] $Expc
  }

  <#
  .SYNOPSIS
  Create a function test object.
  .DESCRIPTION
  This function is used by Invoke-Test to
  compete tests.
  .PARAMETER Func
  Function name.
  .PARAMETER Argm
  Arguments for the function.
  .PARAMETER Outp
  Function output.
  .PARAMETER Objc
  Other objects possibly affected by
  the function.
  .PARAMETER Expc
  Expected condition objects.
  .EFFECTS
  No side effects.
  .OUTPUTS
  Test
  #>
  function New-FunctionTest {
    [OutputType([Test])]
    param (
      [string      ] $Func,
      [TestObject[]] $Argm,
      [TestObject  ] $Outp,
      [TestObject[]] $Objc,
      [TestExpect[]] $Expc
    )

    $test = [FunctionTest]::new()

    $test.Func = $Func
    $test.Argm = $Argm
    $test.Outp = $Outp
    $test.Objc = $Objc
    $test.Expc = $Expc

    $test
  }

#endregion

#region RunTest
#——————————————

  #region TestItems
  #————————————————

    #region TestFunction
    #———————————————————

      class TestFunction {
        [string] $Name
      }

      <#
      .SYNOPSIS
      Specify function name.
      .PARAMETER Name
      .OUTPUTS
      TestFunction
      #>
      function New-TestFunction {
        [OutputType([TestFunction])]
        param (
          [string] $Name
        )

        $function = [TestFunction]::new()
        $function.Name = $Name
        $function
      }

    #endregion

    #region TestObject
    #—————————————————

      class TestObject {
        [String] $Name
        [Object] $Value
      }

      <#
      .SYNOPSIS
      Create an object for a test.
      .PARAMETER Type
      Type of the test object.
      .PARAMETER Name
      .PARAMETER Value
      .OUTPUTS
      Object of a class derived from TestObject.
      #>
      function NewTestObject {
        [OutputType([TestObject])]
        param (
          [string] $Type,
          [string] $Name,
          [Object] $Value
        )

        $object = New-Object $Type
        $object.Name = $Name
        $object.Value = $Value
        $object
      }

      <#
      .SYNOPSIS
      Specify an object.
      .PARAMETER Name
      .PARAMETER Value
      .OUTPUTS
      TestObject
      #>
      function New-TestObject {
        [OutputType([TestObject])]
        param (
          [string] $Name,
          [Object] $Value
        )

        NewTestObject TestObject $Name $Value
      }

    #endregion

    #region TestArgument
    #———————————————————

      class TestArgument : TestObject {
        # TODO: ParameterName property
      }

      <#
      .SYNOPSIS
      Specify an argument.
      .PARAMETER Name
      .PARAMETER Value
      .OUTPUTS
      TestArgument
      #>
      function New-TestArgument {
        [OutputType([TestArgument])]
        param (
          [string] $Name,
          [Object] $Value
        )

        NewTestObject TestArgument $Name $Value
      }

    #endregion

    #region TestOutput
    #—————————————————

      class TestOutput : TestObject {}

      <#
      .SYNOPSIS
      Specify an output.
      .PARAMETER Name
      .PARAMETER Value
      .OUTPUTS
      TestOutput
      #>
      function New-TestOutput {
        [OutputType([TestOutput])]
        param (
          [string] $Name,
          [Object] $Value
        )

        NewTestObject TestOutput $Name $Value
      }

    #endregion

    #region TestExpect
    #—————————————————

      class TestExpect {
        [scriptblock] $Condition
        [bool]        $Output
        [string[]]    $Premise
      }

      <#
      .SYNOPSIS
      Create an expected condition.
      .PARAMETER Condition
      Scriptblock that outputs an object convertible
      to a boolean.
      .PARAMETER Output
      Output of the condition script.
      .PARAMETER Premise
      Reasons for the conditions.
      .OUTPUTS
      TestExpect
      #>
      function NewTestExpect {
        [OutputType([TestExpect])]
        param (
          [scriptblock] $Condition,
          [bool]        $Output,
          [string[]]    $Premise
        )

        $testExpect = [TestExpect]::new()
        $testExpect.Condition = $Condition
        $testExpect.Output    = $Output
        $testExpect.Premise   = $Premise
        $testExpect
      }

      <#
      .SYNOPSIS
      Assert conditions are true.
      .DESCRIPTION
      Unlike AvocadoCore\Expect-Condition, doesn't throw
      an exception, but passes the result of a condition
      to the TestExpect factory.
      .PARAMETER Conditions
      Condition scripts to assert with their premises.
      A condition is a scriptblock that outputs an object
      convertible to a boolean.

      An array of objects should have the form:

      script/condition, 0 or n strings/premises,
      script/condition, 0 or n strings/premises,
      ...
      script/condition, 0 or n strings/premises
      .EFFECTS
      No side effects.
      .OUTPUTS
      TestExpect
      #>
      function Expect-Condition {
        [OutputType([TestExpect])]
        param (
          [Object[]] $Conditions
        )

        $core = Get-Module AvocadoCore
        $prefix = $core.Prefix

        &"Expect-${prefix}Condition" $Conditions `
          -OnSuccess { param($cnd, $prm) NewTestExpect $cnd $true  $prm } `
          -OnFailure { param($cnd, $prm) NewTestExpect $cnd $false $prm }
      }

    #endregion

  #endregion

  <#
  .SYNOPSIS
  Invoke and complete a test.
  .DESCRIPTION
  Invokes and modifies a test only if it's in the initial
  phase and the test's script isn't null. Otherwise the test
  is unchanged.
  .EFFECTS
  Modifies the test.
  .EXCEPTION
  Throws a string message if the test is in the uninitialized phase.
  .OUTPUTS
  void
  By default there is no output.

  Test
  If PassThru is specified and Test is not null, outputs the same
  Test object that is provided as an argument.
  #>
  function Invoke-Test {
    [OutputType(
      [void],
      [Test])]
    param (
      [Test]   $Test,
      [switch] $PassThru
    )

    #region Lib
    #——————————

      function CheckInitialized {
        [OutputType([void])]
        param ([Test] $Test)

        if ($Test.Phas -eq [TestPhase]::Uninit) {
          throw "Provided test is uninitialized."
        }
      }

      function IsInvokable {
        [OutputType([bool])]
        param ([Test] $Test)

        ($Test.Phas -eq [TestPhase]::Initial) -and
        ($null      -ne $Test.Scrp)
      }

      class FunctionTestAccm {
        [string          ] $Func
        [List[TestObject]] $Argm = [List[TestObject]]::new()
        [TestObject      ] $Outp
        [List[TestObject]] $Objc = [List[TestObject]]::new()
        [List[TestExpect]] $Expc = [List[TestExpect]]::new()

        [FunctionTest] ToFunctionTest() {
          return New-FunctionTest `
            $this.Func $this.Argm `
            $this.Outp $this.Objc `
            $this.Expc
        }
      }

      function FillItems {
        [OutputType([void])]
        param (
          [Test]     $Test,
          [Object[]] $Items
        )

        $functionTests = [List[FunctionTest]]::new()
        $accum = $null

        foreach ($item in $Items) {
          if ($item -is [TestFunction]) {
            if ($accum) {
            $functionTests.Add($accum.ToFunctionTest())
            }
            $accum = [FunctionTestAccm]::new()
          }

          switch ($item.GetType()) {
            TestFunction { $accum.Func   = $item.Name  }
            TestArgument { $accum.Argm.Add($item)      }
            TestOutput   { $accum.Outp   = $item       }
            TestObject   { $accum.Objc.Add($item)      }
            TestExpect   { $accum.Expc.Add($item)      }
            Default      { throw "Unknown test item type: $_" }
          }
        }

        if ($accum) {
        $functionTests.Add($accum.ToFunctionTest())
        }
        $Test.TstF = $functionTests
      }

    #endregion

    CheckInitialized $Test

    if (IsInvokable $Test) {
      $items = &$Test.Scrp
      FillItems $Test $items

      $Test.Phas = [TestPhase]::Complete
    }

    if ($PassThru) {
      $Test
    }
  }

#endregion

Export-ModuleMember @(
  'New-TestFunction'
  'New-TestArgument'
  'New-TestOutput'
  'New-TestObject'
  'Expect-Condition'
  'New-Test'
  'Set-Test'
  'Invoke-Test'
)