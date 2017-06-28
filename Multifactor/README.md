# Dynamic Module Session Configuration
Standby for repetition of the description from the root of the repository.

This example is a largely unconfigured PSSession Configuration file aimed at demonstrating advanced logic opporuntities in the PSSC's startup script, such as multi-factor authentication with 3rd party platforms.

In this example, the username of the connecting user is used in a multi-factor authentication push request to the user's registered device.

If the authentication request is approved by the user, the PSSession is successfully created and can be used.

If the authentication requests is denied or times out, the startup script throws an unhandled error, causing the PSSession creation to fail.

# Full Documentation

## Elements of Dynamic Module

### multifactorstartupscript.ps1
This is the PowerShell script used as a startup script for multifactor authentication

I've done my best to document in the script what is going on

Important properties of this script are:

* You will pass the secret key of your Duo integration via a New-PSSessionOption application argument
* The user you create a PSSession with needs to be enrolled in Duo
* You must fill in the following values
    * Your Duo integration key - line 1
    * Your Duo API hostname - line 2


### PSSC
For simplicy's sake, I did not write a JEA config PSSC for this example. I wanted to demonstrate modifying existing PSSession configurations.  
Just know that you can use this script with any JEA config in the ScriptsToProcess option


## Installation

## Configurables 
For my example I have filled in the following values

* Integration key is DIHFIJXHBBH1VP2LBPN1
* API Hostname is api-2aa88467.duosecurity.com
* Secret key to use in application arguments is IrHE8xkW5dKAHz9IjZByi1gknhhTM3AswQX2z0T7

Note: This integration doesn't exist anymore so don't bother trying to use it :)

## Install
Assuming you have PSRemoting already enabled and want to modify the default PSSession configuration you simply run

    Get-PSSessionConfiguration -Name microsoft.powershell | Set-PSSessionConfiguration -StartupScript C:\PowerShellRemoting\multifactorstartupscript.ps1

Note:
* If you need help getting PSRemoting up and running, feel free to reach out to me on Twitter!
* If you don't want to modify the default config, you can use this script with any JEA config in the ScriptsToProcess option
## Usage
You can initiate a connection with the following commands

    $sessionOptions = New-PSSessionOption -ApplicationArguments @{"Key"="IrHE8xkW5dKAHz9IjZByi1gknhhTM3AswQX2z0T7"}
    New-PSSession -ComputerName 127.0.0.1 -SessionOption $sessionOptions

This one isn't quite as simple as the command for installation, so let me explain what this is actually doing.

-ComputerName is specifying the remote machine I want to connect to (in my case I connected to myself)  
-SessionOption passes advanced options to the remote machine, an exhausive list is available on [MSDN](https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/new-pssessionoption) but we're really only interested in ApplicationArguments for our example  
-ApplicationArguments let's you specify, via a hashtable, arbitrary values that will be passed to the remote endpoint, accessible in scripts under $PSSenderInfo.ApplicationArguments.<HashTableKey>  

If everything goes well, shortly after running New-PSSession you should get a push notification on your smartphone.

The screenshot below shows two attempts at connecting.  
In the first I denied the Duo push request on my phone, resulting in the "Access Denied" error being thrown and the PSSession failing to initialize.  
In the second attempt, I approved the Duo push request, resulting in the PSSession initializing sucessfully.

# Closing thoughts

