$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer mPXKrT8RgK7bQgQg4xDvjJLcNrVdOE0M"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
foreach ($network in $response) {
    if ($network.config.name -eq 'steve') {
        $network.config.id
    }
}

