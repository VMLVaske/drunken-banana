import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as path from 'path';
import * as fs from 'fs';

interface AppStackProps extends cdk.StackProps {
  sshIp?: string;
}

export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: AppStackProps) {
    super(scope, id, props);

    // ec2 instance (ubuntu, free tier)
    // security group (access only via ssh & ghost)
    // s3 bucket for backup

    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVPC', { isDefault: true });

    const securityGroup = new ec2.SecurityGroup(this, 'GhostSG', {
      vpc,
      description: 'Allow SSH and ghost (port 2368)',
      allowAllOutbound: true,
    });

    // Allow SSH access only from specified IP
    securityGroup.addIngressRule(
      ec2.Peer.ipv4(props?.sshIp || '0.0.0.0/0'),
      ec2.Port.tcp(22),
      'SSH access'
    );

    // Ghost access
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(2368), 'Ghost access');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'HTTP access');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'HTTPS access');

    // must already exist in aws
    const keyName = 'ghost-key';

    // protecting the backup email
    const email = this.node.tryGetContext('backupEmail') || 'noreply@example.com';

    const userData = ec2.UserData.forLinux();

    const scriptPath = path.join(__dirname, '../scripts/setup.sh');
    const scriptContent = fs.readFileSync(scriptPath, 'utf8');


    userData.addCommands(
      'cat > /home/ubuntu/setup.sh <<EOF',
      ...scriptContent.split('\n'),
      'EOF',
      'chmod +x /home/ubuntu/setup.sh',
      'sudo /home/ubuntu/setup.sh > /home/ubuntu/setup.log 2>&1'
    );

    const instance = new ec2.Instance(this, 'GhostInstance', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      machineImage: ec2.MachineImage.genericLinux({ 'eu-central-1': 'ami-012a41984655c6c83' }),
      securityGroup,
      keyName,
      userData,
    });

    cdk.Tags.of(instance).add('Name', 'GhostVM');

    new cdk.CfnOutput(this, 'InstancePublicIp', {
      value: instance.instancePublicIp,
      description: 'Public IP address of the Ghost instance'
    });
  }
}
