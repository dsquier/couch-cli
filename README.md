# couch-cli

Shell scripts, test data, and related files used to manage CouchDB 2.x and above instances.

## Installing couch-cli scripts

NOTE: These are bash shell scripts and will not work in Windows without the Windows Subsystem for Linux

### 1. Installing on Windows:

- Ensure you have the Windows Subsystem for Linux - https://docs.microsoft.com/en-us/windows/wsl/install-win10
- Click the Windows key and type: 'env'
- Select 'Edit the System Environment Variables'
- Click the `Environment Variables` button on the bottom right of the modal
- Under `User variables for davidsq`, select `Path` and click `Edit`
- Click `New` on the upper right of the modal
- Enter the directory where you have downloaded this repo, i.e., `C:\Users\davidsq\GitHub\couch-cli`
- Save the entry and open a new window, you should be able to type `load-folder` and have it find the script.

### 2. Installing on Linux/MacOS

- Edit `.bash_profile`
- Enter the directory where you have downloaded this repo, i.e., `C:\Users\davidsq\GitHub\couch-cli`
- Save the profile and open a new shell, you should be able to type `load-folder` and have it find the script.

---
## Building a CouchDB server

### 1. Create EC2 Instance

- In the AWS EC2 Console, select "Launch Instance".
- On the left menu, select "My AMIs"
- Select: `couchdb-2.1.1-ami`
- Select the instance size (`t2.xlarge` is typical for dev/staging)
- Select the proper VPC for the Network (i.e., `hydra-dev-network` for dev)
- Select the following Security Groups (i.e., `default`, `dev-couchdb-full`, `hydra-dev-network-InstanceSG` for dev)
- Select the key pair: `db-key-20161115` (used for all environments)

This AMI includes pre-installed: CouchDB 2.1.1 binaries, nfs-common, backup/restore cron scripts (~ubuntu/cron)

### 2. Update EFS Mount for Environment

- Add the EFS mount to fstab so it is automatically mounted on instance reboot for the current environment. Each environment has it's own EFS mount, which is only available in that VPC.

```
sudo vi /etc/fstab
```

Then, add/edit the following line:

```
fs-<EFS-ID>.efs.us-west-2.amazonaws.com:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0
```

- To edit the CouchDB local configuration to point to the EFS filesystem

```
sudo vi /opt/couchdb/etc/local.d/10-admins.ini
```

Add the following two lines under the `[couchdb]` heading

```
database_dir = /efs/couchdb
view_index_dir = /efs/couchdb
```

### 3. Create and seed `master` database

- Clone https://github.com/dsquier/couch-cli and add the destination to your computers path.
- Configure `.env` file to point to the database you are installing
- Clone https://github.com/trddev/chassis-tuner-db and change CWD into `chassis-tuner-db`
- You should see a script called: `seed.sh`, execute this.

### 4. Setup backups on EC2 instance and environment

Add the following line to crontab:

```
20 8 * * * /home/ubuntu/cron/couchdb-backup >> /home/ubuntu/cron/couchdb-backup.log
```

### 5. Mount the EFS voluem

Run this command
```
sudo mount -a
```

### 6. Restart Couchdb

Run this command
```
sudo service couchdb restart
```

### 7. Test to confirm Couch is working

The following command run on the server
```
ubuntu:/home/ubuntu> curl 127.0.0.1:5984
```

should produce this output 
```
{"couchdb":"Welcome","version":"2.1.1","features":["scheduler"],"vendor":{"name":"The Apache Software Foundation"}}
```

### 8. Run a backup and confirm it was created

Run this command, then check the corresponding bucket/prefix in the output. You should see this followed by many lines showing the files it is syncing to S3.

```
ubuntu:/home/ubuntu> /home/ubuntu/cron/couchdb-backup 
+------------------------
| BACKUP STARTED        : Fri Feb 9 18:48:34 UTC 2018
+------------------------
| Backing up from       : /efs/couchdb
| Backing up to         : s3://trd-couchdb/backups/prod/prod-20180209184834
+------------------------
```

### 9. Attach the EC2 instance to the correct Target Group

- Login to the AWS console
- Open the target group matchign the environment (ex: CouchDBRepprod-TargetGroup)
- Select the Targets tab
- Click the Edit button
- Filter by instance id, then select the proper instance
- Click the "Add to registered" button
- Click the "Save" button
- Wait for the Status of the registered target to change to "healthy"
- Do a GET request to the ALB endpoint to confirm the response matches Step 7 above.
- Ex: http://cfnalbchassistunerdb-prod-1500121724.us-west-2.elb.amazonaws.com:5984/ should return 
```
{
  "couchdb": "Welcome",
  "version": "2.1.1",
  "features": [
    "scheduler"
  ],
  "vendor": {
    "name": "The Apache Software Foundation"
  }
}
```

### 10. Create a username/password 

TBD

---
## Creating a CouchDB AMI

* [CouchDB 2.1.1 Installation Guide](http://docs.couchdb.org/en/2.1.1/install/unix.html)

### 1. Create EC2 instance

Create a new EC2 instance based on Ubuntu 16.04. Typically a `t2.xlarge` instance is sufficient for all but production loads.

### 2. Update OS packages

One or more restarts may be required as part of this process.

```
sudo apt-get update
sudo apt-get upgrade
```

### 3. Install CouchDB

```
echo "deb https://apache.bintray.com/couchdb-deb xenial main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update && sudo apt-get install couchdb
```

- If you receive the following message, answer "Yes"

```
WARNING: The following packages cannot be authenticated!
  couchdb
Install these packages without verification? [y/N]
```

- When prompted for type of CouchDB configuration, choose: `Standalone`

- When prompted to set CouchDB interface bind address, enter: `0.0.0.0`

- When prompted to set the CouchDB "admin" user, enter your selected password.

### 4. Install required packages and configure awscli

```
sudo apt-get install nfs-common
sudo apt-get install python3-pip
pip3 install awscli
aws configure
```

- As ubuntu user, copy `.bash_profile` file to `~ubuntu` to enable helper shortcut commands.
- As ubuntu user, create a `~ubuntu/cron` directory and copy the following files to it:

```
couchdb-backup
couchdb-restore
couchdb-list-backups
```

Then, make them executable:

```
chmod +x ~ubuntu/cron/couchdb-*
```

### 5. Create mount point for EFS

```
sudo mkdir /efs
```

### 6. Create an AMI from the EC2 image

- http://docs.aws.amazon.com/toolkit-for-visual-studio/latest/user-guide/tkv-create-ami-from-instance.

--
## Upgrading CouchDB

### 1. Create new EC2 instance and install latest CouchDB

- https://github.com/dsquier/couch-cli#building-a-couchdb-server

### 2. Create backup of DB using couchdb-backup

### 3. Restore backup of DB to new EC2 instance using couchdb-restore

### 4. Edit /opt/couchdb/local.d/10-admins.ini and under [admins] ensure the couchdb user for the environment has the correct password.

### 5. Update CloudFormation stack for <env>-load-balancers and replace the CouchDBInstanceId with the new EC2 instance ID

### 6. Ensure the couchdb user password is set for the environment properly

### 7. Update Chassis Tuner DB Target Group
- Add the new EC2 instance to TargetChassisTunerDB-<env>
- Remove the old EC2 instance from TargetChassisTunerDB-<env>

### 8. Verify new DB is being used by:
- Going to https://dev.trddev.com/chassis-tuner/ and creating a new vehicle setup
- Going to http://127.0.0.1:5995/_utils/#database/master/_all_docs (assuming you mapped 5894 -> 5995)
- Confirm new vehicle setup exists in the new EC2 instance

