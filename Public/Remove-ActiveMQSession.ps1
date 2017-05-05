Function Remove-ActiveMQSession {
    <#
    .SYNOPSIS
        Close a Connection and Session with a remote ActiveMQ Message Broker
    .DESCRIPTION
        Close a connection previously established with New-ActiveMQSession
    .PARAMETER Session
        Session object returned by New-ActiveMQSession
    .EXAMPLE
        Remove-ActiveMQSession $Session
        Close connection used for $Session
    .FUNCTIONALITY
        ActiveMQ
    .LINK
        http://activemq.apache.org/nms/nms-api.html
    .LINK
        http://activemq.apache.org/nms/activemq-uri-configuration.html
    #>


    [cmdletbinding()]
    param(
        [parameter(Mandatory=$True,Position=1)][Apache.NMS.ISession]$Session
    )
    $Connection = $Session.Connection
    $Session.Close()
    $Sessiom.Dispose()
    $Connection.Close()
    $Connection.Dispose()
}
