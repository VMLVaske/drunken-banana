import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as path from 'path';
import * as fs from 'fs';

export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'GhostVPC', {
      maxAzs: 2,
      natGateways: 0,
    })

    const securityGroup = new ec2.SecurityGroup(this, 'GhostSG', {
      vpc,
      description: 'Allow HTTP and SSH',
      securityGroupName: 'GhostSecurityGroup'
    });

    // Allow SSH access only from specified IP
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(22), 'Allow SSH');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'Allow HTTP');

    const role = new iam.Role(this, 'GhostEC2Role', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore')
      ]
    });

    // must already exist in aws
    const keyName = 'ghost-key';

    // protecting the backup email
    const email = this.node.tryGetContext('backupEmail') || 'noreply@example.com';

    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      'sudo apt update -y',
      'sudo apt install -y docker.io docker-compose',
      'sudo systemctl enable docker',
      'sudo systemctl start docker',
      'sudo usermod -aG docker ubuntu',
      'mkdir -p /home/ubuntu/ghost',
      'cd /home/ubuntu/ghost',
      'curl -o docker-compose.yml https://raw.githubusercontent.com/YOUR_GITHUB_REPO/main/docker-compose.yml',
      'sudo docker-compose up -d'
    );

    const instance = new ec2.Instance(this, 'GhostEC2Instance', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      machineImage: ec2.MachineImage.genericLinux({ 'eu-central-1': 'ami-012a41984655c6c83' }),
      securityGroup,
      role,
      keyName,
      userData,
    });

    cdk.Tags.of(instance).add('Name', 'GhostVM');

    new cdk.CfnOutput(this, 'InstancePublicIp', {
      value: instance.instancePublicIp ?? 'Not available yet',
      description: 'Public IP address of the Ghost instance'
    });
  }
}
