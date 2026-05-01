$ErrorActionPreference = "Stop"

$godotConsoleExe = "C:\Users\Usuario\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
$godotGuiExe = "C:\Users\Usuario\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe"
$godotExe = ""

if (Test-Path $godotConsoleExe) {
    $godotExe = $godotConsoleExe
} elseif (Test-Path $godotGuiExe) {
    $godotExe = $godotGuiExe
} else {
    Write-Error "Godot executable not found. Checked:`n- $godotConsoleExe`n- $godotGuiExe"
    exit 1
}

Write-Host "Using Godot executable: $godotExe"

Write-Host "Running content validation..."
& $godotExe --headless --path . --script res://tools/validate_content.gd
Write-Host "validate_content exit code: $LASTEXITCODE"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Content validation failed."
    exit $LASTEXITCODE
}

Write-Host "Running project validation..."
& $godotExe --headless --path . --script res://tools/validate_project.gd
Write-Host "validate_project exit code: $LASTEXITCODE"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Project validation failed."
    exit $LASTEXITCODE
}

Write-Host "All Godot validations passed."
exit 0
