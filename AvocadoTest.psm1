Get-ChildItem "$PSScriptRoot\libraries\*.ps1" -Recurse |
  ForEach-Object {
    if (($_.Name -notmatch "copy" )) {
      . $_
    }
  }