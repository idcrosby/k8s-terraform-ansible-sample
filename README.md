This is a customized version of https://github.com/opencredo/k8s-terraform-ansible-sample

This is used to setup a Kubernetes cluster inside China (CN region)

========

The following variables need to be set inside ./terraform/terraform.tfvars

default_keypair_public_key = 
control_cidr = # CIDR of the VPC being used}
default_keypair_name = 
vpc_name = # Name of the existing VPC to use
vpc_id = # ID of the existing VPC
subnet_cidr = #CIDR to use (within the subnet)
iam_instance_id = # ID of the IAM instance to use
amis = { cn-north-1 = [ID of the AMI to use] }

The required kubernetes binaries must be fetched and put inside the ./binaries/ directory

========

This setup will create the following:

- 3 EC2 instances for HA Kubernetes Control Plane: Kubernetes API, Scheduler and Controller Manager
- 3 EC2 instances for *etcd* cluster
- 3 EC2 instances as Kubernetes Workers (aka Minions or Nodes)
- Kubenet Pod networking (using CNI)
- HTTPS between components and control API
- Sample *nginx* service deployed to check everything works


## Pre reqs

You will need a custom `pause` container. You can create your own by [starting here](https://github.com/kubernetes/kubernetes/tree/5520386b180d3ddc4fa7b7dfe6f52642cc0c25f3/build/pause). The image name needs to be specified in ./ansible/group_vars/all/vars.yaml 

## AWS Credentials

### AWS KeyPair

You need a valid AWS Identity (`.pem`) file and the corresponding Public Key. Terraform imports the [KeyPair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) in your AWS account. Ansible uses the Identity to SSH into machines.

Please read [AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws) about supported formats.

### Terraform and Ansible authentication

Both Terraform and Ansible expect AWS credentials set in environment variables:
```
$ export AWS_ACCESS_KEY_ID=<access-key-id>
$ export AWS_SECRET_ACCESS_KEY="<secret-key>"
```

If you plan to use AWS CLI you have to set `AWS_DEFAULT_REGION`.

Ansible expects the SSH identity loaded by SSH agent:
```
$ ssh-add <keypair-name>.pem
```

## Provision infrastructure, with Terraform

Run Terraform commands from `./terraform` subdirectory.

```
$ terraform plan
$ terraform apply
```

Terraform outputs public DNS name of Kubernetes API and Workers public IPs.
```
Apply complete! Resources: 12 added, 2 changed, 0 destroyed.
  ...
Outputs:

  kubernetes_api_dns_name = lorenzo-kubernetes-api-elb-1566716572.eu-west-1.elb.amazonaws.com
  kubernetes_workers_public_ip = 54.171.180.238,54.229.249.240,54.229.251.124
```

You will need them later (you may show them at any moment with `terraform output`).

## Install Kubernetes, with Ansible

Run Ansible commands from `./ansible` subdirectory.


### Install and set up Kubernetes cluster

Install Kubernetes components and *etcd* cluster.
```
$ ansible-playbook infra.yaml
```

### Setup Kubernetes CLI

Configure Kubernetes CLI (`kubectl`) on your machine, setting Kubernetes API endpoint (as returned by Terraform).
```
$ ansible-playbook kubectl.yaml --extra-vars "kubernetes_api_endpoint=<kubernetes-api-dns-name>"
```

Verify all components and nodes (workers) are up and running, using Kubernetes CLI (`kubectl`).

```
$ kubectl get componentstatuses
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-2               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}

$ kubectl get nodes
NAME                                       STATUS    AGE
ip-10-43-0-30.eu-west-1.compute.internal   Ready     6m
ip-10-43-0-31.eu-west-1.compute.internal   Ready     6m
ip-10-43-0-32.eu-west-1.compute.internal   Ready     6m
```

### Setup Pod cluster routing

Set up additional routes for traffic between Pods.
```
$ ansible-playbook kubernetes-routing.yaml
```
