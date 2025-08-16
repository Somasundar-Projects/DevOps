param(
    # [Parameter(Mandatory = $true)]
    [string]$NewRepoName = "SP.Core.Common",
    # [Parameter(Mandatory = $true)]
    [string]$NewProjectName = "SP.Core.Common",
    # [Parameter(Mandatory = $true)]
    [string]$GitHubOrg = "Somasundar-Projects",
    # [Parameter(Mandatory = $true)]
    [string]$TemplateRepo = "Somasundar-Projects/DevOps",
    # [Parameter(Mandatory = $true)]
    [string]$TargetFrameworks = "net8.0;net9.0"
)

# Temp working folder
$TempPath = "repo-$NewRepoName"
if (Test-Path $TempPath) { Remove-Item -Recurse -Force $TempPath }
git clone "https://github.com/$TemplateRepo.git" $TempPath

Set-Location "$TempPath/Templates/Library"

# Convert target frameworks to version format (e.g., "8.x")
$frameworkVersions = $TargetFrameworks.Split(';') | ForEach-Object {
    if ($_ -match 'net(\d+)\.0') {
        "$($matches[1]).x"
    } else {
        $_
    }
}
$frameworkVersionString = $frameworkVersions -join ';'
$frameworkVersionString = "'" + ($frameworkVersionString.Split(';') | ConvertTo-Json -Compress) + "'"

# Handle .github folder separately
$githubPath = "./.github/workflows"

if (Test-Path $githubPath) {
    $githubFiles = Get-ChildItem -Path $githubPath -Recurse -File
    foreach ($file in $githubFiles) {
        (Get-Content $file.FullName) |
            ForEach-Object { $_ -replace 'Template.Library.CICD.TargetFrameworks', $frameworkVersionString } |
            ForEach-Object { $_ -replace "Template.Library", $NewProjectName } |
            Set-Content $file.FullName
    }
}

# Replace placeholders in all files
$files = Get-ChildItem -Recurse -File
foreach ($file in $files) {
    (Get-Content $file.FullName) |
        ForEach-Object { $_ -replace "Template.Library.TargetFrameworks", $TargetFrameworks } |
        ForEach-Object { $_ -replace "Template.Library.Company", "Somasundar Projects" } |
        ForEach-Object { $_ -replace "Template.Library.Authors", "Somasundar" } |
        ForEach-Object { $_ -replace "Template.Library.Product", "Somasundar Library" } |
        ForEach-Object { $_ -replace "Template.Library.Logging.Abstractions.Version", "8.0.0" } |
        ForEach-Object { $_ -replace "Template.Library.Options.Version", "8.0.2" } |
        ForEach-Object { $_ -replace "Template.Library.Http.Version", "2.3.0" } |
        ForEach-Object { $_ -replace "Template.Library.Coverlet.Collector.Version", "6.0.2" } |
        ForEach-Object { $_ -replace "Template.Library.Microsoft.NET.Test.Sdk.Version", "17.12.0" } |
        ForEach-Object { $_ -replace "Template.Library.Xunit.Version", "2.9.2" } |
        ForEach-Object { $_ -replace "Template.Library.Xunit.Runner.VisualStudio.Version", "2.8.2" } |
        ForEach-Object { $_ -replace "Template.Library", $NewProjectName } |
        Set-Content $file.FullName
}

# Rename project files/folders if needed
Rename-Item "Template.Library.sln" "$NewProjectName.sln"
Move-Item "./src/Template.Library" "./src/$NewProjectName"
Move-Item "./tests/Template.Library.Tests" "./tests/$NewProjectName.Tests"

$OldPath = Join-Path -Path "./src/$NewProjectName" -ChildPath "Template.Library.csproj"
$NewPath = Join-Path -Path "./src/$NewProjectName" -ChildPath "$NewProjectName.csproj"
Rename-Item -Path $OldPath -NewName (Split-Path $NewPath -Leaf)

$OldPath = Join-Path -Path "./tests/$NewProjectName.Tests" -ChildPath "Template.Library.Tests.csproj"
$NewPath = Join-Path -Path "./tests/$NewProjectName.Tests" -ChildPath "$NewProjectName.Tests.csproj"

Rename-Item -Path $OldPath -NewName (Split-Path $NewPath -Leaf)

# Create new GitHub repo using gh CLI
if (-not (Test-Path ".git")) {
    git init
    git add .
    git commit -m "Initial commit from Repo Template"
}
gh repo create "$NewProjectName" --public --source=. --remote=origin --push

Write-Host "🎉 Repo $NewRepoName created and pushed!"