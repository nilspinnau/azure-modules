
{
  "DiagnosticMonitorConfiguration": {
    "overallQuotaInMB": 5096,
    "DiagnosticInfrastructureLogs": {
      "scheduledTransferLogLevelFilter": "Error"
    },
    "PerformanceCounters": {
      "scheduledTransferPeriod": "PT1M",
      "sinks": "AzureMonitorSink",
      "PerformanceCounterConfiguration": [
        {
          "counterSpecifier": "\\Processor(_Total)\\% Processor Time",
          "sampleRate": "PT1M",
          "unit": "percent"
        },
        {
          "counterSpecifier": "\\Processor Information(_Total)\\% Processor Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\Processor Information(_Total)\\% Privileged Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\Processor Information(_Total)\\% User Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\Processor Information(_Total)\\Processor Frequency",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\System\\Processes",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\Process(_Total)\\Thread Count",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\Process(_Total)\\Handle Count",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\System\\System Up Time",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\System\\Context Switches/sec",
          "sampleRate": "PT60S",
          "unit": "CountPerSecond"
        },
        {
          "counterSpecifier": "\\System\\Processor Queue Length",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\Memory\\% Committed Bytes In Use",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\Memory\\Available Bytes",
          "sampleRate": "PT60S",
          "unit": "Bytes"
        },
        {
          "counterSpecifier": "\\Memory\\Committed Bytes",
          "sampleRate": "PT60S",
          "unit": "Bytes"
        },
        {
          "counterSpecifier": "\\Memory\\Cache Bytes",
          "sampleRate": "PT60S",
          "unit": "Bytes"
        },
        {
          "counterSpecifier": "\\Memory\\Pool Paged Bytes",
          "sampleRate": "PT60S",
          "unit": "Bytes"
        },
        {
          "counterSpecifier": "\\Memory\\Pool Nonpaged Bytes",
          "sampleRate": "PT60S",
          "unit": "Bytes"
        },
        {
          "counterSpecifier": "\\Memory\\Pages/sec",
          "sampleRate": "PT60S",
          "unit": "CountPerSecond"
        },
        {
          "counterSpecifier": "\\Memory\\Page Faults/sec",
          "sampleRate": "PT60S",
          "unit": "CountPerSecond"
        },
        {
          "counterSpecifier": "\\Process(_Total)\\Working Set",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\Process(_Total)\\Working Set - Private",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Read Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Write Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\% Idle Time",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Bytes/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Transfers/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Reads/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Writes/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\% Free Space",
          "sampleRate": "PT60S",
          "unit": "Percent"
        },
        {
          "counterSpecifier": "\\LogicalDisk(_Total)\\Free Megabytes",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Bytes Total/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Bytes Sent/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Bytes Received/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Packets/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Packets Sent/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Packets Received/sec",
          "sampleRate": "PT60S",
          "unit": "BytesPerSecond"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Packets Outbound Errors",
          "sampleRate": "PT60S",
          "unit": "Count"
        },
        {
          "counterSpecifier": "\\Network Interface(*)\\Packets Received Errors",
          "sampleRate": "PT60S",
          "unit": "Count"
        }
      ]
    },
    "Directories": {
      "scheduledTransferPeriod": "PT5M",
      "IISLogs": {
        "containerName": "iislogs"
      },
      "FailedRequestLogs": {
        "containerName": "iisfailed"
      },
      "DataSources": []
    },
    "EtwProviders": {
      "sinks": "",
      "EtwEventSourceProviderConfiguration": [],
      "EtwManifestProviderConfiguration": []
    },
    "WindowsEventLog": {
      "scheduledTransferPeriod": "PT5M",
      "xPathQueries": [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "System!*[System[(Level=1 or Level=2)]]"
      ],
      "DataSource": [
        {
          "name": "System!*[System[Provider[@Name='Microsoft Antimalware']]]"
        },
        {
          "name": "System!*[System[Provider[@Name='NTFS'] and (EventID=55)]]"
        },
        {
          "name": "System!*[System[Provider[@Name='disk'] and (EventID=7 or EventID=52 or EventID=55)]]"
        }
      ]
    },
    "Logs": {
      "scheduledTransferPeriod": "PT1M",
      "scheduledTransferLogLevelFilter": "Verbose",
      "sinks": "ApplicationInsights.AppLogs"
    },
    "CrashDumps": {
      "directoryQuotaPercentage": 30,
      "dumpType": "Mini",
      "containerName": "wad-crashdumps",
      "CrashDumpConfiguration": []
    }
  },
  "SinksConfig": {
    "Sink": [
      {
        "name": "AzureMonitorSink",
        "AzureMonitor": {
          "ResourceId": "${workspace_resource_id}"
        }
      }
    ]
  }
}
