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
        Body = $body
        ContentType = 'application/x-www-form-urlencoded'
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
        }
        SkipCertificateCheck = $ignoreCertificateErrors
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
    }
    if ([bool]$Session.SkipCertificateCheck) {
        $request.SkipCertificateCheck = $true
    }

    Invoke-WithRetry -ScriptBlock {
        if ($null -eq $Body) {
            Invoke-RestMethod @request
        }
        else {
            Invoke-RestMethod @request -Body ($Body | ConvertTo-Json -Depth 20) -ContentType 'application/json'
        }
    }
}

function Get-VeeamCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Session,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $response = Invoke-VeeamApi -Session $Session -Path $Path
    foreach ($propertyName in @('data', 'items', 'results')) {
        if ($response.PSObject.Properties[$propertyName]) {
            return @($response.$propertyName)
        }
    }

    return @($response)
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Connect-VeeamApi, Invoke-VeeamApi, Get-VeeamCollection, Set-CollectorCertificatePolicy }
