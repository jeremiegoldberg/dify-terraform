# dify-terraform

> Dify, an LLM application platform, on Kubernetes — every component described
> in Terraform rather than assembled by hand from a compose file.

![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.0-7B42BC?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-provider%20~%3E%202.0-326CE5?logo=kubernetes&logoColor=white)
![Licence](https://img.shields.io/badge/licence-MIT-blue)

Dify ships a `docker-compose.yaml` and that is where most deployments stop. This
is the same system as nine Kubernetes workloads with their services, secrets,
config and ingress, written down — so that what is running can be read, diffed
and destroyed.

## What it deploys

| Component | Role |
|---|---|
| `dify-api` | The backend |
| `dify-web` | The frontend |
| `dify-worker` | Background jobs |
| `dify-postgres` | Application database |
| `dify-redis` | Cache and queue |
| `dify-weaviate` | Vector store |
| `dify-sandbox` | Isolated runtime for user-submitted code |
| `dify-ssrf` | Squid proxy — the sandbox reaches the network only through it |
| `dify-nginx` | Routes the five hostnames to the right service |

The sandbox and the SSRF proxy are the pair worth noticing. Dify runs code
users write. `dify-sandbox` executes it, and `dify-ssrf` is what stops that code
from reaching your cluster's internal addresses. Deploying one without the other
gives you a working platform and an open door.

## Requirements

- A Kubernetes cluster and a kubeconfig that reaches it
- An ingress controller — the ingress is written for NGINX
- Terraform 1.0 or later

## Running it

Everything has a working default except the passwords.

```sh
cd terraform

export TF_VAR_PG_USERNAME=dify
export TF_VAR_PG_PASSWORD='…'
export TF_VAR_REDIS_PASSWORD='…'
export TF_VAR_WEAVIATE_API_KEY='…'
export TF_VAR_SECRET_KEY='…'          # Dify's own session key

terraform init
terraform apply -var domain=dify.example.com
```

| Variable | Default | |
|---|---|---|
| `domain` | `dify.lan` | Base domain; five hostnames are derived from it |
| `namespace` | `dify` | Namespace everything lands in |
| `kubeconfig_path` | `~/.kube/config` | |
| `registry` | *(empty)* | Registry to pull the images from; empty means Docker Hub |
| `image_tag` | `1.1.3` | Pin it |
| `storage_path` | `/root/dify` | Host path for the persistent volumes |
| `tls_cert_path` `tls_key_path` | *(empty)* | Point at a certificate to create the TLS secret |
| `create_dns_records` | `false` | See below |

## The two optional pieces

**TLS.** No certificate is in the repository, and none should be. Give
`tls_cert_path` and `tls_key_path` a certificate you already have and the secret
is created and attached to the ingress; leave them empty and TLS is left to
cert-manager or to the controller's default. Empty is the default so a fresh
clone can be planned without inventing a certificate first.

**DNS on a Mikrotik router.** `create_dns_records` writes A records for the five
hostnames onto a RouterOS device. That is how the author resolves them on a home
network, and it is almost certainly not how you do it — hence off by default.
With it off, the `routeros` provider is still declared but creates nothing, and
you point your own DNS at your ingress controller.

## What this does not do

- **Persistence is host paths.** `storage_path` becomes `hostPath` volumes, so
  the data is tied to whichever node the pod landed on. That is fine for one
  node and wrong for a real cluster, which wants a StorageClass and real
  PersistentVolumeClaims.
- **No resource requests or limits.** Nothing here tells the scheduler what
  these pods need, and the vector store and the worker are not small.
- **No probes.** Kubernetes will route traffic to a pod that is running and not
  yet ready, and will not restart one that has wedged.
- **No autoscaling, no PodDisruptionBudget, no NetworkPolicy.** The SSRF proxy
  constrains the sandbox's egress by configuration, not by cluster policy.
- **Secrets come from the environment**, which means they end up in Terraform
  state. State belongs in a backend with encryption and restricted access; the
  `backend.tf.tpl` here is a template, not a configured backend.

None of these are hard to add. All of them are missing on purpose, so that this
reads as one system rather than as a production deployment nobody reviewed.

## Licence

MIT.
