# PSRemoting Modules

This project is largely just a brain dump of ideas that I had for making interesting use of PowerShell Remoting and PSSession Configurations.

You can read a brief summary of each configuration below, or head straight into the code of the repository to get more information.

[Feedback is always welcome!](https://twitter.com/vector_sec)

## Dynamic Module Session Configuration

This example combines an extremely locked down PSSession Configuration file with a very flexible startup script which allows the dynamic loading of desired PowerShell modules into the PSSession at run-time.

While it can be quite dangerous to allow this startup script to load arbitrary PowerShell modules from the network, some precautions can be made (and are implemented) in the startup script to largely eliminate the issue of trusting the source of the PowerShell module.

This configuration is perfect for allowing multiple use-cases for PSRemoting without having to manage numerous JEA configs. You have the zero access config + whichever module you need at runtime.

## Multifactor Session Configuration (Duo)

This example is a largely unconfigured PSSession Configuration file aimed at demonstrating advanced logic opporuntities in the PSSC's startup script, such as multi-factor authentication with 3rd party platforms.

In this example, the username of the connecting user is used in a multi-factor authentication push request to the user's registered device.

If the authentication request is approved by the user, the PSSession is successfully created and can be used.

If the authentication requests is denied or times out, the startup script throws an unhandled error, causing the PSSession creation to fail.


## Multifactor Session Configuration (Okta)
I'll make this if enough people express interest in it :)

## Thanks
Thanks to @mattifestation for all-around wizardry with PowerShell/JEA and for helping to review some of my work.  
Thanks to @nocow4bob for reviewing the content of this release before it was published.
