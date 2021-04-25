import jetbrains.buildServer.configs.kotlin.v10.toExtId
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

project {
    vcsRoot(DevRoot)

    subProject(Stable)
    subProject(Dev)

    subProjectsOrder = arrayListOf(
        RelativeId("Stable"),
        RelativeId("Dev"))
}

object DevRoot : GitVcsRoot({
    name = "Dev"
    url = "https://github.com/MoWerr/vhserver"
    branch = "refs/heads/dev"
    branchSpec = "+:refs/heads/(dev)\n" +
            "+:refs/heads/main"
    userForTags = "MoWer"
    authMethod = password {
        userName = "MoWerr"
        password = "credentialsJSON:c936cbbd-a1d6-4a1d-87c0-48f933779af3"
    }
})

object Stable : Project({
    name = "Stable"

    buildType(BuildStable)
})

object Dev : Project({
    name = "Dev"

    buildType(BuildDev)
    buildType(PromoteToStable)
})

open class BuildDockerImage(projectName: String, buildName: String, vcsRoot: VcsRoot, dockerPath: String) : BuildType({
    val id: String = "${projectName}_${buildName}";
    id (id.toExtId())

    name = buildName

    vcs {
        this.root(vcsRoot)
    }

    steps {
        dockerCommand {
            name = "Build image"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = dockerPath
            }
            param("dockerImage.platform", "linux")
        }

        dockerCommand {
            name = "Push image"
            commandType = push {
                namesAndTags = dockerPath
            }
        }
    }

    triggers {
        vcs {
        }
    }
})

object BuildStable : BuildDockerImage("Stable","Build", DslContext.settingsRoot, "mowerr/vhserver:latest")
object BuildDev : BuildDockerImage("Dev","Build", DevRoot, "mowerr/vhserver:dev")

object PromoteToStable : BuildType({
    name = "Promote to Stable"

    vcs {
        root(DevRoot)
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