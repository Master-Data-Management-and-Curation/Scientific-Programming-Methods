# Introduction to Kubernetes: practical session

**Today's goals**: Spawn a local Kubernetes cluster with `kind`, deploy a simple web application on it with plain `kubectl` manifests.

> [!WARNING]
> **`kind` is NOT a real Kubernetes cluster!**
>
> `kind` squeezes a whole cluster into a few containers on a single machine. It is meant **only for testing**: a **playground** where you can experiment with Kubernetes, break things and start over in seconds.
>
> It is not how Kubernetes runs in production (no real nodes, no real networking, no real storage, no high availability). When you will have to deploy your code for real, someone will usually give you access to a real cluster: use `kind` only to check that your manifests and charts work before going there, and nothing more!

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Introduction to Kubernetes: practical session](#introduction-to-kubernetes-practical-session)
  - [0. Installation](#0-installation)
  - [1. My first cluster with kind](#1-my-first-cluster-with-kind)
  - [2. Deploy a simple application with kubectl](#2-deploy-a-simple-application-with-kubectl)
  - [3. Clean up](#3-clean-up)

<!-- markdown-toc end -->

<details>
<summary>Using a remote connection?</summary>

Use the same `$HOME/.ssh/config` of the [containers lecture](03-intro-to-container.md), we will need again the `LocalForward 8080 ...` line to reach the application from the browser of your laptop.
</details>

## 0. Installation

We need three tools:

| Tool      | What it does                                                                                     |
|-----------|--------------------------------------------------------------------------------------------------|
| `kind`    | **K**ubernetes **in** **D**ocker: runs a whole Kubernetes cluster inside containers (podman works too!) |
| `kubectl` | The command line client to talk with any Kubernetes cluster                                      |

All of them are single static binaries, so installing them means just downloading the binary and putting it in the `$PATH`.
We do not have root privileges, so instead of `/usr/local/bin` we use `~/.local/bin`, a directory in our home, and add it to the `$PATH`:

```bash
mkdir -p ~/.local/bin
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**kind**

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
install -m 0755 kind ~/.local/bin/kind
rm kind
```

**kubectl**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -m 0755 kubectl ~/.local/bin/kubectl
rm kubectl
```

Check that everything is in place:

```bash
kind version
kubectl version --client
```

> As always, your best friends are `kind --help`, `kubectl --help`  and each subcommand has its own help page (e.g. `kubectl get --help`).

## 1. My first cluster with kind

Now let's create the cluster (it takes a minute or two, the first time it has to pull the node image):

```bash
kind create cluster --name spm
```

<details>
<summary>Cluster creation fails?</summary>

Running Kubernetes without root relies on the cgroup controllers that systemd delegates to our user. If `kind create cluster` complains about cgroups or `Delegate=yes`, remove the half-created cluster and retry inside a dedicated systemd scope:

```bash
kind delete cluster --name spm
systemd-run --user --scope -p Delegate=yes kind create cluster --name spm
```
</details>

`kind` also configured `kubectl` for us (in `~/.kube/config`), so we can already talk with the cluster:

```bash
kubectl get nodes
kubectl cluster-info --context kind-spm
```

```
NAME                STATUS   ROLES           AGE   VERSION
spm-control-plane   Ready    control-plane   42s   v1.37.0
```

***Where is this "node"?***

$\rightarrow$ It is just a container! Have a look:

```bash
podman ps
```

```
CONTAINER ID  IMAGE                                  COMMAND  CREATED        STATUS        PORTS                      NAMES
b5c1a6e4f2d1  docker.io/kindest/node:v1.37.0@sha...           2 minutes ago  Up 2 minutes  127.0.0.1:41235->6443/tcp  spm-control-plane
```

Inside this container there is a whole Kubernetes control plane plus a container runtime (`containerd`) that will run *our* containers. Containers inside a container!

Kubernetes already runs some pods for its own needs. Pods are grouped in **namespaces**, let's look at all of them:

```bash
kubectl get pods --all-namespaces
```

## 2. Deploy a simple application with kubectl

We will deploy the same `nginx` web server we used with podman-compose. In Kubernetes we do not run containers directly, we **describe the state we want** in a YAML file (a *manifest*) and Kubernetes takes care of reaching and keeping that state.

We need two objects:

- a **Deployment**: "I want 2 copies (*replicas*) of a pod running `nginx:alpine`"
- a **Service**: "give a single stable name and IP to all the pods with label `app: nginx`"

Both are described in the [`nginx.yaml`](../codes/06-intro-to-kubernetes/nginx.yaml) file of the [`06-intro-to-kubernetes`](../codes/06-intro-to-kubernetes) folder: have a look at it, then move into that folder (all the commands below are run from there).

And apply it:

```bash
kubectl apply -f nginx.yaml
```

Check what happened:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-5869d7778c-7xkqp   1/1     Running   0          20s
nginx-5869d7778c-pz9lw   1/1     Running   0          20s
```

***How can I reach my web server?***

$\rightarrow$ Same problem we had with containers: the service lives inside the cluster network. The quickest way out is `kubectl port-forward`, which works like the `-p` option of `podman run`:

```bash
kubectl port-forward --address 0.0.0.0 service/nginx 8080:80
```

Open `http://localhost:8080`: welcome to nginx! Stop the port-forward with `Ctrl+C`.

> `--address 0.0.0.0` is needed only if you are on the remote VM, so that the ssh tunnel can reach it. On your laptop you can omit it.

**Kubernetes keeps the state you asked for.** Let's see why this is more than `podman-compose`.

*Self-healing*: delete one of the pods (use one of the names from `kubectl get pods`)

```bash
kubectl delete pod <pod_name>
kubectl get pods
```

A new pod has been created immediately to replace it: we asked for 2 replicas, so there will be 2 replicas.

*Scaling*:

```bash
kubectl scale deployment nginx --replicas=5
kubectl get pods
```

**Exercise**: bring the deployment back to 2 replicas **without** using `kubectl scale`.

<details>
<summary>Solution</summary>

`nginx.yaml` is the source of truth: edit `replicas: 2` there (it is already 2, so nothing to edit!) and re-apply it.

```bash
kubectl apply -f nginx.yaml
```

This is the *declarative* approach: you change the description, Kubernetes changes the reality.

</details>

**Exercise**: change the image to `httpd:alpine` (the apache web server) and watch the pods being replaced with `kubectl get pods -w`. Then check it in the browser.

<details>
<summary>Solution</summary>

Edit `image: nginx:alpine` to `image: httpd:alpine` in `nginx.yaml`, then

```bash
kubectl apply -f nginx.yaml
kubectl get pods -w
```

Kubernetes performs a *rolling update*: new pods are started before the old ones are killed, so the service never goes down.

</details>

Before moving on, remove everything:

```bash
kubectl delete -f nginx.yaml
```


## 3. Clean up

The whole cluster is just a container, so deleting it is instantaneous:

```bash
kind delete cluster --name spm
podman ps -a
```

---

**Repetita juvant!**

Delete everything (the `my-nginx` chart and the cluster), write your own `nginx.yaml` and `prod.yaml` from scratch and repeat all the steps by yourself!
