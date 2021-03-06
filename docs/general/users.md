# User Management

## Amazon IAM

### MFA Devices

For better security we recommend IAM accounts are secured using an MFA device.

You will need to use a hardware device or install a software application such as [Google Authenticator][1] on your smartphone.

Due to an AWS security limitation IAM roles cannot assume other IAM roles without MFA enabled. Therefore you must enable MFA
if you are using an application such as [AWS Vault][2].

For more information on MFA, please refer to the AWS product page: https://aws.amazon.com/iam/details/mfa/.

## SSH Access

As MageCloudKit launches resources inside an Amazon VPC, you must use a [Bastion host](https://docs.aws.amazon.com/quickstart/latest/linux-bastion/architecture.html)
to securely access resources. By default, MageCloudKit launches a single Bastion instance with an Amazon Elastic IP
address. You can then use this host to 'jump' to further instances.

First, discover the public IP address of the Bastion instance:

```bash
$ aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion*" --query 'Reservations[].Instances[].[PublicDnsName, PublicIpAddress]' --output table
```

Then connect to it with SSH key forwarding enabled: 

```bash
$ ssh -A -i private/deployer.pem ubuntu@bastion_ip
```

You can then 'jump' to further instances. Keep in mind as the App Servers are based on the Amazon ECS Optimized AMI,
you must use the `ec2-user`:

```bash
$ ssh ec2-user@172.30.0.187
```

## VPN Access

We recommend installing the OpenVPN software on the Bastion instance, however MageCloudKit does not include
built-in support for this.

[1]: https://support.google.com/accounts/answer/1066447
[2]: https://github.com/99designs/aws-vault
