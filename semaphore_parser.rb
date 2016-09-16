require 'nokogiri'
require 'pry'
require 'open-uri'

def open_file(filename)
  Nokogiri::HTML(open(filename))
end

def semaphore_thread_outputs(semaphore_log_file)
  semaphore_log_file.css(".c-results_list_pre.ng-isolate-scope").map do |thread|
    thread.text.scan(/\d+ tests, \d+ assertions, \d+ failures, \d+ errors, \d+ skips/)
  end.select.with_index { |_, i| i.odd? }
end

def thread_line(thread_number, thread_output)
  "#{thread_number}: #{thread_output.empty? ? "Passed" : thread_output.join("\n    ")}"
end

def print_build_information(semaphore_log_file)
  build_number = semaphore_log_file.css(".c-build-meta_list_status.btn-group").text.scan(/\d+/).first
  project_name = semaphore_log_file.css(".list-inline.neutralize.c-project-headline_list").css("b").text

  branch_name  = semaphore_log_file.css(".c-build_branch").css("b").text
  commit_sha   = semaphore_log_file.css(".u-hover-undelrine").text

  puts "build #{build_number} for #{project_name}"
  puts "branch: #{branch_name}"
  puts "commit sha: #{commit_sha}"
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

def download_complete_logs(semaphore_log_file)
  combined_output = File.open("Thread_output_combined", "w+")

  semaphore_log_file.css(".panel.panel-secondary-pastel").each do |thread|
    thread_num    = thread.css(".c-results_list_command.ng-binding").text.scan(/\d+/)[0].to_i
    download_link = thread.css(".text-info").css("a")[0].attributes["href"].value if thread.css(".text-info").css("a")[0].respond_to?(:attributes)
    
    combined_output.write("THREAD #{thread_num}:\n\n")
    if download_link == nil
      # If there is no download log link
      combined_output.write(thread.text)
    else
      # Download the full log from the link
      open(download_link) {|file|
        while buff = file.read(4096)
          combined_output.write(buff)
        end
      }
    end
    combined_output.write("\n")
  end
  combined_output.close
end

semaphore_log_file = open_file(ARGV[0])

print_build_information(semaphore_log_file)
puts ""

thread_outputs = semaphore_thread_outputs(semaphore_log_file)
print_totals(thread_outputs)

download_complete_logs(semaphore_log_file)
