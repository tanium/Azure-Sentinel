[CmdletBinding()]
param($runId, $pullRequestNumber, $instrumentationKey, $baseFolderPath, $defaultPackageVersion, $isPRMerged
)

Write-Host "Inside of package on Pull Request!"
Write-Host "RunId $runId, PR Number $pullRequestNumber"


try {
    # Normalize base folder path
    $baseFolderPath = Join-Path -Path $baseFolderPath -ChildPath ''
    $baseFolderPath = $baseFolderPath -replace "//", "/"

    Write-Host "====Identifying Solution Name===="
    # Get Solution Name
    . $PSScriptRoot/getSolutionName.ps1 $runId $pullRequestNumber $instrumentationKey $isPRMerged
    # outputs: solutionName

    if ([string]::IsNullOrWhiteSpace($solutionName)) {
        Write-Warning "Solution name not found. Exiting."
        exit 0
    }

    Write-Host "SolutionName is $solutionName"

    Write-Host "====Is New or Existing Solution===="
    # Identify New or Existing Solution
    . $PSScriptRoot/newOrExistingSolution.ps1 $solutionName $pullRequestNumber $runId $baseFolderPath $instrumentationKey $isPRMerged
    # outputs : isNewSolution, offerId, publisherId, solutionSupportedBy

    Write-Host "isNewSolution $isNewSolution, offerId $offerId, publisherId $publisherId"

    Write-Host "====Check if packaging is required===="
    # Check SkipPackagingInfo i.e check if we need to skip packaging process or not
    . $PSScriptRoot/checkSkipPackagingInfo.ps1 $solutionName $pullRequestNumber $runId $baseFolderPath $instrumentationKey $isPRMerged
    # outputs: $isPackagingRequired either true or null

    if ($null -eq $isPackagingRequired -or $isPackagingRequired -eq $false) {
        Write-Host "Packaging is not required. Exiting."
        exit 0
    }

    Write-Host "====Packaging process started===="
    . $PSScriptRoot/package-generator.ps1 $solutionName $pullRequestNumber $runId $instrumentationKey $defaultPackageVersion $offerId $baseFolderPath $isNewSolution $isPRMerged
}
catch {
    Write-Error "Error occurred in package-service script. Error Details: $_"
    exit 1
}