#!/bin/bash

for i in {0..2}; do
  kubectl logs tekton-pipelines-controller-$i -n tekton-pipelines | sed '/Registering [0-9] clients/d;/Registering [0-9] informer factories/d;/Registering [0-9] informers/d;/Registering [0-9] controllers/d;/Readiness and health check server listening on port 8080/d' > logs/controller-$i.json
done
    
