#!/bin/bash
curl -s -k -X POST 'https://<installer_ip>:443/api/v1/install/'  --header 'Content-Type: application/json' --data @./Rest_Config.json