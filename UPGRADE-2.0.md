# Upgrade from v1.x to v2.x

If you find a bug, please open an issue with supporting configuration to reproduce.

## Changes

- Converted the CodePipeline output artifact from the deprecated `aws_s3_bucket_object` resource type to the supported `aws_s3_object` resource type.

## List of backwards incompatible changes

- `aws_s3_object` was added in AWS provider v4 and is not supported in AWS provider versions 3.74.2 or earlier

### State Changes

To migrate from the `v1.x` version to `v2.x` version of the module, the following state remove and import commands can be performed to maintain the current resources without unnecessary modification:

```bash
terraform import 'module.ecs_service.aws_s3_object.artifacts_s3' my-artifact-bucket/artifacts.zip
terraform state rm 'module.ecs_service.aws_s3_bucket_object.artifacts_s3'
```

The above commands simply import the existing object and remove the old reference from state - no terraform configuration changes are necessary.
