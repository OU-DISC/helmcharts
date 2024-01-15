# Generic OU/DISC Helm Chart

> This is a fork of the DBVIS Generic Helm Chart kindly provided by the Data Analysis and Visualization Group, University of Konstanz, Germany.

This helm chart should work for 90% of the projects you do.
It features a deployment, service, multiple optional ingresses and optional PVC.
Additional convenience features are also included (see configuration).

## Usage

### Example pipeline

Please check this gitlab CI example pipeline: https://gitlab.dbvis.de/support/websites/generic-helm-chart/-/blob/master/dbvis-generic/.gitlab-ci.example.yml

### Via OCI (preferred)

The chart is hosted as the metadata of an container image (in this container registry).

In your CI job you need to do the following:


#### This only works for version &geq; 3.0.0 with helm CLI version &geq; 3.7.0

```yaml
variables:
  # your kubernetes namespace
  K8_NAMESPACE: MY_NAMESPACE
  # the registry url of the helm chart
  HELM_CHART: oci://registry.dbvis.de/support/websites/generic-helm-chart/dbvis-generic
  # the current version of the dbvis-generic helm chart
  HELM_CHART_VERSION: 3.0.0
  # just a docker image that contains the HELM binary. This job uses this image to run the stuff below.
  HELM_IMAGE: alpine/helm:3.8.0


deploy-job:
  stage: deploy
  image:
    name: $HELM_IMAGE
    entrypoint: [""]
  script:
    # Login helm into docker registry
    - echo ${CI_REGISTRY_PASSWORD} | helm registry login -u ${CI_REGISTRY_USER} --password-stdin ${CI_REGISTRY}
    # now you can use this chart as usual:
    - helm upgrade --install --namespace=${K8_NAMESPACE} MY_RELEASE ${HELM_CHART} --version ${HELM_CHART_VERSION} 
  tags:
    - no-cache
```

#### This only works for version &leq; 2.6.0 with helm CLI version &leq; 3.6.x

```yaml
variables:
  # your kubernetes namespace
  K8_NAMESPACE: MY_NAMESPACE
  # the registry url of the helm chart
  HELM_CHART: registry.dbvis.de/support/websites/generic-helm-chart
  # the current version of the dbvis-generic helm chart
  HELM_CHART_VERSION: v2.6.0
  # just a docker image that contains the HELM binary. This job uses this image to run the stuff below.
  HELM_IMAGE: alpine/helm:3.6.3


deploy-job:
  stage: deploy
  image:
    name: $HELM_IMAGE
    entrypoint: [""]
  script:
    # log in (basically the same as docker login)
    - echo ${CI_REGISTRY_PASSWORD} | helm registry login -u ${CI_REGISTRY_USER} --password-stdin ${HELM_CHART}
    # downloads the metadata
    - helm chart pull ${HELM_CHART}:${HELM_CHART_VERSION}
    # exports the file into the ./dbvis-generic folder
    - helm chart export ${HELM_CHART}:${HELM_CHART_VERSION}
    # now you can use this chart as usual:
    - helm upgrade --install --namespace=${K8_NAMESPACE} MY_RELEASE ./dbvis-generic
  tags:
    - docker
```

> Note: You can use the extended example for this job as shown in the tutorial: https://gitlab.dbvis.de/support/websites/generic-helm-chart/-/blob/master/dbvis-generic/.gitlab-ci.example.yml

### Copying the chart

Feel free to simply copy the folder dbvis-generic from this repository in your own repository.
You can then use this helm chart as a starter and modify it further according to your convenience.
An example deploy job then looks like this (assuming your folder is called `./my-helm-chart`)

```yaml
variables:
  # your kubernetes namespace
  K8_NAMESPACE: MY_NAMESPACE
  # just a docker image that contains the HELM binary. This job uses this image to run the stuff below.
  HELM_IMAGE: alpine/helm:3.8.0

deploy-job:
  stage: deploy
  image:
    name: $HELM_IMAGE
    entrypoint: [""]
  script:
    # now you can use this chart as usual:
    - helm upgrade --install --namespace=${K8_NAMESPACE} MY_RELEASE ./my-helm-chart
  tags:
    - docker
```

> Note: This way you will not automatically receive bugfixes or adjustments from the upstream dbvis-generic chart. Everything remains in your responsibility.

## Configuration

The following table lists the configurable parameters of the dbvis Generic chart and their default values.

Parameter | Description | Default | Added in version
---|---|---|---
`app.image.name` | **DEPRECATED use app.image.repository instead (will be removed in 4.0.0)** Use app.image.repository instead | `null`
`app.image.repository` | Custom image (e.g., registry.dbvis.de/jentner/covid-19-vis, mysql) | `null`
`app.image.tag` | Custom image tag | `latest`
`app.image.pullPolicy` | Custom image pull policy | `Always`
`app.image.cmd` | **DEPRECATED use app.cmd instead (will be removed in 4.0.0)** Overwrite the command that is executed to start your container. You can define it as an array: `["./start-app.sh"]` | `null` (use the defined command in the Dockerfile)
`app.image.args` | **DEPRECATED use app.args instead (will be removed in 4.0.0)** Overwrite the arguments for a command at container start. You can define it as an array: `["arg0", "arg1", "arg2"]` | `null` (use the defined arguments in the Dockerfile)
`app.type` | Either `Deployment` or `StatefulSet` | `Deployment` | 2.6.0
`app.replicaCount` | Number of replicas | `1`
`app.cmd` | Overwrite the command that is executed to start your container. You can define it as an array: `["./start-app.sh"]` | `null` (use the defined command in the Dockerfile) | 3.9.0
`app.args` | Overwrite the arguments for a command at container start. You can define it as an array: `["arg0", "arg1", "arg2"]` | `null` (use the defined arguments in the Dockerfile) | 3.9.0
`app.port` | Defines the container port(s) and port(s) for service. Can be either a single port `app.port: 80` or a list of ports `app.port: [80, 8080]` (number or name). The first port is used for the liveness and readiness probes (if applicable). Currently only the first port is supported as external ingress. See values.yaml for more. | `1313`
`app.nodePort` | Optional: Defines the node port for the service. Must be in range `30000-32767`. A node port cannot be allocated by two services at the same time. | `null` | 3.8.0
`app.health` | Defines the path for the httpGet health and readiness check. Can be overwritten in `app.readinessProbe` and `app.livenessProbe` | `/`
`app.regcred` | The registry credential | `regcred`
`app.updateStrategy` | **Only used if `app.type=Deployment`!** The update strategy for your Deployment. Change to `Recreate` if you want your pods to be killed before the new ones are deployed. | `RollingUpdate`
`app.extraEnv: ` | Define extra environment variables (see values.yaml) | `""`
`app.extraEnvFrom: ` | Define environment from secrets or configmaps (see values.yaml) | `null`
`app.readinessProbe: ` | Define readiness probe (see values.yaml & https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes)  | (see values.yaml)
`app.livenessProbe: ` | Define liveness probe (see values.yaml & https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) | (see values.yaml)
`app.startupProbe: ` | Define startup probe (see values.yaml & https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) | `null` | 2.5.0
`app.requests.cpu` | Define CPU request | `null` (using default of namespace)
`app.requests.memory` | Define memory request | `null` (using default of namespace)
`app.requests.ephemeralStorage` | Define ephemeral storage request | `null` (using default of namespace)
`app.requests.gpu` | Define the desired number of GPUs. The pod will be placed on a node that has _at least_ the number of GPUs available. However, it will not be ensured that the GPUs are free. If multiple workloads use the same GPUs, the GPUs will rebalance the load and the application will be a little bit slower. The number here is not a limit. If you specify one GPU (`1`) and the node where the pod is placed has four (`4`) GPUs available, your application will have access to all four GPUs if you do not take any measures in your code. | `null` | 3.4.0
`app.limits.cpu` | Define CPU limit | `null` (using default of namespace)
`app.limits.memory` | Define memory limit | `null` (using default of namespace)
`app.limits.ephemeralStorage` | Define ephemeral storage limit | `null` (using default of namespace)
`app.gpu.devices` | This is only active if app.requests.gpu is set. With the default "all" it will give you access to all GPU devices that are available on the node. You may also define specific device-indices such as "0,2", which would only give you access to GPU0 and GPU2 from that node. Alternatively, you may also specify the device id. More information is available here: https://github.com/NVIDIA/nvidia-container-runtime#nvidia_visible_devices You can check here which GPUs are currently being used: https://k8-grafana.dbvis.de/d/Oxed_c6Wz/nvidia-dcgm-exporter-dashboard?orgId=1&refresh=5s | `all` | 3.4.0
`app.podAntiAffinity` | PodAntiAffinity allows you to properly spread pods across the cluster. If you use multiple replicas to ensure a better uptime, it does not make sense if all of your pods would get scheduled on the same worker-node. With PodAntiAffinity, the pods can be spread out based on the topology key which, in the example in values.yaml, is set to  `topology.rook.io/chassis` and stands for a host (charon01, charon06, ...). If you use two replicas and enable the podAntiAffinity, the two pods should be deployed such that each run on a separate host (and not just on a separate worker). Read more about podAntiAffinity here: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#an-example-of-a-pod-that-uses-pod-affinity | `null`<br>**(see values.yaml for an example)** | 3.5.0
`app.podSecurityContext.runAsUser` | Specifies that for any Containers in the Pod, all processes run with user ID. Default: use the default user as defined in the image. | `null` | 3.7.0
`app.podSecurityContext.runAsGroup` | Specifies the primary group ID for all processes within any containers of the Pod. If this field is omitted, the primary group ID of the containers will be root(0) | `null` | 3.7.0
`app.podSecurityContext.fsGroup` | When fsGroup field is specified, all processes of the container are also part of the supplementary group ID of fsGroup. The owner for volumes and any files created in that volume will be with that group ID. | `null` | 3.7.0
`app.pvc.enabled` | Enable PVC | `false`
`app.pvc.existingClaim` | Specify this to use an existing PVC. Must be the name of an existing PVC if set. | `null`
`app.pvc.accessMode` | The access mode of the PVC | `ReadWriteMany`
`app.pvc.storage` | The requested storage | `1Gi`
`app.pvc.mountPath` | The mount path in your container | `/tmp/app`
`app.pvc.storageClassName` | The storage class. Defaults to the default storage class provided in the cluster. | `null`
`app.pvc.volumeName` | The name of a specific PV. Must have been created manually beforehand. | `null`
`app.pvc.selector` | Optional: Add a label selector to match a PV. | `{}`
`app.pvc.readOnly` | Optional: Mark the volume as read only. | `false`
`app.extraPvcs` | Define additional PVCs (see values.yaml) | `[]`
`app.ingress.enabled` | Enable ingress | `true`
`app.ingress.url` | The url for your app | `null`
`app.ingress.extraAnnotations` | An array to customize your proxy handling with [Ingress-NGINX Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) | `nil` (see values.yaml)  
`app.ingress.auth.enabled` | Enables basic authentication for your app | `false`
`app.ingress.auth.prompt` | The prompt the user sees before authenticating | `This website is password protected. Please enter a username and password.`
`app.ingress.auth.secret` | The name of the secret where the auth information is stored. See values.yaml for example. | `basic-auth`
`app.ingress.internal.enabled` | Enable a whitelist-source-range annotation to make your app only accessible for the LSKeim network. | `false`
`app.ingress.internal.whitelistSourceRange` | The IP source range that can access your service. [See NGINX doc for valid values](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#whitelist-source-range). | `134.34.225.45/32` (LSKeim Network)
`app.extraIngresses` | An array for additional ingresses. | `nil` (see values.yaml)
`app.hostVolumes` | An array for host volumes. | `[]` (see values.yaml)
`app.configMapVolumes` | An array for config map volumes.| `[]` (see values.yaml)
`app.configMaps` | An array of config maps (with name and data). | `[]` (see values.yaml)
`app.secretVolumes` | An array for secret map volumes. Allows to mount secrets as files into the container. | `[]` (see values.yaml)
`app.secrets` | An array of secrets (with name and data). | `[]` (see values.yaml)


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```console
$ helm install --name my-release -f values.yaml ./dbvis-generic
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Examples

This section features some example `values.yaml` files that you can use as a starter.

> Note: This section is work in progress.

### Basic app

It is assumed that your image runs a basic http server such as NGINX or APACHE which runs on port `80`.

```yaml
app:
  regcred: regcred
  port: 80
  health: "/"

  requests:
    cpu: 10m
    memory: 50Mi
  limits:
    cpu: 200m
    memory: 100Mi

  ingress:
    ## if you want to login with username and password
    # auth:
    #  enabled: true
    #  secret: my-auth-secret

    ## if you want your app to be only reachable from the LS Network
    # internal:
    #   enabled: true

```

And for a generic gitlab-ci configuration, see [HERE](https://gitlab.dbvis.de/support/websites/generic-helm-chart/-/blob/master/generic.gitlab-ci.yaml)
For your deployment, you will need to modify the URL and K8_NAMESPACE variables near the top of the file. 
Your K8_NAMESPACE is typically your last name, and requires a kubeconfig file provided by the support team.

### Troubleshooting

In case you want to pull from a private repository:
  1. Create a deployment token (see https://docs.gitlab.com/ee/user/project/deploy_tokens/)
  2. Add the deployment token to your kubernetes namespace:
     ```shell_script
     kubectl create secret docker-registry SECRET_NAME --docker-server=registry.dbvis.de --docker-username=TOKEN_USERNAME --docker-password=TOKEN_PASSWORD --namespace=NAMESPACE
     ```
  3. Adjust the value of `app.regcred` in `values.yaml` to match `SECRET_NAME`
