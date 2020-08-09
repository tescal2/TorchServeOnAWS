### Prerequisites

Before beginning to setup the EKS cluster you must first install the required command line tools. You will need to have the following prerequisites installed to deploy [Torch Serve](https://github.com/pytorch/serve) to EKS.

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [eksctl and kubectl](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)
* [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)

Let's test to ensure we have the correct version of the AWS CLI, eksctl, and kubectl.

```
aws --version
eksctl version
kubectl version --short --client
```
#### Create Environment Variables

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

#### Complete Setup

The following script will generate two json policy files, two yaml manifest files and ensure you have properly set all the required enviroment variables.

```
chmod +x ./scripts/*.sh
./scripts/complete_setup.sh
```

#### [Optional] Setup IAM Roles and Policies

An IAM user needs certain AWS resource permissions to set up the EKS cluster for TorchServe. However, if you set up the TorchServe EKS cluster using an AWS Admin account, this step on IAM policies should be skipped and you should proceed directly to the following step:  **Subscribe to EKS-optimized AMI with GPU Support in the AWS Marketplace**.

(A pre-requisite to this step is having an IAM User named "*EKSUser*". To see how to create an IAM User see [Creating an IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html))

The following two steps require admin privilege

##### Create IAM Policy

```
aws iam create-policy --policy-name eks_ami_policy \
    --policy-document file://eks_ami_policy.json
```

##### Attach policy to user

```
aws iam attach-user-policy \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/eks_ami_policy \
    --user-name EKSUser
```

#### Subscribe to EKS-optimized AMI with GPU support in the AWS Marketplace

To run Amazon EKS with a GPU, you must first [subscribe](https://aws.amazon.com/marketplace/pp/B07GRHFXGM) to Amazon EKS-optimized AMI with GPU support from the console using your AWS account. The Amazon EKS-optimized AMI with GPU support builds on top of the standard Amazon EKS-optimized AMI, and configures to serve as the base image for Amazon P2, P3, and G4 instances in Amazon EKS Clusters. Following the link and clicking **subscribe** will ensure that the EKS node creation step succeeds.

![AWS Marketplace console](https://d2908q01vomqb2.cloudfront.net/ca3512f4dfa95a03169c5a670a4c91a19b3077b4/2020/07/29/wu-fig.3-1024x259.jpg)

Read more about the marketplace console [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/launch-marketplace-console.html).

### Getting Started

#### Create an EKS Cluster

Use eksctl to create your self-managed Amazon EKS Cluster.  eksctl creates and deploys a CloudFormation stack of the name 'eksctl-<your cluster name>-cluster'.

```
eksctl create cluster -f ${MANIFESTS_DIR}/cluster.yaml

or

eksctl create cluster \
    --name=$AWS_CLUSTER_NAME \
    --region=$AWS_REGION \
    --version=1.17 \
    --ssh-access \
    --ssh-public-key=~/.ssh/id_rsa.pub \
    --nodegroup-name=$NODE_GROUP_NAME \
    --node-type=$NODE_TYPE \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 4
```

<strong>Note:</strong> Provisioning a cluster typically takes about 15 minutes. You may track the progress in the console window for the CloudFormation service.

<strong>Note:</strong> Often with using eksctl to create a K8s cluster on AWS EKS, the process will become stuck waiting for the nodes to join the cluster. You will receive the following error message: `waiting for at least 2 node(s) to become ready in "<your namespace>"`. Read this [blog](https://blog.doit-intl.com/eksctl-stuck-on-waiting-for-nodes-to-join-the-cluster-c3670aa74487) for tips on resolving this error.

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

#### Install Nvidia device plugin to enable GPU support on your cluster

The Nvidia device plugin for Kubernetes is a Daemonset that allows you to run GPU enabled containers. If you selected an accelerated AMI instance type and the Amazon EKS-optimized accelerated AMI, then you must apply the Nvidia device plugin using the following command:

```
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/1.0.0-beta4/nvidia-device-plugin.yml
```

If you installed the Nvidia device plugin, you can check it's status.

```
kubectl get daemonset -n kube-system

kubectl get service,po,daemonset,pv,pvc --all-namespaces
```

#### Enable CloudWatch logging for cluster

In order to enable CloudWatch logs for the cluster, on all types (api, audit, authenticator, controllerManager, scheduler), run the following command.

```
eksctl utils update-cluster-logging \
		--cluster=$AWS_CLUSTER_NAME \
		--region=$AWS_REGION \
		--enable-types all \
		--approve
```

<strong>Note:</strong> If you receive an error related to permissions, run the following, optional script which will apply the appropriate inline policy and then update cluster logging.

```
#Optional step: only if the above step requires additional priviledge.
chmod +x ./scripts/setup_CloudWatch_logging.sh
./scripts/setup_logging.sh
```

#### Deploy Pods to EKS cluster

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

#### Register models with TorchServe

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
### Conduct inference on the endpoint
There are multiple ways in which to invoke inference from the cluster. In this post, we will query it directly by using the curl method as demonstrated in the [TorchServe’s model serving example](https://github.com/pytorch/serve). To test the TorchServe model server, you just need to send a request to the Inference API. Let's start by pulling down an image of a [Proboscis Monkey](https://en.wikipedia.org/wiki/Proboscis_monkey) and a [Tiger Beetle](https://en.wikipedia.org/wiki/Tiger_beetle).![img](https://torchserve-workshop.s3.amazonaws.com/proboscis-monkey-tiger-beetle-grouped.png)

```
# Save the image locally
curl -O https://torchserve-workshop.s3.amazonaws.com/proboscis-monkey.jpg
curl -O https://torchserve-workshop.s3.amazonaws.com/tiger-beetle.jpg
```

Now that we have two images, we can use curl to send POST to the TorchServe predict endpoint with our images. The predictions endpoint returns a prediction response in JSON. With both the Proboscis Money and the Tiger Beetle, we see several different prediction types along with their associated confidence scores of each prediction.
#####  Send the images for inference
```
curl -X POST http://${PUBLIC_IP}:8080/predictions/densenet161 -T proboscis-monkey.jpg
```

```
curl -X POST http://${PUBLIC_IP}:8080/predictions/densenet161 -T  tiger-beetle.jpg
```

You will see that these results are the same as seen with Lab 01.

### Cleaning up
To avoid unecessary charges, run the following command to complete remove the cluster and tear down the associated infrastructure:

```
./scripts/cleanup.sh
```
