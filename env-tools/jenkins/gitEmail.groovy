def call() {
  shortCommit = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
  email=sh(returnStdout: true, script: "git --no-pager show -s --format='%ae' ${shortCommit}").trim()
  return email
}