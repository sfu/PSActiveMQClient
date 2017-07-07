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
    .PARAMETER ClientAcknowledge
        Set acknowledgement mode to ClientAcknowledge. Each message must be manually acknowledged once successfully processed.
        Acknowledging a message ack's all messages prior to it in the queue (this is not usually an issue as messages are received
        in a FIFO fashion)
        The default Acknowledgement Mode is AutoAcknowledge which automatically acknowledges every message as soon as it's received
    .PARAMETER DupsOkAcknowledge
        Set acknowledgement mode to DupsOkAcknowledge. The Acknowledgement mode switches are mutually exclusive
    .PARAMETER IndividualAcknowledge
        Set acknowledgement mode to IndividualAcknowledge. In this mode, each message is individually acknowledged and ack'ing one does
        NOT automatically ack earlier messages in the queue
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
    .LINK
        http://activemq.apache.org/nms/msdoc/1.6.0/vs2005/Output/html/T_Apache_NMS_AcknowledgementMode.htm
    #>


    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)][string]$Uri = 'activemq:tcp://localhost:61616',
        [parameter(Mandatory=$false)][string]$User,  
        [parameter(Mandatory=$false)][String]$Password,
        [parameter(ParameterSetName="ca")][Switch]$ClientAcknowledge,
        [parameter(ParameterSetName="da")][Switch]$DupsOkAcknowledge,
        [parameter(ParameterSetName="ia")][Switch]$IndividualAcknowledge
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

    [Apache.NMS.AcknowledgementMode]$AcknowledgementMode = [Apache.NMS.AcknowledgementMode]::AutoAcknowledge

    if ($ClientAcknowledge)
    {
        [Apache.NMS.AcknowledgementMode]$AcknowledgementMode = [Apache.NMS.AcknowledgementMode]::ClientAcknowledge
    }
    elseif ($DupsOkAcknowledge)
    {
        [Apache.NMS.AcknowledgementMode]$AcknowledgementMode = [Apache.NMS.AcknowledgementMode]::DupsOkAcknowledge
    }
    elseif ($IndividualAcknowledge)
    {
        [Apache.NMS.AcknowledgementMode]$AcknowledgementMode = [Apache.NMS.AcknowledgementMode]::IndividualAcknowledge
    }

    Try
    {
        $uriobj = [System.Uri]$Uri
        $factory =  New-Object Apache.NMS.NMSConnectionFactory($uriobj)
        $connection = $factory.CreateConnection($User, $Password)
        $connection.Start()
        $session = $connection.CreateSession($AcknowledgementMode)
    }
    Catch
    {
        Throw $_
    }

    $session
}
