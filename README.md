# drunken-banana


To avoid hardcoding secrets (like my email address), please pass the backup notification email at deploy time using CDK context:
cdk deploy -c backupEmail=...