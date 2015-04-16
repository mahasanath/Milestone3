### Devops - Deployment Milestone    


##### Mahalaxmi Sanathkumar (smahala@ncsu.edu)  & Parul Upadhyaya (pupadhy2@ncsu.edu)


#### Pre-steps to setup deployment server on an Ubuntu server.
--------------------------------------------------------------

* In the Milestone 1, we have already build a pipeline that supports application builds.   The build can be triggered either by 'Build Now' option in jenkins master->jobs GUI which is running on the server 'ec2-54-148-145-59.us-west-2.compute.amazonaws.com'(lets say AWS1) (as per our 
setup in Milestone1 or by SCM change. With each git push, application build is triggered. (Please see the amazon instance IP has changed as we have restarted the instance).

* The project that has been setup for the purpose of this milestone's task is 'Testslavemaven2'. The git repository link for the same is: "https://github.com/mahasanath/Firsttask.git". This is a simple java project/application which was used for the first milestone. We are continuing the pipeline using the same project.

* Another instance has been run that will act as a remote server foe deployment. It is running at "ec2-54-148-105-208.us-west-2.compute.amazonaws.com" (lets say AWS2). It's an ubuntu instance.
So AWS1 will be deploying the build application to AWS2 and itself.

* Some initial setup is required for the purpose of the tasks. They are as follows 

> Transfer the .pem files for configuration of ssh to AWS1. The key used is my-key-pair.pem
  
 ```bash
mv my-key-pair.pem ec2.pem
mv ec2.pem ~/.ssh/
```
Do the same for ec4.pem

> Open the config file and enter the following
  
  ```bash
vim ~/.ssh/config
```

	

> Open /etc/apache2/sites-available/jenkins.conf and add the following to enable proxying requests.  


          <VirtualHost *:80>
          	ServerName HOSTNAME
          	ProxyRequests Off
          	<Proxy *>
          		Order deny,allow
          		Allow from all
          	</Proxy>
          	ProxyPreserveHost on
          	ProxyPass / http://localhost:8080/
          </VirtualHost>
      

> Enable it

  ```bash
  sudo a2ensite jenkins  
  sudo service apache2 reload
```
> Installing dependencies for our build server : Java / Maven / Git
  
  ```bash
  sudo add-apt-repository ppa:webupd8team/java  
  sudo apt-get update  
  sudo apt-get install oracle-java7-installer maven git-core
```
Once this is setup, configured Jenkins master using its GUI. The config.xml for the Jenkins master and the project item are attched in the "configuration_files_consoleoutput" folder of github.   

####Tasks explained
-------------------

In Jenkins master , two items have been configured to use the same git project repository ( testslavemaven and workspacewipeout , as seen in the screen shots). This has been done to show how the push in one git repositry would trigger 2 builds and how they get delegated by the master to the 2 slaves that we would be creating. Each of these slaves have been configured to have just one executor each( atmost one build in each to effeciently demonstrate the task). Our setup of the build server delegates all build requests from master to the idle slaves. The status of the builds can be viewed in the Jenkins master server itself.     

The task setup and abilities havebe en demostrated in the screenshos below:   

#####1. The ability to trigger a build in response to a git commit via a git hook.

> To configure Github to trigger a build in response to a push made by the user,
  go to the settings page of the project. Select the "jenkins (git plugin)" from the
  "Webhooks and services" tab. Configure the plugin to set the jenkins URL to the
  Jenkins master. In our case "http://ec2-54-148-38-238.us-west-2.compute.amazonaws.com/"
  and select the checkbox "Active". This configuration can be seen below-

![GitHook_configuration](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/task1_githook.JPG)
  
> In jenkins Master server, add the following to the configuration,  

  ![scm_config](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/scm_change_config.JPG)  
  
> To demonstrate this task, the screenshot below is of the **console output**
  that reads the following line "Started by an SCM change" (which means it was triggered by a 
  git push)

![SCM change](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/buildbyscm_task1.JPG)

> The "Jenkins (git plugin)" in github further affirms that the last delivery was successful.

![Success message](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/lastsuccess_task1.png)


#####2. The ability to setup dependencies for the project and restore to a clean state.
>  The screenshots below demonstrate the task. When the project is first loaded, the dependencies are
   installed, target files are created and the project is built.

 ![Build is successful](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/nuildsuccess.JPG)

> For restoring to a clean state:  
  mvn clean install   
  

#####3. The ability to execute a build script (e.g., shell, maven)
> The screenshots below demonstrate the task. It installs all dependencies using Maven and is pom.xml to load all dependencies needed to build the project. It essentially executesa Maven script , that is the pom.xml file from the project directory. It is configured in the build setup in Jenkins as shown below.   

![buildsetupjenkins](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/pom.xml_task3.JPG)  
> Succesful build by downloading dependencies using pom.xml   

![BUILD SUCCESS](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/buildsuccess.png)

The console output shown below demostrates how the target folder containing previous buids snapshots, classes, generated files and build tasks are removed before building the project. Thus explains that one build does not affect the other. Achieved using "mvn clean install."   

![clean](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/remove_targets_clean.JPG)

#####4. The ability to run a build on multiple nodes (e.g. jenkins slaves, go agents, or a spawned droplet/AWS.).
>  To create and configure slave nodes (in the Jenkins master) that would be ready to accept the tasks delegated
   by the master. The following steps are for setup:
 
- Create an amazon instance (Ubuntu- same as that of the master) for the slave (Jenkins Slave)
- Install ssh server (To connect to the slaves via SSH)
- Create a slave user and generate rsa public and private keys for it.
- Copy the private key to Jenkins (under manage credentials using "Ssh slaves plugin") for that particular slave.
- Installed all the required tools for building the target project(Maven, Jenkins and Git).
```bash
The commands to setup the ssh serve using online resources:

1. Installing required dependencies:  
   sudo add-apt-repository ppa:webupd8team/java  
   sudo apt-get update  
   sudo apt-get install oracle-java7-installer maven git-core
   
2. Creating slave user  
   sudo adduser theslave

3. sudo apt-get install openssh-server  
   sudo vim /etc/ssh/sshd_config

4. Appending to the end of file:  
   AllowUsers theslave

5. Restarting ssh server:  
   restart ssh server  
   sudo restart ssh

6. Switch user:  
   sudo su theslave

7. Creating ssh directory and giving permissions:  
   mkdir ~/.ssh  
   chmod 700 ~/.ssh

8. Run the ssh-keygen command:  
   ssh-keygen -t rsa

9. Copy the contents of id_rsa public key.    
   cd .ssh  
   "cat id_rsa.pub >> authorized_keys"

10.Copy the id_rsa private key into jenkins manage credentials for "theslave" 
  ```
  
> In our project, we have created two slaves 'theslave' and 'jenkins' to demonstrate 
  the ability to run build on multiple nodes. For the purpose of this task, we have 
  changed the number of executors to 0. So that the incoming build request will be directly
  delegated by the master to the online slaves. This is as shown below:

  ![Number of executors in Master](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/master_0.JPG) 
  
> Before jenkins master delegates job to slaves, the build queue have two items as shown below (because the items 'testslavemaven' and 'workspacewipeout' have the same github project:
  ![Trigger tasks](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/trigger_task4.png)   
  
  
> After the jobs are delegated to the two slaves "theslave" and "jenkins", the build executor status depicts that both the slaves are executing build.   

  ![Multiple slaves](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/multipleslaves_task4.png)

    List of configured nodes, including master and 2 slaves viz. 'jenkins' and 'theslave'

  ![list allnodes](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/available_nodes.JPG)  
      
> The slave "jenkins" executed one job as shown below:   

![Jenkins slave working](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/task1_consolescm.JPG)  


> The slave "theslave" executed another job as shown below:
![theslave working](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/theslave_console.JPG)

> SSH authentication of 'theslave'  

![slaves authenticated](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/theslave_auth.JPG)

> The slaves are idle (but online) when they dont have any tasks to execute.    

![Idle slaves](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/slavesidle.JPG)

> The screeshot below shows that the slaveis connected and online.   

![Online slaves](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/after_theslavelaunched.JPG)

#####5. The ability to retrieve the status of the build via http.
> The status of the build can be retrieved by using the following command:  

```bash
curl -i -H "Accept: application/json" -H "Content-Type: application/json" http://ec2-54-148-38-238.us-west-2.compute.amazonaws.com/job/testslavemaven/lastBuild/api/json
  ```     
  
  
![Status response](https://github.com/mahasanath/Firsttask/blob/master/milestone1_devops_screenshots/task5.JPG)

> The configuration file (config.xml) for the Jenkins master and the job configuration file
  have been uploaded on the github.

