Function Send-ActiveMQMessage {
    <#
    .SYNOPSIS
        Send a message to an ActiveMQ Broker queue
    .DESCRIPTION
        Send one or more messages to an ActiveMQ Broker's queue. You may specify either a string to be sent as a message or an object
        that will be serialized as XML and sent. The object must be serializable
    .PARAMETER Queue
        Name of the queue to send to
    .PARAMETER Message
        String or Object to send. If it's an object, it will be serialized to an XML string. Nested objects aren't supported. Convert those yourself and pass in as text string.
    .PARAMETER Session
        An existing Session Object
    .PARAMETER Uri
        The ActiveMQ Uri for the Message Broker. Refer to ActiveMQ documentation for full documentation on URIs supported
        Default: activemq:tcp://localhost:61616
    .PARAMETER User
        If not providing an existing session, the Username to authenticate with
        Example: 'admin'
    .PARAMETER Password
        If not providing an existing session, the Password to authenticate with
    .EXAMPLE
        Send-ActiveMQMessage -Queue My.Queue.Name -Message "Hello World" -Uri activemq:tcp://broker.example.com:61616 -User admin -Password admin
        Connect to broker.example.com and send message with "Hello World" in the body to queue My.Queue.Name.
    .EXAMPLE
        Send-ActiveMQMessage -Queue My.Queue.Name -InputObject $PSObj -Session $Session
        Serialize $PSObj and send to queue My.Queue.Name using an already-established session $Session. 
     
    .FUNCTIONALITY
        ActiveMQ
    .LINK
        http://activemq.apache.org/nms/nms-api.html
    .LINK
        http://activemq.apache.org/nms/activemq-uri-configuration.html
    #>


    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,Position=1)]
            [string]$Queue,  
        [Parameter(Position=2,Mandatory=$True,ValueFromPipeline=$True)]
            $Message,
        [Parameter(ParameterSetName='byUri')]
            [String]$Uri = 'activemq:tcp://localhost:61616',
        [Parameter(ParameterSetName='byUri',Mandatory=$true)]
            [String]$User,  
        [Parameter(ParameterSetName='byUri',Mandatory=$true)]
            [String]$Password,
        [Parameter(ParameterSetName='byUri')]
            [switch]$All,
        [Parameter(ParameterSetName='bySession')]
            [Apache.NMS.ISession]$Session        
    )

    Begin
    {
        # If we're establishing our own session, we *must* acknowledge the message immediately, because the connection will be gone
        # as soon as we exit
        [Apache.NMS.AcknowledgementMode]$AcknowledgementMode = [Apache.NMS.AcknowledgementMode]::AutoAcknowledge
 
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

        if (!$Session)
        {
            Try
            {
                $uriobj = [System.Uri]$Uri
                $factory =  New-Object Apache.NMS.NMSConnectionFactory($uriobj)
                $connection = $factory.CreateConnection($User, $Password)
                $connection.Start()
                $Session = $connection.CreateSession($AcknowledgementMode)
            }
            Catch
            {
                if ($connection)
                {
                    $connection.Close()
                }
                Throw $_
            }
        }

        $Target = [Apache.NMS.Util.SessionUtil]::GetDestination($Session, "queue://$Queue")
        $Producer = $Session.CreateProducer($Target)
    }

    Process
    {
        Try
        {
            if ($Message -is [String])
            {
                $AQMessage = $Session.CreateTextMessage($Message)
            }
            else
            {
                $AQMessage = [Apache.NMS.MessageProducerExtensions]::CreateXmlMessage($Producer,$Message)
            }
            $Producer.Send($AQMessage)
        }
        Catch
        {
            Throw $_
        }
    }

    End
    {
        if ($connection)
        {
            $connection.Close()
        }
    }
}
