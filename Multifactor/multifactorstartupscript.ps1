$ikey = "XXXXXXXXXXXXXXXXXXXX" #Your Duo app integration key from your admin console
$apihost = "api-XXXXXXXX.duosecurity.com" #Your Duo api host from your admin console

function Get-HMACSHA1([string]$req, [string]$skey){
	$hmacsha = New-Object System.Security.Cryptography.HMACSHA1
	[byte[]]$publicKeyBytes = [System.Text.Encoding]::ASCII.GetBytes($req)
	[byte[]]$privateKeyBytes = [System.Text.Encoding]::ASCII.GetBytes($skey)
	$hmacsha.Key = $privateKeyBytes
	[byte[]]$hash = $hmacsha.ComputeHash($publicKeyBytes)
	$return = [System.BitConverter]::ToString($hash).Replace("-","").ToLower()
	return $return
}

function ConvertTo-Base64([string] $toEncode){
	[byte[]]$toEncodeAsBytes = [System.Text.ASCIIEncoding]::ASCII.GetBytes($toEncode)
	[string]$returnValue = [System.Convert]::ToBase64String($toEncodeAsBytes)
	return $returnValue
}

#For lack of a better explanation, a bunch of requirements for Duo's SHA1HMAC implementation
#Read all about it here: https://duo.com/docs/authapi
$date = get-date -date (get-date).ToUniversalTime() -format r 
$reqtype = "POST"
$reqpath = "/auth/v2/auth"
#$env:USERNAME is the username of the remote user creating the connection in New-PSSession either implicitly defined or explicitly using -Credential
#It should go without saying, but this username needs to be a valid user in your Duo organization for this script to work
$postParams = @{device="auto";factor="auto";username="$env:USERNAME";"pushinfo"="session%3DPSRemote Session on $env:COMPUTERNAME"} 
#Alphabetical order, encode those spaces
$postParams.Keys | Sort-Object | ForEach-Object {
	$val = $val + ($_ + "=" + $postParams.Item($_)).replace(" ","%20") + "&" 
}
$val = $val.Substring(0,$val.Length-1) #Chop off the trailing &
$req = "$date`n$reqtype`n$apihost`n$reqpath`n$val" #Put it all together, with newlines
$hash = Get-HMACSHA1 $req $PSSenderInfo.ApplicationArguments.Key #We're getting the key from the remote endpoint, because security
$signature = ConvertTo-Base64($ikey + ":" + $hash)
$auth = "Basic $signature"
$url = "https://$apihost$reqpath"
#Have to overwrite the Date header with the $date used above in the signature
$data = Invoke-WebRequest -Uri $url -Headers @{"Date" = $date; "Authorization" = $auth} -Body $val -Method Post
$resp = $data.Content | ConvertFrom-Json -ErrorAction SilentlyContinue #If things go well, this shouldn't throw an error anyways. If they don't we'll know soon enough
if($resp.response.result -ne "allow") {
	throw "Access Denied" #You didn't say the magic word
}