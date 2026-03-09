FROM jenkins/jenkins:lts-jdk17

# Skip the setup wizard — jump straight to a usable Jenkins
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Pre-install the Pipeline plugin and Stage View (the visual pipeline UI)
# This runs at build time so students don't wait for plugin downloads
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator:latest \
    pipeline-stage-view:latest

# Copy init scripts — these run once on first startup
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

USER jenkins
