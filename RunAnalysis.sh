#!/bin/bash

############## USAGE ########################
#./RunAnalysis.sh --user $USER --pass $PASSWORD --cdx-url $CDX_URL --project-id $PROJECT_ID
#############################################

user=""
web_url=""
pass=""
project_id=0
install_jq=false

prepId=""
prepFinished=false
analysisId=""
anaylsisJobId=""
analysisFinished=false
retryForPrep=100
retryForAnalysis=300
sleep=10

function downloadJq()
{
	if [ "$install_jq" == "true" ]
	then 
		curl -sLo ./myJq https://stedolan.github.io/jq/download/linux64/jq
		chmod +x ./myJq
	fi	
}

function verifyInput()
{
	if [ -z "$user" ]
	then
		echo "no user entered .. exiting"
		exit 1
	fi
	
	if [ -z "$web_url" ]
	then
		echo "no web_url entered .. exiting"
		exit 1
	fi	

	if [ -z "$pass" ]
	then
		echo "no pass entered .. exiting"
		exit 1
	fi	
	
	if [ -z "$project_id" ]
	then
		echo "no project_id entered .. exiting"
		exit 1
	fi	
}
function prepAnalysis()
{
		response=$(curl -sS -X 'POST' --user ${user}:${pass} "$web_url/codedx/api/analysis-prep" -H 'accept: application/json' -H 'Content-Type: application/json' -d "{\"projectId\":$project_id}")
        prepId=$(echo "${response}" | ./myJq --raw-output '.prepId')
		if [ -z "$prepId" ]
		then
			echo "no PrepId found .. exiting"
			exit 1
		fi
}

function waitForPrep()
{
		#we check if prep is finished, then wait for a few seconds and try again. We try uptil the retry numbers specified.
		retryCount=0
		while [ retryCount != retryForPrep ]
		do			
			response=$(curl -sS -X 'GET' --user ${user}:${pass} "$web_url/codedx/api/analysis-prep/$prepId" -H "accept: application/json")
			verificationErrors=$(echo "${response}" | ./myJq --raw-output '.verificationErrors')
			if [ "$verificationErrors" == "[]" ]; then
				prepFinished=true
				break
			else
				retryCount=$[$retryCount +1]				
				sleep $sleep
			fi			
		done
		
		if [ "$prepFinished" == "false" ]
		then 
			echo "Unable to prepare after $retryForPrep tries... exiting"
			exit 1
		else 
			echo "Preparation done, starting analysis"
		fi
}

function triggerAnalysis()
{
        #if no errors were found, let's trigger the analysis!
        response=$(curl -sS -X 'POST' --user ${user}:${pass} "$web_url/codedx/api/analysis-prep/$prepId/analyze" -H 'accept: */*' -d "")
        analysisId=$(echo "${response}" | ./myJq --raw-output '.analysisId')
        anaylsisJobId=$(echo "${response}" | ./myJq --raw-output '.jobId')        	
}

function monitorAanalysis()
{
		retryCount=0
		finalStatus=""
		while [ retryCount != retryForAnalysis ]
		do			
			response=$(curl -sS -X GET --user ${user}:${pass} "$web_url/codedx/api/jobs/$anaylsisJobId")
			status=$(echo "${response}" | ./myJq --raw-output '.status')
			finalStatus=$status
			if [ "$status" == "failed" ]; then
				analysisFinished=false
				break
			fi
			if [ "$status" == "completed" ]; then
				analysisFinished=true
				break
			else
				echo "waiting for analysis to finish. Total retries done: $retryCount"
				retryCount=$[$retryCount +1]				
				sleep $sleep #wait
			fi			
		done
		
		if [ "$analysisFinished" == "false" ]
		then 
			echo "Unable to finish the analysis... exiting"
			echo "last status was: $finalStatus"
			exit 1
		else 
			echo "Analysis Finished"
		fi		
}

################ MAIN ##################

# Get inputs
# As long as there is at least one more argument, keep looping
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # component name to ignore arg passed as space
        --user)
        shift
        user="$1"
        ;;
        # access token arg passed as space
        --pass)
        shift
        pass="$1"
        ;;
        # hub url arg passed as space
        --cdx-url)
        shift
        web_url="$1"
        ;;
		# hub url arg passed as space
        --project-id)
        shift
        project_id="$1"
        ;;
	--install-jq)
	install_jq="$1"
	;;
        *)
        # Do whatever you want with extra options
        echo "Unknown option '$key'"
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

# Start
verifyInput
downloadJq
prepAnalysis
waitForPrep
triggerAnalysis
monitorAanalysis

##############################################
