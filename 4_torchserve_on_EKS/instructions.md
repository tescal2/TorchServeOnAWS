## Prerequisites

You can use your local machine (Mac or Windows) for this lab as well as using an Ubuntu Linux EC2 instance. If you choose a Linux EC2 instance, you will need to set a security group such that may SSH into the instance and run the commands shown throughout this lab. 

- [Getting started with Amazon EC2 Linux instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html)

And then, you will need to install the required command line tools on that instance. Before beginning to setup the EKS cluster you must first install the required command line tools. You will need to have the following prerequisites installed to deploy [TorchServe](https://github.com/pytorch/serve) to EKS.

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [eksctl and kubectl](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)
- [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)

<strong>Note: </strong>With a new Ubuntu Linux instance, you may first need to update your environment and install the following packages to continue.

```
sudo apt-get update
sudo apt install python3-pip
sudo apt install unzip
```

### Set up AWS CLI
`pip3 install --upgrade --user awscli`

### Install the AWS CLI version 2 on Linux
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
### Verify AWS CLI
`aws --version`

and then you will need to run 

`aws configure`

### Install kubectl and eksctl
```
if [ -d "installs" ]; then
    rm -r -f installs
fi
mkdir installs
cd installs
```
### Install eksctl
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin
```
### Install kubectl
```
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.7/2020-07-08/bin/linux/amd64/kubectl

curl -o kubectl.sha256 https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.7/2020-07-08/bin/linux/amd64/kubectl.sha256

openssl sha1 -sha256 kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
```

Let's test to ensure we have the correct version of the AWS CLI, eksctl, and kubectl
```
aws --version
eksctl version
kubectl version --short --client
```
### Install IAM Authenticator
`curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator`

[Optional]: Verify the downloaded binary with the SHA-256 sum provided in the same bucket prefix. 
1. Download the SHA-256 sum for your system. To download the Arm version, change amd64 to arm64 before running the command.
   `curl -o aws-iam-authenticator.sha256 https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator.sha256`
2. Check the SHA-256 sum for your downloaded binary.
   `openssl sha1 -sha256 aws-iam-authenticator`
3. Compare the generated SHA-256 sum in the command output against your downloaded `aws-iam-authenticator.sha256` file. The two should match.
4. Apply execute permissions to the binary.
   `chmod +x ./aws-iam-authenticator`
1. Copy the binary to a folder in your `$PATH`. We recommend creating a `$HOME/bin/aws-iam-authenticator` and ensuring that `$HOME/bin` comes first in your `$PATH`.
`mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin`
1. Add `$HOME/bin` to your `PATH` environment variable.
`echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc`
1.  Test that the `aws-iam-authenticator` binary works.
`aws-iam-authenticator help`

### Create Environment Variables

```
export AWS_ACCOUNT=<your account number>
export AWS_REGION=<region>
export AWS_CLUSTER_NAME=<clustername ex: TorchServe>
export AWS_NAMESPACE=<namespace ex: workshop-inference>
export SERVICE_NAME=<service name ex: test-service>
export NODE_TYPE=p3.2xlarge
export NODE_GROUP_NAME=<name for nodegroup ex: ng-1>
export MANIFESTS_DIR=$(pwd)/manifests
```

## Complete Setup
### Download repo for scripts and templates

```
cd ~
wget -P ./repo https://github.com/tobrien0/TorchServeOnAWS/archive/master.zip
unzip ./repo/master.zip -d ./repo

if [ -d "scripts" ]; then
	rm -r -f scripts
fi
cp -r ./repo/TorchServeOnAWS-master/4_torchserve_on_EKS/scripts/ ./scripts/

if [ -d "templates" ]; then
	rm -r -f templates
fi
cp -r ./repo/TorchServeOnAWS-master/4_torchserve_on_EKS/templates/ ./templates/
```

The following script will generate two json policy files, two yaml manifest files and ensure you have properly set all the required enviroment variables.

```
chmod +x ./scripts/*.sh
./scripts/complete_setup.sh
```

### [Optional] Setup IAM Roles and Policies

An IAM user needs certain AWS resource permissions to set up the EKS cluster for TorchServe. However, if you set up the TorchServe EKS cluster using an AWS Admin account, this step on IAM policies should be skipped and you should proceed directly to the following step: **Subscribe to EKS-optimized AMI with GPU Support in the AWS Marketplace**.

(A pre-requisite to this step is having an IAM User named "*EKSUser*". To see how to create an IAM User see [Creating an IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html))

The following two steps require admin privilege

#### Create IAM Policy

<strong>Note: </strong> You will need to run aws configure in order to establish credentials on the instance.

```
aws iam create-policy --policy-name eks_ami_policy \
    --policy-document file://eks_ami_policy.json
```

#### Attach policy to user

```
aws iam attach-user-policy \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/eks_ami_policy \
    --user-name EKSUser
```

### Subscribe to EKS-optimized AMI with GPU support in the AWS Marketplace

To run Amazon EKS with a GPU, you must first [subscribe](https://aws.amazon.com/marketplace/pp/B07GRHFXGM) to Amazon EKS-optimized AMI with GPU support from the console using your AWS account. The Amazon EKS-optimized AMI with GPU support builds on top of the standard Amazon EKS-optimized AMI, and configures to serve as the base image for Amazon P2, P3, and G4 instances in Amazon EKS Clusters. Following the link and clicking **subscribe** will ensure that the EKS node creation step succeeds.

[![AWS Marketplace console](https://camo.githubusercontent.com/782052c50c01c6911d6e7c01973d56a996029475/68747470733a2f2f6432393038713031766f6d7162322e636c6f756466726f6e742e6e65742f636133353132663464666139356130333136396335613637306134633931613139623330373762342f323032302f30372f32392f77752d6669672e332d31303234783235392e6a7067)](https://camo.githubusercontent.com/782052c50c01c6911d6e7c01973d56a996029475/68747470733a2f2f6432393038713031766f6d7162322e636c6f756466726f6e742e6e65742f636133353132663464666139356130333136396335613637306134633931613139623330373762342f323032302f30372f32392f77752d6669672e332d31303234783235392e6a7067)

Read more about the marketplace console [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/launch-marketplace-console.html).

## Getting Started

### Create an EKS Cluster

Use eksctl to create your self-managed Amazon EKS Cluster. eksctl creates and deploys a CloudFormation stack of the name 'eksctl--cluster'.

```
eksctl create cluster -f ${MANIFESTS_DIR}/cluster.yaml

or

eksctl create cluster \
    --name=$AWS_CLUSTER_NAME \
    --region=$AWS_REGION \
    --ssh-access \
    --ssh-public-key=~/.ssh/id_rsa.pub \
    --nodegroup-name=$NODE_GROUP_NAME \
    --node-type=$NODE_TYPE \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 4
```

**Note:** Provisioning a cluster typically takes about 15 minutes. You may track the progress in the console window for the CloudFormation service.

**Note:** Often with using eksctl to create a K8s cluster on AWS EKS, the process will become stuck waiting for the nodes to join the cluster. You will receive the following error message: `waiting for at least 2 node(s) to become ready in "<your namespace>"`. Read this [blog](https://blog.doit-intl.com/eksctl-stuck-on-waiting-for-nodes-to-join-the-cluster-c3670aa74487) for tips on resolving this error.

When the cluster is ready, you may verify that the cluster was properly created, test that your kube configuration is correct, and view the contents of the fargate profile.

```
eksctl utils describe-stacks --region=$AWS_REGION --cluster=$AWS_CLUSTER_NAME
```

You'll note that this command shows the cluster information (e.g. VPC and IAM info), the CloudFormation stack name, stack status, the name of the cluster and the eksctl version. You can use the following eksctl and kubectl commands to show additional information.

```
eksctl get clusters
eksctl get nodegroup --cluster=$AWS_CLUSTER_NAME

kubectl get nodes
kubectl get svc
kubectl get namespaces --show-labels
```

### Install Nvidia device plugin to enable GPU support on your cluster

The Nvidia device plugin for Kubernetes is a Daemonset that allows you to run GPU enabled containers. If you selected an accelerated AMI instance type and the Amazon EKS-optimized accelerated AMI, then you must apply the Nvidia device plugin using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/1.0.0-beta4/nvidia-device-plugin.yml
```

If you installed the Nvidia device plugin, you can check it's status.

```
kubectl get daemonset -n kube-system

kubectl get service,po,daemonset,pv,pvc --all-namespaces
```

### Enable CloudWatch logging for cluster

In order to enable CloudWatch logs for the cluster, on all types (api, audit, authenticator, controllerManager, scheduler), run the following command. <strong>Note: </strong>this may have been already updated via the cluster creation via the cluster.yaml file.

```
eksctl utils update-cluster-logging \
		--cluster=$AWS_CLUSTER_NAME \
		--region=$AWS_REGION \
		--enable-types all \
		--approve
```

**Note:** If you receive an error related to permissions, run the following, optional script which will apply the appropriate inline policy and then update cluster logging.

```
#Optional step: only if the above step requires additional priviledge.
chmod +x ./scripts/setup_logging.sh
./scripts/setup_logging.sh
```

### Deploy Pods to EKS cluster

Next, you will create the kubectl namespace and then deploy the pods to the EKS cluster using that namespace.

```
NAMESPACE=$AWS_NAMESPACE; kubectl create namespace ${NAMESPACE}

kubectl -n ${NAMESPACE} apply -f ${MANIFESTS_DIR}/deployment.yaml
```

After this is complete, you can check the k8s namespaces and confirm that the deployment is set up and ensure the service is running the following commands.

```
kubectl get ns

kubectl get pods -n ${NAMESPACE}
```

### Register models with TorchServe

Get the external IP for the service and store it in a variable:

```
PUBLIC_IP=`kubectl get svc -n ${NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'`
```

Here, we register densenet161, a pretrained, publicly available model. For more details on the required contents of the model file, read the [docs for the model-archiver utility](https://github.com/pytorch/serve/tree/master/model-archiver), which is provided with TorchServe.

```
curl --write-out %{http_code} --silent --output /dev/null --retry 5 -X POST "http://${PUBLIC_IP}:8081/models?url=https://torchserve.s3.amazonaws.com/mar_files/densenet161.mar&initial_workers=1&synchronous=true"
```

You may then query the list of registered models to verify our pre-trained densenet_161 model is being served.

```
curl "http://${PUBLIC_IP}:8081/models"
```

## Conduct inference on the endpoint

There are multiple ways in which to invoke inference from the cluster. In this post, we will query it directly by using the curl method as demonstrated in the [TorchServe’s model serving example](https://github.com/pytorch/serve). To test the TorchServe model server, you just need to send a request to the Inference API. Let's start by pulling down an image of a [Proboscis Monkey](https://en.wikipedia.org/wiki/Proboscis_monkey) and a [Tiger Beetle](https://en.wikipedia.org/wiki/Tiger_beetle).[![img](https://camo.githubusercontent.com/2bf41f02c95cf7c058ecb5b270fc2034c555a2f4/68747470733a2f2f746f72636873657276652d776f726b73686f702e73332e616d617a6f6e6177732e636f6d2f70726f626f736369732d6d6f6e6b65792d74696765722d626565746c652d67726f757065642e706e67)](https://camo.githubusercontent.com/2bf41f02c95cf7c058ecb5b270fc2034c555a2f4/68747470733a2f2f746f72636873657276652d776f726b73686f702e73332e616d617a6f6e6177732e636f6d2f70726f626f736369732d6d6f6e6b65792d74696765722d626565746c652d67726f757065642e706e67)

```
# Save the image locally
curl -O https://torchserve-workshop.s3.amazonaws.com/proboscis-monkey.jpg
curl -O https://torchserve-workshop.s3.amazonaws.com/tiger-beetle.jpg
```

Now that we have two images, we can use curl to send POST to the TorchServe predict endpoint with our images. The predictions endpoint returns a prediction response in JSON. With both the Proboscis Money and the Tiger Beetle, we see several different prediction types along with their associated confidence scores of each prediction.

#### Send the images for inference

```
curl -X POST http://${PUBLIC_IP}:8080/predictions/densenet161 -T proboscis-monkey.jpg
curl -X POST http://${PUBLIC_IP}:8080/predictions/densenet161 -T  tiger-beetle.jpg
```

You will see that these results are the same as seen with Lab 01.

## Cleaning up

To avoid unecessary charges, run the following command to complete remove the cluster and tear down the associated infrastructure:

```
./scripts/cleanup.sh
```
