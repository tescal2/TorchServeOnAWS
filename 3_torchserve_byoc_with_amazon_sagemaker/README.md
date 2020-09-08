### TorchServe using either a CPU or a GPU instance

Lab 3 allows you to proceed with a BYOC example on Amazon SageMaker using a CPU image that you have already spun up earlier. If you choose to also complete the "Using TorchServe with Containers with GPU-based Image" (Lab_3_gpu), then it requires a GPU instance. Follow these steps to create the appropriate GPU environment. 

*You are going to create an IAM Role and deploy a 'ml.p2.large' SageMaker instance. You can see the current pricing **[here](https://aws.amazon.com/sagemaker/pricing/).***

**[1]** To begin, sign in to your the AWS console. You will be launching a CloudFormation (CF) tempalte into one of the below regions.

**[2]** Next, click ONLY ONE icon below to launch a CF Template in your preferred region:

| Launch Template                                              | Region                         |
| :----------------------------------------------------------- | :----------------------------- |
| <a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?stackName=torchserve-on-aws&templateURL=https://torchserve-workshop.s3.amazonaws.com/torchserve-workshop-template.yaml"><img src="../media/cloudformation-launch-stack.png" ></a> | **N.Virginia** (us-east-1)     |
| <a href="https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/create/review?stackName=torchserve-on-aws&templateURL=https://torchserve-workshop-eu-west-1.s3-eu-west-1.amazonaws.com/torchserve-workshop-template.yaml" target="_blank"><img src="../media/cloudformation-launch-stack.png" ></a> | **Ireland** (eu-west-1)        |
| <a href="https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1#/stacks/create/review?stackName=torchserve-on-aws&templateURL=https://torchserve-workshop-ap-southeast-1.s3-ap-southeast-1.amazonaws.com/torchserve-workshop-template.yaml" target="_blank"><img src="../media/cloudformation-launch-stack.png" ></a> | **Singapore** (ap-southeast-1) |


**[3]** Check the three acknowledgement boxes and the orange 'Create Stack' button at the bottom as seen below:
![](media/cf-transforms.jpg)

*Your CloudFormation stack will take about 5 minutes to complete the creation of the Amazon SageMaker notebook instance and it's IAM role.*


**[4]** Once complete, ensure that you see you should see output similar to the following screen:

![](media/create-complete.jpg)

**[5]** Finally, head over to the **[Amazon SageMaker Console](https://console.aws.amazon.com/sagemaker/home?region=us-east-1#/notebook-instances)** and click on Notebook Instances from the left navigation pane. Identify your newly created notebook and the click the 'Open Jupyter' link as shown below:

![](media/open-jupyter.jpg)

*You can now proceed to the "[Lab 3] Using TorchServe with Containers - GPU".*
