#!/bin/bash

# Use temporary files instead of associative arrays for better compatibility
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Initialize an empty JSON structure
json_database="{}"

# First pass: collect all pipeline runs and their task runs, mapping them to controllers
for log_file in logs/controller-*.json; do
    controller_name=$(basename "$log_file" | cut -d'-' -f2 | cut -d'.' -f1)
    controller_key="controller-$controller_name"
    
    # Extract task runs and their controller assignments
    while IFS= read -r line; do
        if [[ $line =~ \"knative.dev/kind\":\"tekton.dev.TaskRun\" && $line =~ \"knative.dev/key\":\"default/maven-run-[a-zA-Z0-9-]+\" ]]; then
            task_run=$(echo "$line" | jq -r '."knative.dev/key"' | sed 's/^default\///')
            if [[ $task_run =~ ^maven-run-[a-zA-Z0-9]+-((git-clone)|(list-directory)|(maven-run))$ ]]; then
                pipeline_run=$(echo "$task_run" | cut -d'-' -f1-3)
                # Store task run with its controller assignment
                echo "$controller_key" > "$temp_dir/${task_run}.controller"
                echo "$task_run" >> "$temp_dir/${pipeline_run}.tasks"
                echo "$pipeline_run" >> "$temp_dir/all_pipelineruns"
            fi
        fi
    done < "$log_file"
done

# Get unique pipeline runs
sort -u "$temp_dir/all_pipelineruns" > "$temp_dir/unique_pipelineruns"

# Initialize controllers in JSON
for log_file in logs/controller-*.json; do
    controller_name=$(basename "$log_file" | cut -d'-' -f2 | cut -d'.' -f1)
    controller_key="controller-$controller_name"
    json_database=$(echo "$json_database" | jq --arg key "$controller_key" '. + {($key): {}}')
done

# Create a temporary file to store controller-task mappings
> "$temp_dir/controller_mappings"

# Process each pipeline run
while IFS= read -r pipeline_run; do
    [[ -z "$pipeline_run" ]] && continue
    
    # Get all task runs for this pipeline run
    if [[ -f "$temp_dir/${pipeline_run}.tasks" ]]; then
        # Clear the controller mappings for this pipeline run
        > "$temp_dir/controller_mappings"
        
        # Create mappings of controllers to task runs
        while IFS= read -r task_run; do
            if [[ -f "$temp_dir/${task_run}.controller" ]]; then
                controller=$(cat "$temp_dir/${task_run}.controller")
                echo "${controller}:${task_run}" >> "$temp_dir/controller_mappings"
            fi
        done < "$temp_dir/${pipeline_run}.tasks"
        
        # Process mappings for each controller
        for controller_key in $(cut -d':' -f1 "$temp_dir/controller_mappings" | sort -u); do
            # Get all task runs for this controller
            task_runs=$(grep "^${controller_key}:" "$temp_dir/controller_mappings" | cut -d':' -f2)
            
            # Skip if no task runs for this controller
            [[ -z "$task_runs" ]] && continue
            
            taskrun_array=$(echo "$task_runs" | jq -R . | jq -s '. | sort | unique')
            
            echo "Adding to $controller_key - Pipeline Run: $pipeline_run"
            echo "Task Runs: $(echo "$taskrun_array" | jq -c '.')"
            
            json_database=$(echo "$json_database" | jq --arg controller "$controller_key" --arg pipeline_run "$pipeline_run" --argjson taskruns "$taskrun_array" '
                .[$controller][$pipeline_run] = $taskruns
            ')
        done
    fi
done < "$temp_dir/unique_pipelineruns"

# Write the result to output.json
echo "$json_database" | jq '.' > output.json
echo "JSON database generated in output.json"
