// Create a pre-built pipeline job so the demo is ready to run immediately
import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.getInstanceOrNull()
if (!jenkins) return

def pipelineScript = '''
pipeline {
    agent any

    environment {
        APP_NAME = "autoops-demo-app"
    }

    stages {
        stage("Build") {
            steps {
                echo "Building ${env.APP_NAME}..."
                sh "echo 'Compiling source files...'"
                sh "echo 'Build artifact created: app-1.0.0.jar'"
            }
        }
        stage("Test") {
            steps {
                echo "Running test suite..."
                sh "echo 'Unit tests:        42 passed, 0 failed'"
                sh "echo 'Integration tests: 12 passed, 0 failed'"
            }
            post {
                failure {
                    echo "Tests FAILED — notifying team"
                }
            }
        }
        stage("Deploy") {
            when {
                expression { true }
            }
            steps {
                echo "Deploying ${env.APP_NAME} to staging..."
                sh "echo 'Deploy complete. URL: https://staging.example.com'"
            }
        }
    }

    post {
        success { echo "Pipeline PASSED — all stages green" }
        failure { echo "Pipeline FAILED — check stage logs above" }
    }
}
'''

if (!jenkins.getItem("autoops-demo")) {
    def job = jenkins.createProject(WorkflowJob, "autoops-demo")
    job.setDefinition(new CpsFlowDefinition(pipelineScript, true))
    job.save()
    println "Created pipeline job: autoops-demo"
}

jenkins.save()
