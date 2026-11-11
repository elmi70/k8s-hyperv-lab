@{
    Severity     = @('Error', 'Warning')
    # These are interactive console scripts for a lab operator; colored Write-Host
    # progress output is intentional and is not captured by pipelines.
    ExcludeRules = @('PSAvoidUsingWriteHost')
}
