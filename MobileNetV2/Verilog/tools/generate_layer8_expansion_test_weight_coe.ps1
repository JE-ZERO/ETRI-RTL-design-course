param(
    [string]$OutputPath = (
        Join-Path $PSScriptRoot "..\mem\layer8_expansion_weight_pin4_test.coe"
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cin = 64
$cout = 384
$pin = 4
$weightWidth = 16
$groupsPerFilter = $cin / $pin
$romDepth = $cout * $groupsPerFilter

function Get-TestWeight {
    param(
        [int]$OutputChannel,
        [int]$InputChannel
    )

    # Small signed integers make waveform and golden-model checks easy.
    # The formula is deterministic, varies across both channel indices,
    # and produces values in the inclusive range -8 through 7.
    return (($OutputChannel * 5 + $InputChannel * 3) % 16) - 8
}

function Convert-ToSigned16Hex {
    param([int]$Value)

    if ($Value -lt -32768 -or $Value -gt 32767) {
        throw "Value $Value does not fit in signed 16 bits."
    }

    $encoded = if ($Value -lt 0) { 65536 + $Value } else { $Value }
    return "{0:X4}" -f $encoded
}

$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput

if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add("memory_initialization_radix=16;")
$lines.Add("memory_initialization_vector=")

for ($n = 0; $n -lt $cout; $n++) {
    for ($mGroup = 0; $mGroup -lt $groupsPerFilter; $mGroup++) {
        $laneHex = [string[]]::new($pin)

        for ($lane = 0; $lane -lt $pin; $lane++) {
            $m = $mGroup * $pin + $lane
            $weight = Get-TestWeight -OutputChannel $n -InputChannel $m
            $laneHex[$lane] = Convert-ToSigned16Hex -Value $weight
        }

        # Lane mapping:
        #   dout[15:0]  = weight[n][m+0]
        #   dout[31:16] = weight[n][m+1]
        #   dout[47:32] = weight[n][m+2]
        #   dout[63:48] = weight[n][m+3]
        # Hex text is therefore emitted in lane 3,2,1,0 order.
        $word = $laneHex[3] + $laneHex[2] + $laneHex[1] + $laneHex[0]
        $address = $n * $groupsPerFilter + $mGroup
        $terminator = if ($address -eq ($romDepth - 1)) { ";" } else { "," }
        $lines.Add($word + $terminator)
    }
}

$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllLines($resolvedOutput, $lines, $utf8NoBom)

Write-Output "Generated: $resolvedOutput"
Write-Output "ROM width: 64 bits"
Write-Output "ROM depth: $romDepth words"
Write-Output "Packed weights: $($cout * $cin)"

