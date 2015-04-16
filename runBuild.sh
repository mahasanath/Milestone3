canary="canary2"
while true
do
#ansible canary2 -m shell -a "sudo latencytop"
if [ "$canary" = canary1 ]
then
  ansible canary2 -m copy -a "src=/var/lib/jenkins/workspace/testslavemaven2/target dest=/home/ubuntu/deployed/"
  ansible canary2 -m copy -a "src=/home/ubuntu/deployScript.sh dest=/home/ubuntu/"
  ansible canary2 -m shell -a "cd /home/ubuntu/; sh deployScript.sh"
  echo "silence all alerts" 
  ansible canary1 -m nagios -a "action=silence_nagios" --sudo
  echo "Utilization of CPU in individual server and memory usage"
  ansible canary2 -m shell -a "mpstat; free"
  echo "Deployment Success on Server 1"
  sleep 10
  canary="canary2"  
else
   ansible canary1 -m copy -a "src=/var/lib/jenkins/workspace/testslavemaven2/target dest=/home/ubuntu/deployed/"
  ansible canary1 -m copy -a "src=/home/ubuntu/deployScript.sh dest=/home/ubuntu/"
  ansible canary1 -m shell -a "cd /home/ubuntu/; sh deployScript.sh"
  echo "enable smart disk alerts"
  ansible canary1 -m nagios -a "action=enable_alerts service=smart host=ec2-54-148-105-208.us-west-2.compute.amazonaws.com" --sudo 
 # ansible canary2 -m nagios -a "action=enable_alerts service=smart host=ec2-54-148-145-59.us-west-2.compute.amazonaws.com" --sudo 
 # ansible canary1 -m nagios -a "action=silence_nagios" --sudo
  echo "Utilization of CPU in individual server and memory usage for server 2"
  ansible canary2 -m shell -a "mpstat; free"
  echo "Deployment Success on server 2"
  sleep 10
  canary="canary1"
fi
done 
