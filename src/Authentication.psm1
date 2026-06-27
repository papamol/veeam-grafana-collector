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
        TimeoutSec = 120
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
        TimeoutSec = 120
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

        [int]$Limit = 100
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $offset = 0

    do {
        $separator = if ($Path.Contains('?')) { '&' } else { '?' }
        $pagedPath = '{0}{1}limit={2}&offset={3}' -f $Path, $separator, $Limit, $offset
        $response = Invoke-VeeamApi -Session $Session -Path $pagedPath
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

        foreach ($item in $items) {
            $results.Add($item)
        }

        $offset += $items.Count
    } while ($items.Count -eq $Limit)

    return $results.ToArray()
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Connect-VeeamApi, Invoke-VeeamApi, Get-VeeamCollection, Set-CollectorCertificatePolicy }
