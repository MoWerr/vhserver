import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.merge
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.VcsTrigger
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.vcs
import jetbrains.buildServer.configs.kotlin.v2019_2.vcs.GitVcsRoot

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2020.2"

object DevRoot : GitVcsRoot({
    name = "Dev"
    url = "https://github.com/MoWerr/vhserver"
    branch = "refs/heads/dev"
    userForTags = "MoWer"
    authMethod = password {
        userName = "MoWerr"
        password = "credentialsJSON:c936cbbd-a1d6-4a1d-87c0-48f933779af3"
    }
})

project {
    vcsRoot(DevRoot)

    subProject(Stable)
    subProject(Dev)
}

object Stable : Project({
    name = "Stable"

    buildType(Build)
})

object Build : BuildType({
    name = "Build"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        dockerCommand {
            name = "Build image"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = "mowerr/vhserver:latest"
            }
            param("dockerImage.platform", "linux")
        }

        dockerCommand {
            name = "Push image"
            commandType = push {
                namesAndTags = "mowerr/vhserver:latest"
            }
        }
    }

    triggers {
        vcs {
        }
    }
})

object Dev : Project({
    name = "Dev"

    // buildType(PromoteToStable)
    buildType(BuildDev)
})

object BuildDev : BuildType({
    name = "Build"

    vcs {
        root(DevRoot)
    }

    steps {
        dockerCommand {
            name = "Build image"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = "mowerr/vhserver:dev"
            }
            param("dockerImage.platform", "linux")
        }

        dockerCommand {
            name = "Push Image"
            commandType = push {
                namesAndTags = "mowerr/vhserver:dev"
            }
        }
    }

    triggers {
        vcs {
        }
    }
})
/*
object PromoteToStable : BuildType({
    name = "Promote"

    vcs {
        root(HttpsGithubComMoWerrVhserverRefsHeadsDev1)
    }

    triggers {
        vcs {
            enabled = false
        }
    }

    features {
        merge {
            branchFilter = "+:<default>"
            destinationBranch = "main"
        }
    }

    dependencies {
        snapshot(BuildDev) {
            runOnSameAgent = true
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
    }
})
*/