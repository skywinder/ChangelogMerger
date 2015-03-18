require "changelog_merger/version"

require_relative "changelog_merger/parser"

module ChangelogMerger
  # Your code goes here...
  class Merger
    def initialize
      @options = Parser.parse_options

    end

    def run_generator
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
    end

    def check_existing_changelog_file
      if @options[:output] == 'CHANGELOG.md'
        if File.exist? @options[:output]

          puts "#{@options[:output]} found"
          @options[:chagelog_exists] = true
          extension = File.extname(@options[:output])
          base = File.basename(@options[:output], extension)
          @options[:output] = base + '_AUTO' + extension
          puts "Change it to: #{@options[:output]}"
        end
      end
    end

    def generate_pr_message
      @options[:pr_message] = "Add automatically generated change log file.

Hi, as I can see, you are carefully fill tags and labels for issues in your repo.

And special for such cases - I created a [github_changelog_generator](https://github.com/skywinder/github-changelog-generator), that generate change log file based on **tags**, **issues** and merged **pull requests** (and split them to separate lists according labels) from :octocat: GitHub Issue Tracker.

By using this script your Change Log will look like this: [Click me!](https://github.com/skywinder/#{@options[:project]}/blob/add-change-log-file/#{@options[:output]})

\> ***What’s the point of a change log?***
To make it easier for users and contributors to see precisely what notable changes have been made between each release (or version) of the project.
\> :copyright: *[http://keepachangelog.com](http://keepachangelog.com/)*

And now you do not need to spend a lot of :hourglass_flowing_sand: for filling it manually!

Some essential features of **github_changelog_generator**:

- Generate **neat** Change Log file according basic [change log guidelines](http://keepachangelog.com). :gem:

- **Distinguish** issues **according labels**:
    - Merged pull requests (all \`merged\` pull-requests)
    - Bug fixes (by label \`bug\` in issue)
    - Enhancements (by label \`enhancement\` in issue)
    -   Issues (closed issues \`w/o any labels\`)

-  it **exclude** not-related to changelog issues (any issue, that has label \`question\` \`duplicate\` \`invalid\` \`wontfix\` )  :scissors:

- You can set which labels should be included/excluded and apply a lot of other customisations, to fit changelog for your personal style :tophat: (*look \`github_changelog_generator --help\`  for details)*

You can easily update this file in future by simply run script: \`github_changelog_generator #{@options[:repo]}\` in your repo folder and it make your Change Log file up-to-date again!

Since now you do not have to fill your \`CHANGELOG.md\` manually: just run script, relax and take a cup of :coffee: before your next release!

Hope you find this commit as useful. :wink:"

      if @options[:chagelog_exists]
        @options[:pr_message] += '

P.S.
I know that you already has `CHANGELOG.md` file but give them a chance and compare quality of automatically generated change log. Hope, you will love it! :blush:'
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
      Dir.chdir("./#{@options[:project]}")
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
