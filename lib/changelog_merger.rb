require "changelog_merger/version"

require_relative "changelog_merger/parser"

module ChangelogMerger
  # Your code goes here...
  class Merger
    def initialize
      @options = Parser.parse_options
    end

    def run_generator
      begin
        if @options[:run_wo_pr]
          generate_change_log
          execute_line("open #{@options[:output]}")
        else
          go_to_work_dir
          clone_repo_and_cd
          check_existing_changelog_file
          generate_pr_message
          generate_change_log
          add_commit_push
        end
      rescue
        execute_line('git push skywinder :add-change-log-file && git checkout master && git branch -D add-change-log-file')
      end
    end

    def check_existing_changelog_file
      if @options[:output] == 'CHANGELOG.md'
        if File.exist? @options[:output]
          puts "#{@options[:output]} found"
          @options[:chagelog_exists] = 'CHANGELOG.md'
          extension = File.extname(@options[:output])
          base = File.basename(@options[:output], extension)
          @options[:output] = base + '_AUTO' + extension
          puts "Change it to: #{@options[:output]}"
        end
      end

      if File.exist? 'HISTORY.md'
        @options[:chagelog_exists] = 'HISTORY.md'
      end
    end

    def generate_pr_message
      @options[:pr_message] = "Add change log file.

Hi, as I can see, you carefully fill tags and labels for issues in your repo.

For such cases I create a [github_changelog_generator](https://github.com/skywinder/github-changelog-generator), that generate change log file based on **tags**, **issues** and merged **pull requests** from :octocat: Issue Tracker.

This PR add change log file to your repo (generated by this script).
You can check, how it is look like here: [Change Log](https://github.com/skywinder/#{@options[:project]}/blob/add-change-log-file/#{@options[:output]})

Some essential features, that has this script:

-  it **exclude** not-related to changelog issues (any issue, that has label \`question\` \`duplicate\` \`invalid\` \`wontfix\` )
- Distinguish issues **according labels**:
    - Merged pull requests (all \`merged\` pull-requests)
    - Bug fixes (by label \`bug\` in issue)
    - Enhancements (by label \`enhancement\` in issue)
    -   Issues (closed issues \`w/o any labels\`)
- Generate neat Change Log file according basic [change log guidelines](http://keepachangelog.com).

You can quickly update this file in future by the simple run script: \`github_changelog_generator #{@options[:repo]}\` in your repo folder and it makes your Change Log file up-to-date again!

Hope you find this commit as useful. :wink:"

      unless @options[:chagelog_exists].nil?
        @options[:pr_message] += "

P.S.
I know that you already has #{@options[:chagelog_exists]} file but give this script a chance and compare it with yours change log. Hope, you will love it! :blush:"
      end
    end

    def add_commit_push
      execute_line('hub fork')
      execute_line('git checkout -b add-change-log-file')
      execute_line("git add #{@options[:output]}")
      execute_line("git commit -v -m '#{@options[:message]}'")
      execute_line('git push skywinder')
      # execute_line('git push')
      execute_line("hub pull-request -m '#{@options[:pr_message]}' -o")
    end

    def generate_change_log
      execute_line("github_changelog_generator #{@options[:repo]} -o #{@options[:output]}")
    end

    def clone_repo_and_cd
      if Dir.exist?(@options[:project])
        execute_line("rm -rf #{@options[:project]}")
      end
      execute_line("hub clone #{@options[:repo]}")
      @options[:dry_run] || Dir.chdir("./#{@options[:project]}")
      puts "Go to #{Dir.pwd}"
    end

    def execute_line(line)
      if @options[:dry_run]
        puts "Dry run: #{line}"
        return nil
      end
      puts line
      value = %x(#{line})
      puts value
      check_exit_status(value)
      value
    end

    def check_exit_status(output)
      if $?.exitstatus != 0
        puts "Output:\n#{output}\nExit status = #{$?.exitstatus} ->Terminate script."
        exit
      end
    end

    def go_to_work_dir
      Dir.chdir(@options[:path])

      merger_folder = 'changelog_merger_dir'
      unless Dir.exist?(merger_folder)
        puts "Creating directory #{merger_folder}"
        Dir.mkdir(merger_folder)
      end
      Dir.chdir("./#{merger_folder}")

      puts "Go to #{Dir.pwd}"
    end
  end
end

if __FILE__ == $0
  ChangelogMerger::Merger.new.run_generator
end
