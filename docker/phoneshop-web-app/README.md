
## Devops-fully-automated-Docker-Image-deployment
Fully automated and secured Docker dployment pipeline

Testing teh webhook.....

## CICD Infra setup
1) ###### GitHub setup
    Fork GitHub Repository by using the existing repo "effulgencetech-nodejs-docker-repo" (https://github.com/Michaelgwei86/effulgencetech-nodejs-repo.git )     
    - Go to GitHub (github.com)
    - Login to your GitHub Account
    - **Fork repository "effulgencetech-nodejs-docker-repo" (https://github.com/Michaelgwei86/effulgencetech-nodejs-repo.git) & name it "effulgencetech-nodejs-repo.git"**
    - Clone your newly created repo to your local

2) ###### Jenkins
    - Create an **Amazon Linux 2 VM** instance and call it "Jenkins"
    - Instance type: t2.large
    - Security Group (Open): 8080 and 22 to 0.0.0.0/0
    - Key pair: Select or create a new keypair
    - **Attach Jenkins server with IAM role having "AdministratorAccess"**
    - Launch Instance
    - After launching this Jenkins server, attach a tag as **Key=Application, value=jenkins**
    - SSH into the instance and Run the following commands in the **jenkins-install.sh** file

3) ###### Slack 
    - **Join the slack channel https://devopswithmike.slack.com/archives/C0590M8QZ97**
    - **Join into the channel "#effulgencetech-devops-channel"**

### Jenkins setup
1) #### Access Jenkins
    Copy your Jenkins Public IP Address and paste on the browser = **ExternalIP:8080**
    - Login to your Jenkins instance using your Shell (GitBash or your Mac Terminal)
    - Copy the Path from the Jenkins UI to get the Administrator Password
        - Run: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
        - Copy the password and login to Jenkins
    - Plugins: Choose Install Suggested Plugings 
    - Provide 
        - Username: **admin**
        - Password: **admin**
        - Name and Email can also be admin. You can use `admin` all, as its a poc.
    - Continue and Start using Jenkins

2)  #### Pipeline creation
    - Click on **New Item**
    - Enter an item name: **effulgencetech-nodejs-docker-repo** & select the category as **Pipeline**
    - Now scroll-down and in the Pipeline section --> Definition --> Select Pipeline script from SCM
    - SCM: **Git**
    - Repositories
        - Repository URL: FILL YOUR OWN REPO URL (that we created by importing in the first step)
        - Branch Specifier (blank for 'any'): */main
        - Script Path: Jenkinsfile
    - Save

3)  #### Plugin installations:
    - Click on "Manage Jenkins"
    - Click on "Plugin Manager"
    - Click "Available"
    - Search and Install the following Plugings "Install Without Restart"        
        - **Slack Notification**

4)  #### Credentials setup(Slack):
    - Click on Manage Jenkins --> Manage Credentials --> Global credentials (unrestricted) --> Add Credentials
        1)  ###### Slack secret token (slack-token)
            - Kind: Secret text            
            - Secret: lXpiMy7yGJLm9V6OsMmdkKVS
            - ID: Slack-token
            - Description: Slack-token
            - Click on Create                

        2)  #### Configure system:
            - Click on Manage Jenkins --> Configure System

            1)  - Go to section Slack
                - Workspace: **devopswithmike** (if not working try with Team-subdomain devopswithmike)
                - Credentials: select the slack-token credentials (created above) from the drop-down    
        3)  ###### Docker hub authentication (DOCKERHUB_CREDENTIALS)
            - Kind: Username and Password            
            - Username: "Enter your dockerhub username"
            - Password: "Enter your password"
            - ID: "DOCKERHUB_CREDENTIALS"
            - Description: "DOCKERHUB_CREDENTIALS"
            - Click on Create 

### Performing continous integration with GitHub webhook

1) #### Add jenkins webhook to github
    - Access your repo **effulgencetech-nodejs-docker-repo** on github
    - Goto Settings --> Webhooks --> Click on Add webhook 
    - Payload URL: **http://REPLACE-JENKINS-SERVER-PUBLIC-IP:8080/github-webhook/**    (Note: The IP should be public as GitHub is outside of the AWS VPC where Jenkins server is hosted)
    - Click on Add webhook

2) #### Configure on the Jenkins side to pull based on the event
    - Access your jenkins server, pipeline **effulgencetech-nodejs-docker-repo**
    - Once pipeline is accessed --> Click on Configure --> In the General section --> **Select GitHub project checkbox** and fill your repo URL of the project effulgencetech-devops-fully-automated.
    - Scroll down --> In the Build Triggers section -->  **Select GitHub hook trigger for GITScm polling checkbox**

Once both the above steps are done click on Save.


## Finally observe the whole flow and understand the integrations :) 
# Happy learning from EffulgenceTech


# my demo docker app using a jenkins pip
/
//def COLOR_MAP = [
//    'SUCCESS': 'good', 
//    'FAILURE': 'danger',
//]

pipeline{

	agent any

	//rename the user name dainmusty with the username of your dockerhub repo
	environment {
		DOCKERHUB_CREDENTIALS=credentials('DOCKERHUB_CREDENTIALS')
		IMAGE_REPO_NAME = "dainmusty/effulgencetech-nodejs-img"
		CONTAINER_NAME= "effulgencetech-nodejs-cont-"
	}
	
//Downloading files into repo
	stages {
		stage('Git checkout') {
            		steps {
                		echo 'Cloning project codebase...'
                		git branch: 'main', url: 'https://github.com/dainmusty/Effulgence.git'
            		}
        	}
	
//Building and tagging our Docker image

		stage('Build-Image') {
			
			steps {
				//sh 'docker build -t dainmusty/effulgencetech-nodejs-image:$BUILD_NUMBER .'
				sh 'docker system prune -f'
                sh 'docker container prune -f'
				sh 'docker build -t $IMAGE_REPO_NAME:$BUILD_NUMBER .'
				sh 'docker images'
			}
		}
		
//Logging into Dockerhub
		stage('Login to Dockerhub') {

			steps {
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
			}
		}

//Building and tagging our Docker container
		stage('Build-Container') {

			steps {
				//sh 'docker run --name effulgencetech-node-cont-$BUILD_NUMBER -p 8082:8080 -d dainmusty/effulgencetech-nodejs-image:$BUILD_NUMBER'
				sh 'docker run --name $CONTAINER_NAME-$BUILD_NUMBER -p 8089:8080 -d $IMAGE_REPO_NAME:$BUILD_NUMBER'
				sh 'docker ps'
			}
		}

//Pushing the image to the docker

		stage('Push to Dockerhub') {
			//Pushing image to dockerhub
			steps {
				//sh 'docker push dainmusty/effulgencetech-nodejs-image:$BUILD_NUMBER'
				sh 'docker push $IMAGE_REPO_NAME:$BUILD_NUMBER'
			}
		}
        
	}

  //  post { 
       // always { 
         //   echo 'I will always say Hello again!'
      //      slackSend channel: '#developers', color: COLOR_MAP[currentBuild.currentResult], message: "*${currentBuild.currentResult}:*, Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
    //    }
  //  }

}

# Demo docker app using jenkins pip with dynamic port assignment (courtesy Patrick) - Limitation here is that, you have to continuously update the SG  with the changing port number

 
//def COLOR_MAP = [
//    'SUCCESS': 'good',
//    'FAILURE': 'danger',
//]
 
pipeline{
 
    agent any
 
    //rename the user name topg528 with the username of your dockerhub repo
    environment {
        DOCKERHUB_CREDENTIALS=credentials('DOCKERHUB_CREDENTIALS')
        IMAGE_REPO_NAME = "topg528/effulgencetech-nodejs-img"
        CONTAINER_NAME= "effulgencetech-nodejs-cont-"
    }
   
//Downloading files into repo
    stages {
        stage('Git checkout') {
                    steps {
                        echo 'Cloning project codebase...'
                        git branch: 'main', url: 'https://github.com/topGuru77/effulgencetech-nodejs-repo.git'
                    }
            }
   
//Building and tagging our Docker image
 
        stage('Build-Image') {
           
            steps {
                //sh 'docker build -t topg528/effulgencetech-nodejs-image:$BUILD_NUMBER .'
                sh 'docker build -t $IMAGE_REPO_NAME:$BUILD_NUMBER .'
                sh 'docker images'
            }
        }
       
//Logging into Dockerhub
        stage('Login to Dockerhub') {
 
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }
 
//Building and tagging our Docker container
stage('Build-Container') {
    steps {
        script {
            def port = sh(
                script: '''
                used_ports=$(ss -Htan | awk '{print $4}' | cut -d: -f2 | sort -n | uniq)
                free_port=$(comm -23 <(seq 8000 9000 | sort -n) <(echo "$used_ports") | shuf | head -n 1)
                echo $free_port
                ''',
                returnStdout: true
            ).trim()
           
            echo "Selected free port: ${port}"
 
            // Save port to environment variable if needed
            env.DYNAMIC_PORT = port
 
            // Run your Docker container with dynamic port  # Remember to update the security group to allow this port
            sh """
            docker run --name effulgencetech-nodejs-cont-${BUILD_NUMBER} -p $DYNAMIC_PORT:8080 -d $IMAGE_REPO_NAME:$BUILD_NUMBER
            """
        }
    }
}
 
 
//Pushing the image to the docker
 
        stage('Push to Dockerhub') {
            //Pushing image to dockerhub
            steps {
                //sh 'docker push topg528/effulgencetech-nodejs-image:$BUILD_NUMBER'
                sh 'docker push $IMAGE_REPO_NAME:$BUILD_NUMBER'
            }
        }
       
    }
 
  //  post {
       // always {
         //   echo 'I will always say Hello again!'
      //      slackSend channel: '#developers', color: COLOR_MAP[currentBuild.currentResult], message: "*${currentBuild.currentResult}:*, Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
    //    }
  //  }
 
}



# Docker image management - phone web app Express
# Run locally where you have your image files reside
1. docker buildx create --use

2. docker buildx build \
  --platform linux/amd64 \
  -t dainmusty/fonapp-nodejs:express \
  --push .


# Run this on your host server (ec2)

3. docker pull dainmusty/fonapp-nodejs:latest

4. docker run -d -p 3000:3000 dainmusty/fonapp-nodejs:latest
# if the port is already allocated, do the ff;
a. docker ps
b. docker rm -f a24fdae43d11
c. docker run -d -p 3000:3000 dainmusty/fonapp-nodejs:latest





 Refresher: Which Port Must Be Unique?
Type of Port	Must Be Unique?	Why
External (host)	✅ Yes	Because only 1 process can bind to a port on the host machine (your EC2)
Internal (container)	❌ No	Docker containers are isolated — multiple containers can use the same internal port


