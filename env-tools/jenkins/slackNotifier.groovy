#!/usr/bin/env groovy

def call(String buildResult, String committerName) {
  buildResult =  buildResult ?: 'SUCCESS'
  if ( buildResult == "SUCCESS" ) {
	slackSend color: "good", message: "Job: ${env.JOB_NAME} \nBuildNumber ${env.BUILD_NUMBER} was successful \nCommitter:${committerName} \nBuild:${env.BUILD_URL}"
  }
  else if( buildResult == "FAILURE" ) {
	slackSend color: "danger", message: "Job: ${env.JOB_NAME} \nBuildNumber ${env.BUILD_NUMBER} has failed the committer needs to fix me \nCommitter:${committerName} \nBuild:${env.BUILD_URL}"
  }
  else if( buildResult == "UNSTABLE" ) {
	slackSend color: "warning", message: "Job: ${env.JOB_NAME} \nBuildNumber ${env.BUILD_NUMBER} is unstable \nCommitter:${committerName} \nBuild:${env.BUILD_URL}"
  }
  else {
	slackSend color: "danger", message: "Job: ${env.JOB_NAME} \nBuildNumber ${env.BUILD_NUMBER} is in some wonky state, please look at me \nCommitter:${committerName} \nBuild:${env.BUILD_URL}"
  }
}