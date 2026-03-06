# frozen_string_literal: true

require "test_helper"

class HugoGitClientTest < ActiveSupport::TestCase
  # Subclass that captures git commands instead of executing them
  class RecordingGitClient < HugoGitClient
    attr_reader :commands_run

    def initialize(**args)
      super
      @commands_run = []
    end

    private

    def run_git(*cmd, env: {})
      @commands_run << cmd.join(" ")
      true
    end
  end

  setup do
    @tmp_dir = Dir.mktmpdir
    @repo_url = "git@github.com:user/blog.git"
    @deploy_key_path = "/tmp/test_deploy_key"
  end

  teardown do
    FileUtils.rm_rf(@tmp_dir)
  end

  context "#clone" do
    should "run git clone with SSH deploy key" do
      client = RecordingGitClient.new(repo_url: @repo_url, deploy_key_path: @deploy_key_path, work_dir: @tmp_dir)

      client.clone

      assert client.commands_run.any? { |c| c.include?("clone") && c.include?(@repo_url) }
    end
  end

  context "#commit_and_push" do
    should "run git add, commit, and push" do
      client = RecordingGitClient.new(repo_url: @repo_url, deploy_key_path: @deploy_key_path, work_dir: @tmp_dir)

      client.commit_and_push("Add post: my-article")

      assert client.commands_run.any? { |c| c.include?("add") }
      assert client.commands_run.any? { |c| c.include?("commit") && c.include?("Add post: my-article") }
      assert client.commands_run.any? { |c| c.include?("push") }
    end
  end
end
