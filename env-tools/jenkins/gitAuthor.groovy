def call() {
  shortCommit = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
  name = sh(returnStdout: true, script: "git --no-pager show -s --format='%an' ${shortCommit}").trim()
  return name
}