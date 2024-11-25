#!/bin/bash

echo "Analysis of controller workload:"
echo "--------------------------------"

# Count pipeline runs per controller
echo "Pipeline runs per controller:"
jq -r 'to_entries | .[] | "\(.key): \(.value | length) pipeline runs"' output.json

echo -e "\nTask runs per controller:"
# Count task runs per controller (flatten arrays and count unique entries)
jq -r 'to_entries | .[] | "\(.key): \(.value | values | flatten | length) task runs"' output.json
