[CmdletBinding(PositionalBinding=$True)]
Param(
    [Parameter(Mandatory = $true)]
    [String]$ClusterSshUrl,                         # required
    [Parameter(Mandatory = $true)]
    [String]$ClusterSshUsername,                    # required
    [Parameter(Mandatory = $true)]
    [String]$ClusterSshPassword,                    # required
    [Parameter(Mandatory = $true)]
    [String]$JarPath,                               # required    path of the jar in WASB to submit
    [Parameter(Mandatory = $true)]
    [String]$ClassName,                             # required
    [String]$AdditionalParams                       # optional    at least include the topology name
    )

###########################################################
# Start - Initialization - Invocation, Logging etc
###########################################################
$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

& "$scriptDir\..\init.ps1"
if(-not $?)
{
    throw "Initialization failure."
    exit -9999
}
###########################################################
# End - Initialization - Invocation, Logging etc
###########################################################

function Run-Command($command, $commandOption, $commandArg1, $commandArg2)
{
  $failure = $false
  try
  {
      Write-InfoLog "Running command: $command $commandOption $commandArg1 $commandArg2" (Get-ScriptName) (Get-ScriptLineNumber)
      & $command $commandOption $commandArg1 $commandArg2 | Out-Host
      
      if($?)
      {
          Write-SpecialLog "Successfully ran command: $command" (Get-ScriptName) (Get-ScriptLineNumber)
      }
      else
      {
          $failure = $true
      }
  }
  catch
  {
      $failure = $true
      Write-ErrorLog "Exception encountered while invoking the command $command at: $ClusterSshUrl" (Get-ScriptName) (Get-ScriptLineNumber) $_
  }
  return $failure
}

$failure = $false

$JarDir = Split-Path $JarPath
$JarName = Split-Path $JarPath -Leaf

Write-SpecialLog "Cluster SSH Password: $ClusterSshPassword" (Get-ScriptName) (Get-ScriptLineNumber)

$PrevDir = Get-Location
$dummy = Set-Location $JarDir
if(Test-Path $JarName) 
{ 
    Write-InfoLog "$JarName found in $JarDir" (Get-ScriptName) (Get-ScriptLineNumber)
}
else
{
    Write-WarnLog "$JarName not found in $JarDir" (Get-ScriptName) (Get-ScriptLineNumber)
}

$retry = 0

while($retry -lt 3)
{
    $failure = Run-Command "scp" "-p" "$JarName" "$ClusterSshUsername`@$ClusterSshUrl`:~/$JarName"
    
    if($failure)
    {
        Write-WarnLog "Topology upload encountered an error, retrying..." (Get-ScriptName) (Get-ScriptLineNumber)
    }
    else
    {
        Write-SpecialLog "Successfully uploaded topology jar: $JarName" (Get-ScriptName) (Get-ScriptLineNumber)
        break
    }
    $retry++
}

$dummy = Set-Location $PrevDir

if($failure)
{
    Write-ErrorLog "Topology upload encountered an error, please check logs for error information." (Get-ScriptName) (Get-ScriptLineNumber)
    throw "Topology submission encountered an error, please check logs for error information and retry again."
}

$failure = Run-Command "ssh" "" "$ClusterSshUsername`@$ClusterSshUrl" "storm jar ~/$JarName $ClassName $AdditionalParams"
if($failure)
{
      Write-WarnLog "Topology submission encountered an error, please check logs for error information and retry." (Get-ScriptName) (Get-ScriptLineNumber)
      #throw "Topology submission encountered an error, please check logs for error information and retry."
}
else
{
    Write-SpecialLog "Successfully submitted topology: $ClassName" (Get-ScriptName) (Get-ScriptLineNumber)
}
