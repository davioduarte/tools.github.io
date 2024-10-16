# Check massgrave.dev for more details

$ErrorActionPreference = "Stop"

write-host
Write-Host "Use o comando (irm https://davioduarte.github.io/tools.github.io/script.ps1 | iex) "
Write-Host -ForegroundColor Green "Use the new command (irm https://davioduarte.github.io/tools.github.io/script.ps1 | iex) moving forward."
write-host

# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$DownloadURL1 = 'https://davioduarte.github.io/tools.github.io/data/tools.bat'
$DownloadURL2 = 'https://davioduarte.github.io/tools.github.io/data/tools.bat'

$URLs = @($DownloadURL1, $DownloadURL2)
$RandomURL1 = Get-Random -InputObject $URLs
$RandomURL2 = ($URLs -ne $RandomURL1)[0]

try {
    $response = Invoke-WebRequest -Uri $RandomURL1 -UseBasicParsing
}
catch {
    $response = Invoke-WebRequest -Uri $RandomURL2 -UseBasicParsing
}

# # Verify script integrity
# $releaseHash = 'D666A4C7810B9D3FE9749F2D4E15C5A65D4AC0D7F0B14A144D6631CE61CC5DF3'
# $stream = New-Object IO.MemoryStream
# $writer = New-Object IO.StreamWriter $stream
# $writer.Write($response)
# $writer.Flush()
# $stream.Position = 0
# $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($stream)) -replace '-'
# if ($hash -ne $releaseHash) {
#     Write-Warning "Hash ($hash) mismatch, aborting!`nReport this issue at http://172.20.100.240/dpsp/tools"
#     $response = $null
#     return
# }

# Check for AutoRun registry which may create issues with CMD
$paths = "HKCU:\SOFTWARE\Microsoft\Command Processor", "HKLM:\SOFTWARE\Microsoft\Command Processor"
foreach ($path in $paths) { 
    if (Get-ItemProperty -Path $path -Name "Autorun" -ErrorAction SilentlyContinue) { 
        Write-Warning "Autorun registry found, CMD may crash! `nManually copy-paste the below command to fix...`nRemove-ItemProperty -Path '$path' -Name 'Autorun'"
    } 
}

$rand = [Guid]::NewGuid().Guid
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
$FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\MAS_$rand.cmd" } else { "$env:TEMP\MAS_$rand.cmd" }

$ScriptArgs = "$args "
$prefix = "@::: $rand `r`n"
$content = $prefix + $response
Set-Content -Path $FilePath -Value $content

# Set ComSpec variable for current session in case its corrupt in the system
$env:ComSpec = "$env:SystemRoot\system32\cmd.exe"
Start-Process cmd.exe "/c """"$FilePath"" $ScriptArgs""" -Wait

$FilePaths = @("$env:TEMP\MAS*.cmd", "$env:SystemRoot\Temp\MAS*.cmd")
foreach ($FilePath in $FilePaths) { Get-Item $FilePath | Remove-Item }
