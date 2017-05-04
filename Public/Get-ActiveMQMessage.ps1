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
    .PARAMETER User
        If not providing an existing session, the Username to authenticate with
        Example: 'admin'
    .PARAMETER Password
        If not providing an existing session, the Password to authenticate with
    .PARAMETER AcknowledgementMode
        If not providing an existing session, how to acknowledge messages (the default is not to). One of [AutoAcknowledge,DupsOkAcknowledge,ClientAcknowledge,Transactional, or IndividualAcknowledge].
        Auto-acknowledged messages can only be retrieved once. If an error occurs further down the pipeline and the message hasn't been saved, 
        the message will be lost. To acknowledge a messsage, call the .Acknowledge() method on the $Message object that this cmdlet returns.
        Refer to the Apache NMS API documentation for further info on the different Acknowledge modes
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
            [Apache.NMS.AcknowledgementMode]$AcknowledgementMode = [Apache.NMS.AcknowledgementMode]::IndividualAcknowledge,
        [Parameter(ParameterSetName='bySession')]
            [Apache.NMS.ISession]$Session,
        [parameter(Mandatory=$false)][int]$WaitTime,
        [switch]$All
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

    if (!$Session)
    {
        Try
        {
            $uriobj = [System.Uri]$Uri
            $factory =  New-Object Apache.NMS.NMSConnectionFactory($uriobj)
            $connection = $factory.CreateConnection($User, $Password)
            $connection.Start()
            $Session = $connection.CreateSession($AutoAcknowledge)
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



  


    
}
