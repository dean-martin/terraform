#!/usr/bin/env bash
aws s3 sync www/ s3://$(terraform output -raw s3_bucket)/ --delete
