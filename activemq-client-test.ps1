#
# A powershell script to read from any ActiveMq provider
# 

Add-Type -Path $PSScriptRoot\lib\apache.NMS.dll

$global:queueName = "ICAT.test.log"
$global:timer = New-Object System.Timers.Timer(5000)
$global:runCount = 0
$global:msmqHost = "activemq:tcp://localhost:61616"
$global:daysOld = 0
$global:connected = $false



$action = {
    Write-Host "Timer elapsed at : $((Get-Date).ToString())" 
    Write-Host "Stopping timer execution...."
    $timer.Stop();
    connect($msmqHost)
} 

function global:decryptCredentials($keyPass)
{    
}

function global:logToFile([String] $content)
{   
    [System.IO.File]::AppendText("", $content)
}

function global:connect($url)
{
    write-host "Start connecting to activeMq at : $((Get-Date).ToString())" 
    $uri = [System.Uri]$url
    write-host $uri
    $factory =  New-Object Apache.NMS.NMSConnectionFactory($uri)

    $connection = $factory.CreateConnection("username", "password")
    Write-Host $connection
    
    $session = $connection.CreateSession()
    $target = [Apache.NMS.Util.SessionUtil]::GetDestination($session, "queue://$queueName")
    Write-Host "created session  $target  . $target.IsQueue " 

    # creating message queue consumer. 
    # using the Listener - event listener might not be suitable 
    # as we only logs expired messages in the queue. 

    $consumer =  $session.CreateConsumer($target)
    $targetQueue = $session.GetQueue($queueName)
    $queueBrowser = $session.CreateBrowser($targetQueue)
    $messages = $queueBrowser.GetEnumerator()
    
     Write-Host "------------Connection starts------------"

     $connection.Start()

     Write-Host $connection

     try {
        while(1) {
            Write-Host "Waiting for messages.."
            $msg = $consumer.Receive([System.TimeSpan]::FromSeconds(60))
            if (!$msg)
            {
                Write-Host "No msg after 1 minute. Repeating"
                continue
            }
    
          
            Write-Host "Reading message:"
            Write-Host $msg.Text
            if ($msg.Text -Match "^quit")
            {
                break
            }
        }
     }
     catch
     {
        Write-Error $_
     }   

     Write-Host "Closing connection"
     $connection.Close()
     # restartTimer
}

function global:restartTimer()
{
    Write-Host "Restarting timer."
    $timer.Start();
}

function main()
{   
    setupTimer 
}

function setupTimer()
{
    Write-Host "register timer event"
    Register-ObjectEvent $timer -EventName Elapsed -Action $action
    Write-Host "starting timer"
    $timer.Start()    
}

function global:getLocalDateTime($time)
{
    $timeStr = $time.toString()
    $unixTime = $timeStr.subString(0, $timeStr.Length - 3)
    $epoch = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    return $epoch.AddSeconds($unixTime).ToLocalTime()
}

# main code block

global:connect($msmqHost)
