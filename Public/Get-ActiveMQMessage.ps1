Function Get-ActiveMQMessage {
    <#
    .SYNOPSIS
        Return the first or all messages from an ActiveMQ broker queue
    .DESCRIPTION
        Retrieve either the first message in the queue or all messages in the queue of an ActiveMQ Message Broker.
    .PARAMETER Queue
        Name of the queue to check
    .PARAMETER Session
        An existing Session Object
    .PARAMETER Uri
        The ActiveMQ Uri for the Message Broker. Refer to ActiveMQ documentation for full documentation on URIs supported
        Default: activemq:tcp://localhost:61616

        Passing a URI will force messages to be auto-acknowledged, as the connection will close as soon as this cmdlet completes.  
        Auto-acknowledged messages can only be retrieved once. If an error occurs further down the pipeline and the message hasn't been saved, 
        the message will be lost. To acknowledge messages individually upon successfully processing them, pass in a Session and call 
        the .Acknowledge() method on the $Message object that this cmdlet returns.
        Refer to the Apache NMS API documentation for further info on the different Acknowledge modes

        It is recommended you establish a session separately if message loss can not be tolerated. 
    .PARAMETER User
        If not providing an existing session, the Username to authenticate with
        Example: 'admin'
    .PARAMETER Password
        If not providing an existing session, the Password to authenticate with
    .PARAMETER All
        Return all messages intsead of just the first one in the queue
    .PARAMETER Wait
        Number of seconds to wait if no message is available. Specify 0 to wait forever. The default, if not specified, is to return immediately if no message is available
    .EXAMPLE
        $Message = Get-ActiveMQMessage -Queue My.Queue.Name -Uri activemq:tcp://broker.example.com:61616 -User admin -Password admin -Acknowledge AutoAcknowledge
        Connect to broker.example.com and return and return the first message in queue My.Queue.Name. Acknowledge the message immediately, removing it from the queue.
    .EXAMPLE
        Get-ActiveMQMessage -Queue My.Queue.Name -Session $Session -Wait 60
        Retrieve the first message from queue My.Queue.Name from an already-established session $Session. Wait up to 60 seconds for a new message if the queue is empty
     
    .FUNCTIONALITY
        ActiveMQ
    .LINK
        http://activemq.apache.org/nms/nms-api.html
    .LINK
        http://activemq.apache.org/nms/msdoc/1.6.0/vs2005/Output/html/T_Apache_NMS_AcknowledgementMode.htm
    .LINK
        http://activemq.apache.org/nms/activemq-uri-configuration.html
    #>


    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,Position=1)]
            [string]$Queue,  
        [Parameter(ParameterSetName='byUri')]
            [String]$Uri = 'activemq:tcp://localhost:61616',
        [Parameter(ParameterSetName='byUri',Mandatory=$true)]
            [String]$User,  
        [Parameter(ParameterSetName='byUri',Mandatory=$true)]
            [String]$Password,
        [Parameter(ParameterSetName='byUri')]
            [switch]$All,
        [Parameter(ParameterSetName='bySession')]
            [Apache.NMS.ISession]$Session,
        [parameter(Mandatory=$false)][int]$WaitTime
    )

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
    $Consumer = $Session.CreateConsumer($Target)

    $loopCount = 0
    do
    {
        if ($WaitTime -and $loopCount -eq 0)
        {
            if ($WaitTime -eq 0)
            {
                $Message = $Consumer.Receive()
            }
            else
            {
                $Message = $Consumer.Receive([System.TimeSpan]::FromSeconds($WaitTime))
            }
        }
        else
        {
            $Message = $Consumer.ReceiveNoWait()
        }
        if ($Message -ne $null)
        {
            $Message
        }
        $loopCount++

    } until ($Message -eq $null -or !$All)

    if ($connection)
    {
        $connection.Close()
    }
}
