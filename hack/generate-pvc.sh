#!/bin/bash

# Generate and apply 20 PVCs
for i in $(seq 1 30); do
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: maven-source-pvc-${i}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Mi
EOF
done

echo "Applied 20 PVCs to the cluster."
