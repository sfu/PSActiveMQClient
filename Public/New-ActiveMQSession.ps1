Function New-ActiveMQSession {
    <#
    .SYNOPSIS
        Establish a Connection and Session with a remote ActiveMQ Message Broker
    .DESCRIPTION
        This utility function does the basic work to establish an ActiveMQ Session with a Message Broker. An NMS Session object is returned. Note that it's not necessary to use this function - simply importing the ActiveMQClient module into your session will import the NMS library, making all NMS methods available. It is highly recommended that you familiarize yourself with the NMS methods available on the Session object returned
    .PARAMETER Uri
        The ActiveMQ Uri for the Message Broker. Refer to ActiveMQ documentation for full documentation on URIs supported
        Default: activemq:tcp://localhost:61616
    .PARAMETER User
        Username to authenticate with
        Example: 'admin'
    .PARAMETER Password
        Password to authenticate with
    .EXAMPLE
        $Session = New-ActiveMQSession -Uri activemq:tcp://broker.example.com:61616 -User admin -Password admin
        Connect to broker.example.com and return an NMS ISession object. Then:

        # Create a Target object for the desired queue
        $Target = [Apache.NMS.Util.SessionUtil]::GetDestination($session, "queue://$queueName")
        # Create a consumer with the target
        $Consumer =  $Session.CreateConsumer($Target)
        # Wait for message (will block and wait forever)
        $Message = $Consumer.Receive() 
    .FUNCTIONALITY
        ActiveMQ
    .LINK
        http://activemq.apache.org/nms/nms-api.html
    .LINK
        http://activemq.apache.org/nms/activemq-uri-configuration.html
    #>


    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)][string]$Uri = 'activemq:tcp://localhost:61616',
        [parameter(Mandatory=$false)][string]$User,  
        [parameter(Mandatory=$false)][String]$Password
    )

 
    # This should have been handled by the module load code, but just in case..

    Try
    {
        Add-Type -Path $PSScriptRoot\..\lib\apache.NMS.dll
    }
    Catch
    {
        # Probably just already loaded
    }

    Write-Debug ( "Running $($MyInvocation.MyCommand).`n" +
                    "PSBoundParameters:$( $PSBoundParameters | Format-List | Out-String)")

    Try
    {
        $uriobj = [System.Uri]$Uri
        $factory =  New-Object Apache.NMS.NMSConnectionFactory($uriobj)
        $connection = $factory.CreateConnection($User, $Password)
        $connection.Start()
        $session = $connection.CreateSession()
    }
    Catch
    {
        Throw $_
    }

    $session
}
