# frozen_string_literal: true

class HugoGitClient
  attr_reader :repo_path

  def initialize(repo_url:, deploy_key_path:, work_dir:)
    @repo_url = repo_url
    @deploy_key_path = deploy_key_path
    @work_dir = work_dir
    @repo_path = File.join(work_dir, "repo")
  end

  def clone
    run_git("git", "clone", "--depth", "1", @repo_url, @repo_path,
      env: ssh_env)
  end

  def commit_and_push(message)
    run_git("git", "-C", @repo_path, "add", "-A")
    run_git("git", "-C", @repo_path, "commit", "-m", message)
    run_git("git", "-C", @repo_path, "push", "origin", "main",
      env: ssh_env)
  end

  private

  def ssh_env
    { "GIT_SSH_COMMAND" => "ssh -i #{@deploy_key_path} -o StrictHostKeyChecking=accept-new" }
  end

  def run_git(*cmd, env: {})
    system(env, *cmd, exception: true)
  end
end
