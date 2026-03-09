#!/bin/bash
# CompTIA AutoOps+ | Decoding the Jenkinsfile
# Exam Objective 3.3 — Pipeline definition: Jenkinsfile
#
# Jenkins uses a Groovy-based DSL (not YAML). The Jenkinsfile lives in the
# root of your repo and Jenkins reads it to know how to build your project.


# ===========================================================================
# BLOCK 0 — Setup
# ===========================================================================

rm -rf jenkinsfile-demo
mkdir jenkinsfile-demo
cd jenkinsfile-demo

cat > app.py << 'EOF'
def greet():
    print("Hello from Jenkins build!")

greet()
EOF

cat > test_app.py << 'EOF'
from app import greet

def test_greet(capsys):
    greet()
    out = capsys.readouterr().out
    assert "Hello" in out
EOF

echo "Files ready."


# ===========================================================================
# BLOCK 1 — A simple declarative Jenkinsfile
#
# Declarative syntax (the modern way) uses a pipeline {} block.
# Every Jenkinsfile has the same skeleton:
#   pipeline → agent → stages → stage → steps
# ===========================================================================

cat > Jenkinsfile << 'EOF'
// Declarative Pipeline — the modern Jenkins syntax
pipeline {

    // agent: where does this pipeline run?
    // "any" means Jenkins picks any available worker node
    agent any

    // environment: variables available to every stage
    environment {
        APP_NAME = "my-app"
        PYTHON_VERSION = "3.12"
    }

    stages {

        // Stage 1: get the code
        stage("Checkout") {
            steps {
                checkout scm   // scm = source control manager (your git repo)
                echo "Checked out branch: ${env.BRANCH_NAME}"
            }
        }

        // Stage 2: install dependencies
        stage("Install") {
            steps {
                sh "pip install -r requirements.txt"
            }
        }

        // Stage 3: run tests
        stage("Test") {
            steps {
                sh "pytest test_app.py -v"
            }
            // post: what to do AFTER this stage based on outcome
            post {
                always {
                    echo "Tests finished — archiving results"
                    archiveArtifacts artifacts: "*.log", allowEmptyArchive: true
                }
                failure {
                    echo "Tests FAILED — sending notification"
                    // mail to: "team@example.com", subject: "Build failed"
                }
            }
        }

        // Stage 4: only deploy if we are on the main branch
        stage("Deploy") {
            when {
                branch "main"   // conditional execution — skipped on feature branches
            }
            steps {
                echo "Deploying ${APP_NAME} to staging..."
                sh "python app.py"
            }
        }
    }

    // Global post block — runs after ALL stages
    post {
        success {
            echo "Pipeline PASSED — build is green"
        }
        failure {
            echo "Pipeline FAILED — check the logs above"
        }
        always {
            echo "Pipeline complete. Cleaning workspace."
            cleanWs()   // wipe the workspace after every build
        }
    }
}
EOF

echo ""
echo "--- BLOCK 1: the full Jenkinsfile ---"
cat Jenkinsfile


# ===========================================================================
# BLOCK 2 — Key Jenkinsfile concepts explained
# ===========================================================================

echo ""
echo "=== Jenkinsfile anatomy ==="
echo ""
echo "pipeline {}     : the root block — everything lives inside"
echo "agent any       : run on any Jenkins node (or specify docker, label, etc.)"
echo "environment {}  : define env vars accessible in all stages as env.VAR_NAME"
echo "stages {}       : container for all your stage blocks"
echo "stage('name') {}: one logical phase (Checkout, Build, Test, Deploy)"
echo "steps {}        : the actual shell commands or built-in Jenkins steps"
echo "when {}         : conditional — only run this stage if condition is true"
echo "post {}         : run after stage or pipeline (always/success/failure/unstable)"
echo ""
echo "Groovy vs YAML:"
echo "  Jenkins  = Groovy DSL  (.Jenkinsfile, no .yml)"
echo "  GitHub Actions = YAML  (.github/workflows/*.yml)"
echo "  GitLab CI      = YAML  (.gitlab-ci.yml)"
