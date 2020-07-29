#!/bin/bash
echo "Confirming prerequisites..."
sudo rpm --import https://yum.corretto.aws/corretto.key > /dev/null 2>&1
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo > /dev/null 2>&1
sudo yum install -y java-11-amazon-corretto-devel > /dev/null 2>&1

pip install torch torchtext torchvision sentencepiece psutil future > /dev/null 2>&1
pip install torchserve torch-model-archiver > /dev/null 2>&1

if [ -d "serve" ]; then
    rm -r -f serve > /dev/null 2>&1
fi
git clone https://github.com/pytorch/serve.git serve > /dev/null 2>&1

if [ -d "model_store" ]; then
    rm -f model_store/* > /dev/null 2>&1
else
    mkdir model_store > /dev/null 2>&1
fi
echo "Prerequisites complete!"
