// Disable authentication and CSRF for the demo — never do this in production
import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer

def instance = Jenkins.getInstance()
instance.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
instance.setAuthorizationStrategy(new AuthorizationStrategy.Unsecured())

// Disable CSRF protection so the REST API works without a crumb token
instance.setCrumbIssuer(null)

instance.save()
println "Security: unsecured, CSRF disabled (demo mode)"
