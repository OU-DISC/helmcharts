# Changelog

## 3.9.0

Changed default value `app.pvc.storageClassName` to `null` to use the default storage class of the cluster.
Rename `app.image.cmd` -> `app.cmd` and `app.image.args` -> `app.args` (backwards compatible).

## 3.8.0

Allows to add a node port to the service via `app.nodePort`.

## 3.7.0
Allows to specify the podSecurityContext which is applied to all containers of the pod.
The PodSecurityContext allows to overwrite the user and group that runs the container as well as to specify the group under which all volumes are being mounted.
More information here: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod
and here: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#podsecuritycontext-v1-core

```yaml
app:
  podSecurityContext:
    # run the container as user with id 1000
    runAsUser: 1000
    # run the container with PRIMARY group id 2000
    runAsGroup: 2000
    # Mount all files and volumes with that group id (2000)
    fsGroup: 2000
```

## 3.6.0
This change allows for secret volumes, that is a secret that is mounted as files into you container.
This is similar to config map volumes.

```yaml
app:
  secretVolumes:
  ## if you want to use the secrets defined below, prefix secretName with "${$.Release.Name}"
  - name: secret1vol
    secretName: "{{ $.Release.Name }}-secret1"
    mountPath: /mysecrets/secret1
  ## This is the default. Secrets should not be changed from a container
    readOnly: true
  
  ## The following secret defined in the secretvolume must be generated manually as it does not use the .Release.Name-prefix
  - name: secret2vol
    secretName: my-manual-secret
    mountPath: /mymanualsecret

  secrets:
  ## Secrets defined here will be automatically prefixed with .Release.Name to avoid any collisions.
  - name: secret1
  ## this will be resolved as {{.Release.Name}}-secret1
  ## The default type is Opaque
    type: Opaque
  ## If this is false the deployment will fail if the secret does not exist
    optional: true
  ## Define the stringData for your secret. The .stringData assumes LITERAL strings
    stringData:
      file1: |-
        This is a multiline
        secret
      file2: This is a single line secret
  ## Optional: Define data for your secret. The .data assumes BASE64 ENCODED strings
  ## The value for file3 is "this is a test" with base64 encoding
    data:
      file3: dGhpcyBpcyBhIHRlc3Q=

```


## 3.5.0
Added support for podAntiAffinity.
```yaml
app:
  # define as a template string
  podAntiAffinity: |
    # if it is not possible to schedule the pod on a different host (see below), the pod will be scheduled on the same host
    preferredDuringSchedulingIgnoredDuringExecution:
        # weights are only relevant if multiple rules are being used
        - weight: 100
          podAffinityTerm:
            # labelselector selects all pods with the same deploymentName as the one defined by the release (this is true if replicaCount > 1)
            labelSelector:
              matchExpressions:
              - key: deploymentName
                operator: In
                values:
                - {{ .Release.Name }}
            # The topology key is a label that we use on the nodes (e.g., `kubectl describe node kube-worker1` => topology.rook.io/chassis=charon07; expl: kube-worker1 runs on host charon07)
            # This means that this antiAffinity rule will separate the pods in such way that they are placed on different charon hosts (actual hosts).
            # This will keep your service alive even if a full host and all its VMs, including kubernetes workers fail.
            topologyKey: topology.rook.io/chassis
```

## 3.4.0
Added support for GPU scheduling.
```yaml
app:
  requests:
    gpu: 2

  gpu:
    devices: all
```
These values will schedule the pod on a node where at least 2 GPUs are available. The pod will have access to __ALL__ GPUs on that node.
If the pod should have access to only __TWO__ GPUs, then  `app.gpu.devices` should be set to `0,1` or any other tuple within (0,1,2,3).
In this example, the pod will have access to GPU0 and GPU1 of that node. 

## 3.3.0
We added support for overriding the container's command and passing arguments: 

```yaml
app:
  image: 
    cmd: your_cmd
    args: 
    - an
    - array
    - of
    - arguments
```

## 3.2.0
We added support for ConfigMaps and volumes based on ConfigMaps:
```yaml
configmaps:
  - name: configmap1
    data:
      file1: ...
      file2: ...

  - name: configmap2
    data:
      file1: ...
      file2: ...

configMapVolumes:
  - name: configmap1vol
    configMapName: configmap1
    mountPath: /configmaps/configmap1

  - name: configmap2vol
    configMapName: configmap2
    mountPath: /configmaps/configmap2
```


## 3.1.0

Add support for multiple ports.
This chart is backward compatible.

A port definition can now look like this:

```yaml
app:
  port:
    - 8080
    - 1313
```
Note, that the first port in the list will be used for the ingress.
All ports will be accessible through the Service (unnamed) and opened for the container in the Pod.

The old port definition will continue to work!
```yaml
app:
  port: 8080
```

> Thanks Max Fischer!

## 3.0.0

### Caution! This helm chart version only works with helm CLI version &geq; 3.7

### Breaking changes

There is nothing changed in the helm chart itself but with version 3.7 of helm the packaging has been changed.
Therefore, you need to make some adjustments in your CI pipeline:

Variables section old:
```yaml
variables:
  # [...]
  #
  # Helm chart (default dbvis-generic-chart)
  HELM_CHART: registry.dbvis.de/support/websites/generic-helm-chart
  #
  # Helm chart version
  HELM_CHART_VERSION: v2.6.0
  #
  # [...]
  #
  # Helm image (only works with helm chart version <= 2.6.0)
  HELM_IMAGE: alpine/helm:3.6.3
  # [...]
```

Variables section new:
```yaml
variables:
  # ...
  #
  # Helm chart (default dbvis-generic-chart)
  HELM_CHART: oci://registry.dbvis.de/support/websites/generic-helm-chart/dbvis-generic
  #
  # Helm chart version
  HELM_CHART_VERSION: 3.0.0
  #
  # [...]
  #
  # Helm image (only works with helm chart version >= 3.0.0)
  HELM_IMAGE: alpine/helm:3.8.0
  # [...]
```


Deploy job script old:
```yaml
.deploy-script: &deploy-template
  # [...]
  script:
    # [...]
    # Login helm into docker registry
    - echo ${CI_REGISTRY_PASSWORD} | helm registry login -u ${CI_REGISTRY_USER} --password-stdin ${HELM_CHART}
    # list all available charts (locally)
    - helm chart list
    # pull the generic helm chart
    - helm chart pull ${HELM_CHART}:${HELM_CHART_VERSION}
    # export the generic helm chart to ./dbvis-generic
    - helm chart export ${HELM_CHART}:${HELM_CHART_VERSION}
    # now you can use this chart as usual:
    - helm upgrade --install --namespace=${K8_NAMESPACE} MY_RELEASE ./dbvis-generic

    # [...]
```

Deploy job script new:
```yaml
.deploy-script: &deploy-template
  # [...]
  script:
    # [...]
    # Login helm into docker registry
    - echo ${CI_REGISTRY_PASSWORD} | helm registry login -u ${CI_REGISTRY_USER} --password-stdin ${CI_REGISTRY}
    # directly install from OCI registry:
    - helm upgrade --install --namespace=${K8_NAMESPACE} MY_RELEASE ${HELM_CHART} --version ${HELM_CHART_VERSION} 
    # [...]
```

You can find the current CI example pipeline working with this version [here](./.gitlab-ci.example.yml)


Kudos to Max Fischer for figuring this out!


## 2.6.0

### Caution! This helm chart version only works with helm CLI version &leq; 3.6

### Features
- Added `app.type` (default `Deployment`). Allows the user to choose `StatefulSet` as a deployment option.


## 2.5.0

### Features
- Added `app.startupProbe` (default `null`). Allows the user to define a startup probe which is useful for pods/containers that have a long startup time.

