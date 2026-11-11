param([string]$FfmpegDir = $env:HALFSIZE_FFMPEG_DIR)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  $flutter = Get-Command flutter -ErrorAction SilentlyContinue
  if (-not $flutter) { $flutter = "T:\Android\flutter\bin\flutter.bat" }
  & $flutter build windows --release
  $release = Join-Path $root 'build\windows\x64\runner\Release'
  if (-not (Test-Path $release)) { throw "Release output missing: $release" }

  if ($FfmpegDir) {
    $bin = Join-Path $release 'bin'
    New-Item -ItemType Directory -Force -Path $bin | Out-Null
    Copy-Item (Join-Path $FfmpegDir 'ffmpeg.exe') $bin -Force
    Copy-Item (Join-Path $FfmpegDir 'ffprobe.exe') $bin -Force
    Get-ChildItem $FfmpegDir -Filter '*.dll' | Copy-Item -Destination $bin -Force
    $license = Join-Path (Split-Path -Parent $FfmpegDir) 'LICENSE.txt'
    if (Test-Path $license) { Copy-Item $license $bin -Force }
  }

  $version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)').Matches[0].Groups[1].Value
  $dist = Join-Path $root 'dist'
  New-Item -ItemType Directory -Force -Path $dist | Out-Null

  $zip = Join-Path $dist "halfsizeX-$version-windows-x64-portable.zip"
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Compress-Archive -Path (Join-Path $release '*') -DestinationPath $zip
  Write-Output $zip

  $wix = Get-Command wix.exe -ErrorAction SilentlyContinue
  if (-not $wix) {
    Write-Warning 'WiX not found; skipped MSI. Install with: dotnet tool install --global wix'
    return
  }

  $work = Join-Path $root 'build\windows\installer'
  New-Item -ItemType Directory -Force -Path $work | Out-Null
  $wxs = Join-Path $work 'halfsizeX.wxs'
  $msi = Join-Path $dist "halfsizeX-$version-windows-x64.msi"
  if (Test-Path $msi) { Remove-Item $msi -Force }

  $dirs = @{}
  $dirs[''] = 'INSTALLFOLDER'
  $i = 0
  Get-ChildItem $release -Recurse -Directory |
    ForEach-Object { $_.FullName.Substring($release.Length + 1).Replace('\', '/') } |
    Sort-Object { ($_ -split '/').Count }, { $_ } |
    ForEach-Object {
      $i++
      $dirs[$_] = "D$i"
    }

  $fileComponents = New-Object System.Collections.Generic.List[string]
  $fi = 0
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
  [void]$sb.AppendLine('<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">')
  [void]$sb.AppendLine('  <Package Name="halfsizeX" Manufacturer="halfsizeX" Version="$(var.Version)"')
  [void]$sb.AppendLine('           UpgradeCode="{8D1E4B2C-3F5A-4B6E-9C7D-2A1F0E3B5C4D}"')
  [void]$sb.AppendLine('           Scope="perUser" Language="1033" Compressed="yes">')
  [void]$sb.AppendLine('    <MajorUpgrade DowngradeErrorMessage="A newer halfsizeX is already installed." />')
  [void]$sb.AppendLine('    <MediaTemplate EmbedCab="yes" />')
  [void]$sb.AppendLine('    <StandardDirectory Id="LocalAppDataFolder">')
  [void]$sb.AppendLine('      <Directory Id="ProgramsFolder" Name="Programs">')
  [void]$sb.AppendLine('        <Directory Id="INSTALLFOLDER" Name="halfsizeX" />')
  [void]$sb.AppendLine('      </Directory>')
  [void]$sb.AppendLine('    </StandardDirectory>')
  [void]$sb.AppendLine('    <StandardDirectory Id="ProgramMenuFolder">')
  [void]$sb.AppendLine('      <Directory Id="AppProgramMenuDir" Name="halfsizeX" />')
  [void]$sb.AppendLine('    </StandardDirectory>')
  [void]$sb.AppendLine('    <Feature Id="Main" Title="halfsizeX" Level="1">')
  [void]$sb.AppendLine('      <ComponentGroupRef Id="AppFiles" />')
  [void]$sb.AppendLine('      <ComponentRef Id="StartMenuShortcut" />')
  [void]$sb.AppendLine('    </Feature>')
  [void]$sb.AppendLine('  </Package>')

  function Write-Dir([string]$rel, [int]$depth) {
    $indent = '  ' * ($depth + 2)
    if ($rel -ne '') {
      $name = ($rel -split '/')[-1]
      [void]$sb.AppendLine("$indent<Directory Id=""$($dirs[$rel])"" Name=""$([System.Security.SecurityElement]::Escape($name))"">")
    }
    $parent = $rel
    $current = if ($rel -eq '') { $release } else { Join-Path $release ($rel.Replace('/', '\')) }
    $files = Get-ChildItem $current -File
    foreach ($f in $files) {
      $script:fi++
      $cid = "C$($script:fi)"
      $fid = "F$($script:fi)"
      $src = [System.Security.SecurityElement]::Escape($f.FullName)
      $indent = '  ' * ($depth + 2)
      [void]$sb.AppendLine("$indent<Component Id=""$cid"" Guid=""*"">")
      [void]$sb.AppendLine("$indent  <File Id=""$fid"" Source=""$src"" KeyPath=""yes"" />")
      [void]$sb.AppendLine("$indent</Component>")
      $fileComponents.Add($cid)
    }
    $children = Get-ChildItem $current -Directory | Sort-Object Name
    foreach ($child in $children) {
      $childRel = if ($parent -eq '') { $child.Name } else { "$parent/$($child.Name)" }
      Write-Dir $childRel ($depth + 1)
    }
    if ($rel -ne '') {
      [void]$sb.AppendLine("$indent</Directory>")
    }
  }

  [void]$sb.AppendLine('  <Fragment>')
  [void]$sb.AppendLine('    <DirectoryRef Id="INSTALLFOLDER">')
  Write-Dir '' 0
  [void]$sb.AppendLine('    </DirectoryRef>')
  [void]$sb.AppendLine('  </Fragment>')
  [void]$sb.AppendLine('  <Fragment>')
  [void]$sb.AppendLine('    <ComponentGroup Id="AppFiles">')
  foreach ($cid in $fileComponents) {
    [void]$sb.AppendLine("      <ComponentRef Id=""$cid"" />")
  }
  [void]$sb.AppendLine('    </ComponentGroup>')
  [void]$sb.AppendLine('  </Fragment>')
  [void]$sb.AppendLine('  <Fragment>')
  [void]$sb.AppendLine('    <DirectoryRef Id="AppProgramMenuDir">')
  [void]$sb.AppendLine('      <Component Id="StartMenuShortcut" Guid="*">')
  [void]$sb.AppendLine('        <Shortcut Id="AppShortcut" Name="halfsizeX" Description="Compress video to an exact size"')
  [void]$sb.AppendLine('                  Target="[INSTALLFOLDER]halfsizeX.exe" WorkingDirectory="INSTALLFOLDER">')
  [void]$sb.AppendLine('          <ShortcutProperty Key="System.AppUserModel.ID" Value="com.halfsizeX.video" />')
  [void]$sb.AppendLine('        </Shortcut>')
  [void]$sb.AppendLine('        <RemoveFolder Id="RemoveAppProgramMenuDir" On="uninstall" />')
  [void]$sb.AppendLine('        <RegistryValue Root="HKCU" Key="Software\halfsizeX" Name="installed" Type="integer" Value="1" KeyPath="yes" />')
  [void]$sb.AppendLine('      </Component>')
  [void]$sb.AppendLine('    </DirectoryRef>')
  [void]$sb.AppendLine('  </Fragment>')
  [void]$sb.AppendLine('</Wix>')
  Set-Content -LiteralPath $wxs -Value $sb.ToString() -Encoding UTF8

  & wix.exe build -arch x64 -d Version=$version -d SourceDir=$release -o $msi $wxs
  if ($LASTEXITCODE -ne 0) { throw "wix build failed with $LASTEXITCODE" }
  Write-Output $msi
} finally {
  Pop-Location
}
