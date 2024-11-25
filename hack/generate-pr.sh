#!/bin/bash

# Generate and apply 20 PVCs
for i in $(seq 1 30); do
  cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: maven-run-
spec:
  pipelineRef:
    name: maven-build
  params:
    - name: git-repo
      value: https://github.com/jkhelil/sample-maven.git
    - name: git-revision
      value: main
  workspaces:
    - name: shared-workspace
      persistentvolumeclaim:
        claimName: maven-source-pvc-${i}
    - name: maven-settings
      emptyDir: {}
    - name: maven-local-m2
      emptyDir: {}
EOF
done

echo "Applied 20 PVCs to the cluster."
