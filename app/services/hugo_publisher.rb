# frozen_string_literal: true

class HugoPublisher
  class NotConfiguredError < StandardError
    def initialize
      super("Hugo publishing is not configured. Set HUGO_REPO_SSH_URL and HUGO_DEPLOY_KEY_PATH environment variables.")
    end
  end

  def initialize(article)
    @article = article
  end

  def call
    raise NotConfiguredError unless configured?

    tmp_dir = Dir.mktmpdir("hugo-publish")

    begin
      git_client = HugoGitClient.new(repo_url: repo_url, deploy_key_path: deploy_key_path, work_dir: tmp_dir)
      git_client.clone

      formatter = HugoPostFormatter.new(@article)
      post_dir = File.join(git_client.repo_path, "content", "posts", @article.slug)
      FileUtils.mkdir_p(post_dir)

      File.write(File.join(post_dir, "index.md"), formatter.format)
      copy_images(formatter.image_references, post_dir)

      git_client.commit_and_push("Add post: #{@article.slug}")
    ensure
      FileUtils.rm_rf(tmp_dir)
    end
  end

  private

  def configured?
    repo_url.present? && deploy_key_path.present?
  end

  def repo_url
    @repo_url ||= ENV.fetch("HUGO_REPO_SSH_URL", nil)
  end

  def deploy_key_path
    @deploy_key_path ||= ENV.fetch("HUGO_DEPLOY_KEY_PATH", nil)
  end

  def copy_images(image_references, post_dir)
    image_references.each do |ref|
      blob = ActiveStorage::Blob.find_signed(ref[:signed_id])
      next unless blob

      blob.open do |tempfile|
        FileUtils.cp(tempfile.path, File.join(post_dir, ref[:filename]))
      end
    rescue => e
      Rails.logger.warn("Hugo publish: failed to copy image #{ref[:filename]}: #{e.message}")
    end
  end
end
