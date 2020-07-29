#!/bin/bash
echo "Beginning cleanup..."
rm -rf model_store
rm -rf logs
rm -rf serve
rm -rf *.jpg
rm -rf *.pth
rm -rf *.pth.*
echo "Cleanup complete!"
