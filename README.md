# StatefulSet Deployment Testing for Tekton Pipelines Controller

In this repository, we test the deployment of Tekton Pipelines Controller as a StatefulSet. The goal is to verify how the system handles pipeline runs, task runs, and controller workload distribution.

## Test Scenario

The following steps outline the test scenario and the commands used to apply tasks, pipelines, and generate the required resources.

### Apply the used tasks

To apply the necessary tasks, run the following commands:

```bash
# Apply custom task definition
kubectl apply -f .tekton/list-dir-task.yaml

# Apply Git Clone task from Tekton Catalog
kubectl -n tekton-pipelines apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/git-clone/0.9/git-clone.yaml

# Apply Maven task from Tekton Hub
kubectl apply -f https://api.hub.tekton.dev/v1/resource/tekton/task/maven/0.3/raw

# Once the tasks are applied, you need to apply the pipeline definition
kubectl apply -f .tekton/pipeline-mvn.yaml

# Create the PVCs required for the test by running
./generate-pvc.sh

# Now, generate the PipelineRuns for the test
./generate-pr.sh

# You can check if the PipelineRuns are complete by running
tkn pr ls

# Collect logs from the Tekton controllers, run the following script
./collect-logs.sh

# Once the logs are collected, generate a JSON database with the following command
./generate-db.sh

# Finally, analyze the generated JSON database
./analyze-db.sh

```

### Result Output / Observations
After running the analysis script, you will see the following output:
```bash
➜  ./analyze-db.sh
Analysis of controller workload:
--------------------------------
Pipeline runs per controller:
controller-0: 70 pipeline runs
controller-1: 72 pipeline runs

Task runs per controller:
controller-0: 115 task runs
controller-1: 128 task runs

```

- The load is evenly distributed between controllers
- Check output.json for taskruns distribution between controllers
- The work for one single pipelinerun is distributed among the controllers.
- Multiple killing of the controllers during the runs doesn't affect the taskruns completion
