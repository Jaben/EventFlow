$ErrorActionPreference = "Stop"

function Invoke-Call {
    param (
        [scriptblock]$ScriptBlock,
        [string]$ErrorAction = $ErrorActionPreference
    )
    & @ScriptBlock
    if (($lastexitcode -ne 0) -and $ErrorAction -eq "Stop") {
        exit $lastexitcode
    }
}

function Invoke-WebRequestWithRetry {
    param (
        [string]$Uri,
        [int]$TimeoutSec = 60,
        [int]$RetryIntervalSec = 5,
        [int]$MaxRetries = 12
    )

    $retries = 0
    while ($retries -lt $MaxRetries) {
        try {
            Invoke-WebRequest -Uri $Uri -TimeoutSec $TimeoutSec -UseBasicParsing
            return
        } catch {
            Write-Host "Request to $Uri failed. Retrying in $RetryIntervalSec seconds..."
            Start-Sleep -Seconds $RetryIntervalSec
            $retries++
        }
    }
    throw "Failed to connect to $Uri after $MaxRetries retries."
}

# Up containers
Invoke-Call -ScriptBlock { docker compose --compatibility -f docker-compose.ci.yml pull } -ErrorAction Stop
Invoke-Call -ScriptBlock { docker compose --compatibility -f docker-compose.ci.yml up -d } -ErrorAction Stop

# Set connection url to environment variable
# RabbitMQ
$env:RABBITMQ_URL = "amqp://guest:guest@localhost:5672"
# Elasticsearch
$env:ELASTICSEARCH_URL = "http://localhost:9200"
# Event Store
$env:EVENTSTORE_URL = "tcp://admin:changeit@localhost:1113"

# Health checks
# EventStore
Invoke-WebRequestWithRetry -Uri "http://localhost:2113"

# Elasticsearch
Invoke-WebRequestWithRetry -Uri "http://localhost:9200"

# RabbitMQ
Invoke-WebRequestWithRetry -Uri "http://localhost:15672"
