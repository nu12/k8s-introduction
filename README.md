# Introduction à Kubernetes

Notes from the course [Introduction à Kubernetes](https://www.udemy.com/course/la_plateforme_k8s/).

## Node

```shell
$ kubectl get nodes -o wide
```

## Pod

```shell
$ kubectl run www --image=nginx:1.14-alpine
```

## Service

* ClusterIP

* NodePort

* LoadBalancer

```shell
$ kubectl expose pod POD_NAME --type=NodePort --port=8080 --target-port=80 

$ kubectl create service nodeport POD_NAME --tcp=8080:80
```

## Deployment

```shell
kubectl create deployment NAME --image=image -- [COMMAND] [args...] [options]
```

```shell
$ kubectl create deploy www --image=nginx:1.16
```

### Rollout/update

```shell
$ kubectl apply -f FILE.yaml
$ kubectl set image deploy/NAME CONTAINER_NAME IMAGE:TAG
```

### Rollout history

```shell
$ kubectl rollout history deploy/NAME
```

### Rollback

```shell
$ kubectl rollout undo deploy/NAME
$ kubectl rollout undo deploy/NAME --to-revision=X
```
### HorizontalPodAutoscaler
```shell
$ kubectl autoscale deploy www --min=2 --max=10 --cpu-percent=50
```
#### Metrics server 
```shell
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
$ kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```
## Namespace
```shell
$ kubectl create namespace NAME

$ kubectl delete namespace namespace/NAME

$ kubectl run www --image=nginx:1.14-alpine --namespace=development
```
### Resource Quota
```shell
$ kubectl create namespace test
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
	name: quota
spec:
	hard:
		requests.cpu: "1"
		requests.memory: 1Gi
		limits.cpu: "2"
		limits.memory: 2Gi
```
```shell
$ kubectl apply -f quota.yaml --namespace=test
```
Use pod-with-resource.yaml

## Secret

### Generic

```shell
$ kubectl create secret generic service-creds --from-file=file1 --from-file=file2
$ kubectl create secret generic service-creds --from-literal=key=value
```

```yaml
apiVersion: v1
kind: Secret
metadata:
	name: mongo-creds
data:
	mongoURL: bW9uZ29kY...XQ=
```

Using secrets as volumes.

```yaml
spec:
	containers:
		[...]
		volumeMounts:
		- name creds
		  mountPath: "/etc/creds"
		  readOnly: true
	volumes:
	- name: creds
	  secret:
	  	secretName: mongo-creds
# OR
	- name: creds
	  secret:
	  	secretName: service-creds
	  	- key: file1
	  	  path: service/file1
	  	- key: file2
	  	  path: service/file2
```


```shell
(container) $ cat /etc/creds/mongoURL
# OR
(container) $ cat /etc/creds/service/file1 && cat /etc/creds/service/file2
```

Using secret as environment variable.

```yaml
spec:
	containers:
		[...]
		env:
		- name: MONGO_URL
		  valueFrom:
		  	secretKeyRef
		  		name: mongo-creds
		  		key: mongoURL

```

### Registry

```shell
$ kubectl create secret docker-registry registry-creds --docker-server=FQND --docker-username=USERNAME --docker-password=PASSWORD --docker-email=EMAIL
```

```yaml
spec:
	containers:
		[...]
	imagePullSecrets:
	- name: registry-creds

```

### TLS

```shell
$ kubectl create secret tls domain-pki --cert /path/to/cert.pem --key /path/to/key.pem
```

```yaml
spec:
	containers:
		[...]
		volumeMounts:
		- name tls
		  mountPath: "/etc/ssl/certs/"
	volumes:
	- name: tls
	  secret:
	  	secretName: domain-pki

```

## ServiceAccount

Authentication & Authorization. Used by pods.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa

```

* Role / ClusterRole: List rules and permissions. Actions to be performed.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: list-pods
rules:
  - apiGroups:
    - ''
    resources:
    - pods
    verbs:
    - list

```

* RoleBinding / ClusterRoleBinding: Link ServiceAccount and Role.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: list-pods_demo-sa 
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: list-pods
subjects:
  - kind: ServiceAccount
    name: demo-sa
    namespace: default

```

## CronJob

```shell
$ kubectl apply -f say_hello.yaml
$ kubectl get po -w
```

```
say-hello-1607707740-kw2ml      0/1     Pending   0          0s
say-hello-1607707740-kw2ml      0/1     Pending   0          1s
say-hello-1607707740-kw2ml      0/1     ContainerCreating   0          1s
say-hello-1607707740-kw2ml      1/1     Running             0          14s
say-hello-1607707740-kw2ml      0/1     Completed           0          26s
say-hello-1607707800-grs2x      0/1     Pending             0          0s
say-hello-1607707800-grs2x      0/1     Pending             0          0s
say-hello-1607707800-grs2x      0/1     ContainerCreating   0          0s
say-hello-1607707800-grs2x      1/1     Running             0          8s
say-hello-1607707800-grs2x      0/1     Completed           0          18s
say-hello-1607707860-wr7pk      0/1     Pending             0          0s
```

```shell
$ kubectl logs say-hello-1607708040-g445k
```

```
Hello form kube
Fri Dec 11 17:34:26 UTC 2020
```

## Ingress

```shell
$ cat www-domain.yaml
```

```yaml
apiVersion: extensions/v1
kind: Ingress
metadata:
  name: www-domain
spec:
  rules:
  - host: www.example.com
  	http:
  	  paths:
  	  - backend:
  	  	serviceName: www
  	  	servicePort: 80
```

```shell
$ kubectl run www --image=nginx:1.12.2
$ kubectl expose deployment www --port=80 --target-port=80
$ kubectl apply -f www-domain.yaml
```

## Volumes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongo
spec:
  containers:
  - image: mongo:4.0
    name: mongo
    volumeMounts:
    - mountPath: /data/db
      name: data

# EmptyDir
  volumes:
    - name: data
      emptyDir: {}

# HostPath
  volumes:
    - name: data
      hostPath:
        path: /data-db

# AWS (EBS)
  volumes:
    - name: data
      awsElasticBlockStorage
      volumeID: EXISTING_VOLUME_ID
      fsType: ext4

# GCE (PD)
  volumes:
    - name: data
      gcePersistentDisk
      pdName: DISK_NAME
      fsType: ext4

# PVC
  volumes:
    - name: data
      persistentVolumeClaim
        claimName: claim
```

### PersistentVolume

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv
spec:
  storageClassName: manual
  capacity: 
    storage: "1Gi"
  accessModes:
  - "ReadWriteOnce"
  hostPath:
    path: /data/pv
```

### PersistentVolumeCLaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: claim
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```