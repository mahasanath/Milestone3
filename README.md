### Devops - Deployment Milestone    


##### Mahalaxmi Sanathkumar (smahala@ncsu.edu)  & Parul Upadhyaya (pupadhy2@ncsu.edu)


#### Pre-steps to setup deployment server on an Ubuntu server.
--------------------------------------------------------------

* In the Milestone 1, we have already built a pipeline that supports application builds. The build can be triggered either by 'Build Now' option in jenkins master->jobs GUI which is running on the server 'ec2-54-148-145-59.us-west-2.compute.amazonaws.com'(lets say AWS1) (as per our 
setup in Milestone1 or by SCM change. With each git push, application build is triggered. (Please see that the amazon instance IP has changed as we have restarted the instance).

* The project that has been setup for the purpose of this milestone's task is 'Testslavemaven2'. The git repository link for the same is: "https://github.com/mahasanath/Firsttask.git". This is a simple java project/application which was used for the first milestone. We are continuing the pipeline using the same project.

* Another instance has been run that will act as a remote server for deployment. It is running at "ec2-54-148-105-208.us-west-2.compute.amazonaws.com" (lets say AWS2). It's an ubuntu instance.
So AWS1 will be deploying the build application to AWS2 and itself.

* Some initial setup is required for the purpose of the tasks. They are as follows:

> Open the config file in home(local machine) and enter the following. ec2 and ec4 are obtained as shown in the next step. We have just copied my-key-pair.pem to two different files.
  
 ```bash
vim ~/.ssh/config
```
    Host ec2
        User ubuntu
        HostName ec2-54-148-145-59.us-west-2.compute.amazonaws.com
        IdentityFile ~/.ssh/ec2.pem

    Host ec4
        User ubuntu
        HostName ec2-54-148-105-208.us-west-2.compute.amazonaws.com
        IdentityFile ~/.ssh/ec4.pem


> Transfer the .pem file for configuration of ssh to AWS1. The key used is my-key-pair.pem. In AWS1, copy the key to two different keys ec2 and ec4 (for AWS1 and AWS2). We did the same for local machine (created two keys ec2 and ec4)
 ```bash
chmod 400 my-key-pair.pem
scp -i my-key-pair.pem ~/Downloads/my-key-pair.pem ubuntu@ec2-54-148-145-59.us-west-2.compute.amazonaws.com:./
mv my-key-pair.pem ec2.pem
mv ec2.pem ~/.ssh/
```
Do the same for ec4.pem

> In AWS1, in config file, enter the following
   Host ec4
        User ubuntu
        HostName ec2-54-148-105-208.us-west-2.compute.amazonaws.com
        IdentityFile ~/.ssh/ec4.pem

The above steps will let us ssh into machines AWS1 and AWS2 from local machine and AWS2 from AWS1 using the commands

  ```bash
ssh ec2
ssh ec4
```

####Tasks explained
-------------------

The task setup and abilities have been demostrated in the screenshots below:

#####1. The ability to configure a deployment environment automatically, using a configuration management tool, such as ansible, or configured using vagrant/docker.

> To configure a deployment environment automatically, we used 'ansible'. We configured the servers permanently for deployment. Install ansible:

```bash
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
```

  
> Go to the ansible folder and create a file called hosts. Place the following inside it. This will configure the deployment server. canary1 and canary2 are the two servers.

[canary1]
ec2-54-148-145-59.us-west-2.compute.amazonaws.com       ansible_ssh_private_key_file=/home/ubuntu/.ssh/ec2.pem    ansible_ssh_user=ubuntu

[canary2]
ec2-54-148-105-208.us-west-2.compute.amazonaws.com      ansible_ssh_private_key_file=/home/ubuntu/.ssh/ec4.pem    ansible_ssh_user=ubuntu

Make sure you have permissions to ec4 and ec2 pem files (can be assigned using 'sudo chmod 600 <file_name>. 

The command 'ansible all -m ping' will show the connection. 

 ![T1_ansible](https://github.com/mahasanath/Milestone3/blob/master/T1_ansible.png) 

 ![ansible_individual](https://github.com/mahasanath/Milestone3/blob/master/ansible_individual.png)


#####2. The ability to deploy a self-contained/built application to the deployment environment. That is, this action should occur after a build step in your pipeline.

> We have used ansible to handle the deployment. The build files from 'Build' step are stored in AWS1 at location "/var/lib/jenkins/workspace/testslavemaven2/target". I have created a script called 'runBuild.sh' that monitors the Build files of Jenkins and every 10 seconds transfers the build files to the deployed server and run them (deploy). 

When a change is committed to Github, it builds the application again and ansible takes care of the task to regularly deploy build application to the deployed servers (AWS2 and AWS1). 

There is another file called 'deployScript.sh' that goes to the location where build files are copied in the remote deploy server and run them. It is a java application so it runs the application with 'java <App name>'. (Please see jdk should be present in the deployed and deploying server). As ours is not a web application, the file on run produces output in the console. The address can be seen of the server where the application has been deployed.

The file can be run as 'runBuild.sh' It will run until it is stopped. And it will detect changes in the build files and keep deploying. This can be checked on the fly. Run the deploy server and make changes in the application, build and see the changes.

The screenshots below show the task:

 ![T2_deploy1](https://github.com/mahasanath/Milestone3/blob/master/T2_deployment1.png)
 ![T2_deploy2](https://github.com/mahasanath/Milestone3/blob/master/T2_deploy.png)

The build files are in 'deployed folder in the home location' in remote server as seen here.


#####3. The deployment must occur on an actual remote machine/VM (e.g. AWS, droplet, VCL), and not a local VM.
> There are two instances running as mentioned below and deployment is taking place in both the instances and both are AWS instances (one being remote). 

![T3_instances_run](https://github.com/mahasanath/Milestone3/blob/master/T3_instances_running.png)
![T3_instances_running](https://github.com/mahasanath/Milestone3/blob/master/instances_running.png)


#####4. The ability to perform a canary release.
>  The same file 'runBuild.sh' has the canary release code.
  We are running the deploy server in a loop as mentioned before. It has 'if-else' that keeps switching between the two servers where deployment is taking place (self-AWS1 and remote-AWS2). And releases are made alternatively. The program checks for previous deployed server and next time runs the other server and vice versa.

```bash
 ansible canary2 -m copy -a "src=/var/lib/jenkins/workspace/testslavemaven2/target dest=/home/ubuntu/deployed/"
  ansible canary2 -m copy -a "src=/home/ubuntu/deployScript.sh dest=/home/ubuntu/"
  ansible canary2 -m shell -a "cd /home/ubuntu/; sh deployScript.sh"

```


#####5. The ability to monitor the deployed application for alerts/failures (using at least 2 metrics).
> We have used two metrics: mpstat and free. And also 'enabled smart alerts' and 'silenced all the alerts' using nagios.

```bash
ansible canary1 -m nagios -a "action=silence_nagios" --sudo
ansible canary1 -m nagios -a "action=enable_alerts service=smart host=ec2-54-148-105-208.us-west-2.compute.amazonaws.com" --sudo
  ```     

![T5](https://github.com/mahasanath/Milestone3/blob/master/T5.png)
![T5_silence alerts](https://github.com/mahasanath/Milestone3/blob/master/T5_silence.png)


**REFERENCES
------------
1. http://pydoc.net/Python/ansible/1.8.2/ansible.modules.extras.monitoring.nagios/
2. http://docs.ansible.com/playbooks_intro.html#handlers-running-operations-on-change

 
