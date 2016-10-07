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

def add_to_totals(totals, thread_output_line)
  line_totals = thread_output_line.scan(/\d+/)
  totals.each_with_index { |(key, _), i| totals[key] += line_totals[i].to_i }
  totals
end

def write_totals_to_stats(totals, stats)
  stats.write("\n")
  totals.each { |key, value| stats.write("#{value} #{key}\n") }
  stats.write("\nfailures + errors + skips: #{totals[:failures] + totals[:errors] + totals[:skips]}")
end

def thread_stats_regex
  /\d+ tests, \d+ assertions, \d+ failures, \d+ errors, \d+ skips/
end

def download_thread_and_add_to_outputs(download_link, totals, combined_output, stats)
  open(download_link) do |file|
    alignment = ""

    file.each_line do |line|
      combined_output.write(line)

      if line =~ thread_stats_regex
        totals = add_to_totals(totals, line)

        stats.write("#{alignment}#{line}")
        alignment = "   " if pre_string.empty?
      end
    end
  end

  totals
end

def add_thread_to_outputs(thread_text, totals, combined_output, stats)
  combined_output.write(thread_text)
  stats.write(thread_text.scan(thread_stats_regex).join("\n   ") + "\n")
  thread_text.scan(thread_stats_regex).map { |thread_output_line| totals = add_to_totals(totals, thread_output_line) }

  totals
end

def generate_combined_output_and_stats(semaphore_log_file, combined_output_filename, stats_filename)
  combined_output = File.open("#{combined_output_filename}", "w+")
  stats           = File.open("#{stats_filename}", "w+")
  totals          = { tests: 0, assertions: 0, failures: 0, errors: 0, skips: 0 }

  stats.write(build_information(semaphore_log_file))

  semaphore_log_file.css(".panel.panel-secondary-pastel").each do |thread|
    thread_num    = thread.css(".c-results_list_command.ng-binding").text.scan(/\d+/).first
    download_node = thread.css(".text-info").css("a").first
    download_link = download_node.attributes["href"].value if download_node.respond_to?(:attributes)

    stats.write("#{thread_num}: ")
    combined_output.write("THREAD #{thread_num}:\n\n")

    totals = if download_link
      download_thread_and_add_to_outputs(download_link, totals, combined_output, stats)
    else
      add_thread_to_outputs(thread.text, totals, combined_output, stats)
    end

    combined_output.write("\n")
  end

  write_totals_to_stats(totals, stats)
  combined_output.close
  stats.close
end

def generate_common_output_lines(combined_output_filename, common_lines_filename)
  common_lines_command = "cat #{combined_output_filename} | grep -v \"^\s*$\" | sort | uniq -c | sort -nr > #{common_lines_filename}"
  system(common_lines_command)
end

if __FILE__ == $0
  semaphore_log_file = open_file(ARGV[0])

  build  = "build_#{semaphore_log_file.css(".c-build-meta_list_status.btn-group").text.scan(/\d+/).first}"
  folder = ARGV[1] || ""

  combined_output_filename = "#{folder}#{build}_thread_output_combined.txt"
  common_lines_filename    = "#{folder}#{build}_thread_output_common_lines.txt"
  stats_filename           = "#{folder}#{build}_stats.txt"

  puts "Downloading and compiling all output to: #{combined_output_filename} ..."
  generate_combined_output_and_stats(semaphore_log_file, combined_output_filename, stats_filename)

  puts "Outputting the common lines in the compiled output to: #{common_lines_filename} ..."
  generate_common_output_lines(combined_output_filename, common_lines_filename)

  puts "Outputted all statistics to #{stats_filename}"
end
