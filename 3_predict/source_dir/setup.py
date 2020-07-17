from setuptools import setup, find_packages

setup(name='sagemaker-roberta-example',
      version='1.0',
      description='SageMaker Example for RoBERTa.',
      packages=find_packages(exclude=('tests', 'docs')))
