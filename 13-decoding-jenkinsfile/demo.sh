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
# BLOCK 1 — The minimal Jenkinsfile skeleton
#
# Every Jenkinsfile — no matter how complex — is just this structure:
#   pipeline → agent → stages → stage → steps
#
# Start here. Once you can read this, everything else is just adding blocks.
# ===========================================================================

cat > Jenkinsfile.minimal << 'EOF'
pipeline {
    agent any

    stages {
        stage("Build") {
            steps {
                sh "echo Building..."
            }
        }
        stage("Test") {
            steps {
                sh "echo Testing..."
            }
        }
        stage("Deploy") {
            steps {
                sh "echo Deploying..."
            }
        }
    }
}
EOF

echo ""
echo "--- BLOCK 1: minimal Jenkinsfile skeleton ---"
cat Jenkinsfile.minimal


# ===========================================================================
# BLOCK 2 — The full annotated Jenkinsfile
#
# Now we add: environment variables, conditional execution (when),
# per-stage post blocks, and a global post block.
# The skeleton is still the same — these are just additions.
# ===========================================================================

cat > Jenkinsfile << 'EOF'
pipeline {

    agent any   // "any" = use any available Jenkins worker node

    // environment: define variables once, use them in any stage as env.VARNAME
    environment {
        APP_NAME = "my-app"
    }

    stages {

        stage("Checkout") {
            steps {
                checkout scm                          // checkout scm = clone your git repo
                echo "Branch: ${env.BRANCH_NAME}"    // env.BRANCH_NAME is set by Jenkins
            }
        }

        stage("Install") {
            steps {
                sh "pip install -r requirements.txt"  // sh "" = run a shell command
            }
        }

        stage("Test") {
            steps {
                sh "pytest test_app.py -v"
            }
            post {                                    // post runs after THIS stage
                failure {
                    echo "Tests FAILED — notify team"
                }
            }
        }

        stage("Deploy") {
            when {
                branch "main"    // conditional: skip this stage on feature branches
            }
            steps {
                echo "Deploying ${env.APP_NAME}..."
                sh "python app.py"
            }
        }
    }

    // Global post: runs after ALL stages regardless of outcome
    post {
        success { echo "Pipeline PASSED" }
        failure { echo "Pipeline FAILED — check logs" }
        always  { cleanWs() }   // cleanWs() = wipe workspace after every build
    }
}
EOF

echo ""
echo "--- BLOCK 2: full annotated Jenkinsfile ---"
cat Jenkinsfile


# ===========================================================================
# BLOCK 3 — Quick reference: Jenkinsfile vs YAML pipeline tools
# ===========================================================================

echo ""
echo "=== Jenkinsfile keyword reference ==="
echo ""
echo "pipeline {}      : root block — everything lives here"
echo "agent any        : run on any node (also: agent { docker 'python:3.12' })"
echo "environment {}   : key=value pairs, access as env.KEY in any stage"
echo "stage('name') {} : one logical phase — shows up as a column in the UI"
echo "steps {}         : commands inside a stage (sh, echo, checkout, etc.)"
echo "when {}          : gate — only run this stage if the condition is true"
echo "post {}          : hooks — always / success / failure / unstable"
echo "cleanWs()        : Jenkins built-in — wipes the workspace directory"
echo ""
echo "Groovy vs YAML:"
echo "  Jenkins        = Groovy DSL  (Jenkinsfile, no extension)"
echo "  GitHub Actions = YAML        (.github/workflows/*.yml)"
echo "  GitLab CI      = YAML        (.gitlab-ci.yml)"
