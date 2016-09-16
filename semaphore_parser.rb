require 'nokogiri'
require 'pry'
require 'open-uri'

def open_file(filename)
  Nokogiri::HTML(open(filename))
end

def build_information(semaphore_log_file)
  build_number = semaphore_log_file.css(".c-build-meta_list_status.btn-group").text.scan(/\d+/).first
  project_name = semaphore_log_file.css(".list-inline.neutralize.c-project-headline_list").css("b").text

  branch_name  = semaphore_log_file.css(".c-build_branch").css("b").text
  commit_sha   = semaphore_log_file.css(".u-hover-undelrine").text

  ["build #{build_number} for #{project_name}",
   "branch: #{branch_name}",
   "commit sha: #{commit_sha}\n\n"].join("\n")
end

def print_totals(thread_outputs)
  totals = { tests: 0, assertions: 0, failures: 0, errors: 0, skips: 0 }

  thread_outputs.each_with_index do |thread_output, i|
    thread_output.map do |single_thread_output|
      single_thread_output_totals = single_thread_output.scan(/\d+/)

      totals.each_with_index do |(key, _), i|
        totals[key] += single_thread_output_totals[i].to_i
      end
    end

    puts thread_line(i + 1, thread_output)
  end

  puts ""

  totals.each do |key, value|
    puts "#{value} #{key}"
  end

  puts ""
  puts "failures + errors + skips: #{totals[:failures] + totals[:errors] + totals[:skips]}"
end

def generate_combined_output_and_output_stats(semaphore_log_file, combined_output_filename, output_stats_filename)
  combined_output = File.open("#{combined_output_filename}", "w+")
  output_stats    = File.open("#{output_stats_filename}", "w+")

  thread_stats_regex = /\d+ tests, \d+ assertions, \d+ failures, \d+ errors, \d+ skips/

  output_stats.write(build_information(semaphore_log_file))

  semaphore_log_file.css(".panel.panel-secondary-pastel").each do |thread|
    thread_num    = thread.css(".c-results_list_command.ng-binding").text.scan(/\d+/).first
    download_node = thread.css(".text-info").css("a").first
    download_link = download_node.attributes["href"].value if download_node.respond_to?(:attributes)

    output_stats.write("#{thread_num}: ")
    combined_output.write("THREAD #{thread_num}:\n\n")

    if download_link
      open(download_link) do |file|
        pre_string = ""
        file.each_line do |line|
          combined_output.write(line)

          if line =~ thread_stats_regex
            output_stats.write(pre_string + line)
            pre_string = "   " if pre_string.empty?
          end
        end
      end
    else
      combined_output.write(thread.text)
      output_stats.write(thread.text.scan(thread_stats_regex).join("\n   ") + "\n")
    end

    combined_output.write("\n")
  end

  combined_output.close
  output_stats.close
end

def find_common_output_lines(combined_output_filename, common_lines_filename)
  common_lines_command = "cat #{combined_output_filename} | grep -v \"^\s*$\" | sort | uniq -c | sort -nr > #{common_lines_filename}"
  system(common_lines_command)
end

if __FILE__ == $0
  combined_output_filename = "thread_output_combined.txt"
  common_lines_filename    = "thread_output_common_lines.txt"
  output_stats_filename    = "thread_output_stats.txt"

  semaphore_log_file = open_file(ARGV[0])

  puts "Downloading and compiling all output to: #{combined_output_filename} ..."
  generate_combined_output_and_output_stats(semaphore_log_file, combined_output_filename, output_stats_filename)

  puts "Outputting the common lines in the compiled output to: #{common_lines_filename} ..."
  find_common_output_lines(combined_output_filename, common_lines_filename)

  puts "Outputted all statistics to #{output_stats_filename}"
end
