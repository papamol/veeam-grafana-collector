Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Set-CollectorCertificatePolicy {
    [CmdletBinding()]
    param(
        [bool]$IgnoreCertificateErrors
    )

    if ($IgnoreCertificateErrors) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    }
}

function Connect-VeeamApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )

    $ignoreCertificateErrors = [bool]$Config.Veeam.IgnoreCertificateErrors
    $apiVersion = if ($Config.Veeam.PSObject.Properties['ApiVersion'] -and -not [string]::IsNullOrWhiteSpace($Config.Veeam.ApiVersion)) {
        $Config.Veeam.ApiVersion
    }
    else {
        '1.3-rev1'
    }
    Set-CollectorCertificatePolicy -IgnoreCertificateErrors $ignoreCertificateErrors

    $body = @{
        grant_type = 'password'
        username = $Config.Veeam.Username
        password = $Config.Veeam.Password
    }

    $uri = '{0}/oauth2/token' -f $Config.Veeam.BaseUrl.TrimEnd('/')
    $request = @{
        Method = 'Post'
        Uri = $uri
        Headers = @{
            'x-api-version' = $apiVersion
        }
        Body = $body
        ContentType = 'application/x-www-form-urlencoded'
        TimeoutSec = 30
    }
    if ($ignoreCertificateErrors) {
        $request.SkipCertificateCheck = $true
    }

    $response = Invoke-WithRetry -ScriptBlock {
        Invoke-RestMethod @request
    }

    $token = Get-PropertyValue -InputObject $response -Names @('access_token', 'accessToken', 'token')
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw 'Veeam authentication response did not include an access token.'
    }

    return [pscustomobject]@{
        BaseUrl = $Config.Veeam.BaseUrl.TrimEnd('/')
        Headers = @{
            Authorization = "Bearer $token"
            Accept = 'application/json'
            'x-api-version' = $apiVersion
        }
        SkipCertificateCheck = $ignoreCertificateErrors
        TimeoutSec = 30
    }
}

function Invoke-VeeamApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Session,

        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('Get', 'Post')]
        [string]$Method = 'Get',

        [AllowNull()]
        [object]$Body = $null
    )

    $uri = if ($Path.StartsWith('http')) { $Path } else { '{0}/{1}' -f $Session.BaseUrl.TrimEnd('/'), $Path.TrimStart('/') }

    $request = @{
        Method = $Method
        Uri = $uri
        Headers = $Session.Headers
        TimeoutSec = $Session.TimeoutSec
    }
    if ([bool]$Session.SkipCertificateCheck) {
        $request.SkipCertificateCheck = $true
    }

    Invoke-WithRetry -ScriptBlock {
        try {
            if ($null -eq $Body) {
                Invoke-RestMethod @request
            }
            else {
                Invoke-RestMethod @request -Body ($Body | ConvertTo-Json -Depth 20) -ContentType 'application/json'
            }
        }
        catch {
            throw "Veeam API request failed for $uri. $($_.Exception.Message)"
        }
    }
}

function Get-VeeamCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Session,

        [Parameter(Mandatory)]
        [string]$Path,

        [int]$Limit = 1,

        [int]$MaxPages = 1
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $offset = 0
    $page = 0

    do {
        $page++
        if ($page -gt $MaxPages) {
            throw "Stopped paging $Path after $MaxPages pages to prevent an endless collection loop."
        }

        $separator = if ($Path.Contains('?')) { '&' } else { '?' }
        $pagedPath = '{0}{1}limit={2}&skip={3}' -f $Path, $separator, $Limit, $offset
        if (Get-Command -Name Write-CollectorLog -ErrorAction SilentlyContinue) {
            Write-CollectorLog -Message ("Requesting {0} page {1}" -f $pagedPath, $page)
        }
        try {
            $response = Invoke-VeeamApi -Session $Session -Path $pagedPath
        }
        catch {
            if ($results.Count -gt 0) {
                if (Get-Command -Name Write-CollectorLog -ErrorAction SilentlyContinue) {
                    Write-CollectorLog -Message ("Stopping paged collection for {0} after {1} item(s): {2}" -f $Path, $results.Count, $_.Exception.Message) -Level WARN
                }
                break
            }

            throw
        }
        $items = $null

        foreach ($propertyName in @('data', 'items', 'results')) {
            if ($response.PSObject.Properties[$propertyName]) {
                $items = @($response.$propertyName)
                break
            }
        }

        if ($null -eq $items) {
            $items = @($response)
        }

        $total = if ($response.PSObject.Properties['pagination'] -and $response.pagination.PSObject.Properties['total']) {
            [int]$response.pagination.total
        }
        else {
            $null
        }

        if (Get-Command -Name Write-CollectorLog -ErrorAction SilentlyContinue) {
            $totalText = if ($null -eq $total) { 'unknown' } else { [string]$total }
            Write-CollectorLog -Message ("Received {0} item(s) from {1}; total={2}" -f $items.Count, $pagedPath, $totalText)
        }

        foreach ($item in $items) {
            $results.Add($item)
        }

        $offset += $items.Count
    } while ($page -lt $MaxPages -and $items.Count -eq $Limit -and ($null -eq $total -or $offset -lt $total))

    if ($null -ne $total -and $results.Count -lt $total -and (Get-Command -Name Write-CollectorLog -ErrorAction SilentlyContinue)) {
        Write-CollectorLog -Message ("Collected {0} of {1} available item(s) from {2}; additional pages are disabled to avoid slow Veeam pagination." -f $results.Count, $total, $Path) -Level WARN
    }

    return $results.ToArray()
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Connect-VeeamApi, Invoke-VeeamApi, Get-VeeamCollection, Set-CollectorCertificatePolicy }
