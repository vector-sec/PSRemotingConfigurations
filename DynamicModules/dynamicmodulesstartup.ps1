if ($PSSenderInfo.ApplicationArguments.PSMName) {

    #Effectively https://<YOUR TRUSTED HOST>/<PS Module Name Passed At Runtime>.psm1
    $url = "https://<YOUR TRUSTED HOST>/$($PSSenderInfo.ApplicationArguments.PSMName).psm1"

    #BEGIN Comment/Uncomment for certificate pinning
    $cnName = $url.Split("/")[2] #Assuming that the common name of the web server certificate belongs to the domain you specified in $url
    $cnName = "CN=$cnName" #I had to do some interesting nonsense to get the Common Name to match reliably, this may not be needed for your certificate
    $chainSubject = "<SUBJECT HERE>" #Subject of your intermediary or root CA, in my situation this was CN=Name 
    $chainKey = "<PUBLIC KEY HERE>" #Highly recommend that you pin to the intermediary or root CA rather than the certificate of your webserver
    $request = [System.Net.HttpWebRequest]::Create($url)
    try {
        #Make the request but ignore (dispose it) the response, since we only care about the service point
        $request.GetResponse().Dispose()
    }
    catch {
        #do nothing with exceptions, we're only after the public key
    }
    $chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
    $chain.Build($request.ServicePoint.Certificate)
    #Walk the certificate chain until you find the level with the a subject matching $chainSubject
    $chaincert = $chain.ChainElements | Where-Object {$_.Certificate.Subject -eq $chainSubject}
    $key = $chaincert.Certificate.GetPublicKeyString()
    #If public keys mismatch, or if the common name of the web server certificate does not match $cnName, then throw an error causing the session creation to fail
    if (($key -ne $chainKey) -or (($request.ServicePoint.Certificate.GetName().Split(",") | Where-Object {$_ -match "CN=.*"}).trim() -ne $cnName)) {
        throw "HTTPS connection to module server not trusted."
    }
    #END Comment/Uncomment for certificate pinning


    try {
        #Download the module as a string
        $webclient = new-object System.Net.WebClient
        $scriptContent = $webclient.DownloadString($url)
    }
    catch [System.Net.WebException] {
        #404s, 403s, etc will land you here
        write-host $_.Exception.Message
        write-host $_.Exception.ItemName
        throw "Invalid module name"
    }

    #Import the downloaded module
    #See https://twitter.com/vector_sec/status/838761720088788992
    Import-Module (New-Module -Name $PSSenderInfo.ApplicationArguments.PSMName -ScriptBlock ([scriptblock]::Create($scriptContent)))

    #Enumerate functions of the module and set their visibility to public, exposing them to the runspace of the PSSession
    Get-Command -Module $PSSenderInfo.ApplicationArguments.PSMName | ForEach-Object {$_.Visibility = 'Public'}
}